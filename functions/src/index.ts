import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {defineSecret} from "firebase-functions/params";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {v3} from "node-hue-api";
import {Api} from "node-hue-api/dist/esm/api/Api";

// Public OAuth client id of the Hue Remote API app; the secret is managed
// with `firebase functions:secrets:set HUE_CLIENT_SECRET` (see SETUP.md).
const HUE_CLIENT_ID = "wq9lMKlb0LypJeExHayCZgXLVQGPuInF";
const hueClientSecret = defineSecret("HUE_CLIENT_SECRET");

const APP_URL = "https://app.lalo.lighting";

if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();
db.settings({ignoreUndefinedProperties: true});

/**
 * Creates a Hue Remote API bootstrap. Must be called inside a function
 * handler because the secret is only available at runtime.
 * @return {object} remote bootstrap
 */
function hueRemote() {
  return v3.api.createRemote(HUE_CLIENT_ID, hueClientSecret.value());
}

/**
 * Converts a HEX color to RGB. Falls back to white for malformed input so a
 * bad stored color can never crash the blink handler.
 * @param {string} hex color like "ff8800"
 * @return {number[]} [r, g, b]
 */
function hexToRgb(hex: string): number[] {
  const result = hex.match(/[0-9a-fA-F]{2}/g);
  if (!result || result.length < 3) return [255, 255, 255];
  return [
    parseInt(result[0], 16),
    parseInt(result[1], 16),
    parseInt(result[2], 16),
  ];
}

/**
 * Waits for the given number of milliseconds.
 * @param {number} ms milliseconds to wait
 * @return {Promise<void>}
 */
function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Request headers for the Home Assistant REST API.
 * @param {string} token long-lived access token
 * @return {Record<string, string>} headers
 */
function haHeaders(token: string): Record<string, string> {
  return {
    "Authorization": `Bearer ${token}`,
    "Content-Type": "application/json",
  };
}

/**
 * Whether a URL host is a loopback, private, or link-local target that must
 * not be reached through a user-supplied URL (SSRF guard). Covers IP literals
 * and common internal hostnames.
 * @param {string} host hostname or IP literal from a parsed URL
 * @return {boolean} true if the host must be blocked
 */
function isBlockedHost(host: string): boolean {
  let h = host.toLowerCase();
  if (h.startsWith("[") && h.endsWith("]")) h = h.slice(1, -1);
  if (h === "localhost" || h.endsWith(".localhost") ||
      h.endsWith(".local") || h.endsWith(".internal") || h === "metadata") {
    return true;
  }
  // IPv6 loopback, unique-local (fc00::/7) and link-local (fe80::/10).
  if (h === "::" || h === "::1" || /^f[cd][0-9a-f]{2}:/.test(h) ||
      /^fe[89ab][0-9a-f]:/.test(h)) {
    return true;
  }
  const v4 = h.match(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/);
  if (!v4) return false;
  const p = v4.slice(1).map((n) => parseInt(n, 10));
  if (p.some((n) => n > 255)) return true;
  return (
    p[0] === 0 ||
    p[0] === 10 ||
    p[0] === 127 ||
    (p[0] === 169 && p[1] === 254) ||
    (p[0] === 172 && p[1] >= 16 && p[1] <= 31) ||
    (p[0] === 192 && p[1] === 168) ||
    (p[0] === 100 && p[1] >= 64 && p[1] <= 127)
  );
}

/**
 * Validates that a user-supplied URL targets a public host (SSRF guard).
 * @param {string} url an http(s) URL
 * @return {boolean} true if the URL is safe to fetch
 */
function isPublicUrl(url: string): boolean {
  try {
    return !isBlockedHost(new URL(url).hostname);
  } catch {
    return false;
  }
}

/**
 * Blinks a Philips Hue light twice in the given color, then restores the
 * previous state.
 * @param {admin.firestore.DocumentData} friend the light owner's user doc
 * @param {number[]} color RGB color to blink in
 * @return {Promise<string|null>} error message for the client or null
 */
async function blinkHue(
    friend: admin.firestore.DocumentData,
    color: number[]): Promise<string | null> {
  const cred = friend.api.credentials;
  if (!cred) return "Could not connect to light";
  let api: Api;
  try {
    api = await hueRemote().connectWithTokens(
        cred.tokens.access.value,
        cred.tokens.refresh.value,
        cred.username);
  } catch (e) {
    console.error(e);
    return "Could not connect to light";
  }
  try {
    const lightId = friend.light.id;
    const original = await api.lights.getLightState(lightId);
    const setOn = new v3.lightStates.LightState();
    setOn.on().brightness(100).rgb(color);
    const setOff = new v3.lightStates.LightState();
    setOff.off();
    for (let i = 0; i < 2; i++) {
      await api.lights.setLightState(lightId, setOn);
      await sleep(1000);
      await api.lights.setLightState(lightId, setOff);
      await sleep(1000);
    }
    await api.lights.setLightState(lightId, original);
    return null;
  } catch (e) {
    console.error(e);
    return "Could not blink light";
  }
}

/**
 * Blinks a Home Assistant light twice in the given color, then restores the
 * previous state.
 * @param {admin.firestore.DocumentData} friend the light owner's user doc
 * @param {number[]} color RGB color to blink in
 * @return {Promise<string|null>} error message for the client or null
 */
async function blinkHomeAssistant(
    friend: admin.firestore.DocumentData,
    color: number[]): Promise<string | null> {
  const url = (friend.api.url as string).replace(/\/+$/, "");
  if (!isPublicUrl(url)) return "Could not connect to light";
  const headers = haHeaders(friend.api.token as string);
  const entityId = friend.light.id as string;
  const call = (service: string, body: Record<string, unknown>) =>
    fetch(`${url}/api/services/light/${service}`, {
      method: "POST",
      headers,
      body: JSON.stringify(body),
    });
  try {
    const origResp = await fetch(`${url}/api/states/${entityId}`, {headers});
    if (!origResp.ok) return "Could not connect to light";
    const original = await origResp.json() as {
      state: string;
      attributes?: { brightness?: number; rgb_color?: number[] };
    };
    const turnOn: Record<string, unknown> = {"entity_id": entityId};
    if (friend.light.color === true) {
      turnOn.rgb_color = color;
      turnOn.brightness = 255;
    }
    for (let i = 0; i < 2; i++) {
      await call("turn_on", turnOn);
      await sleep(1000);
      await call("turn_off", {"entity_id": entityId});
      await sleep(1000);
    }
    if (original.state === "on") {
      const restore: Record<string, unknown> = {"entity_id": entityId};
      if (original.attributes?.brightness != null) {
        restore.brightness = original.attributes.brightness;
      }
      if (original.attributes?.rgb_color != null) {
        restore.rgb_color = original.attributes.rgb_color;
      }
      await call("turn_on", restore);
    }
    return null;
  } catch (e) {
    console.error(e);
    return "Could not blink light";
  }
}

// OAuth callback of the Hue Remote API: exchanges the authorization code for
// tokens, stores them together with the user's lights and sends the user
// back to the web app.
export const callback = functions.https.onRequest(
    {secrets: [hueClientSecret]},
    async (req, res) => {
      const state = req.query.state?.toString();
      const authorizationCode = req.query.code?.toString();
      if (!state || !authorizationCode) {
        res.status(400).send("Missing parameters!");
        return;
      }
      // `state` is an unguessable single-use nonce created by the client in
      // `hueStates/{nonce}`; it maps back to the user that started the flow.
      const stateSnap = await db.doc(`hueStates/${state}`).get();
      if (!stateSnap.exists) {
        res.status(400).send("Invalid or expired state!");
        return;
      }
      const stateData = stateSnap.data()!;
      await stateSnap.ref.delete();
      if (Date.now() - (stateData.time ?? 0) > 60 * 60 * 1000) {
        res.status(400).send("Invalid or expired state!");
        return;
      }
      const user = stateData.uid as string;
      const snapshot = await db.doc(`users/${user}`).get();
      if (!snapshot.exists) {
        res.status(404).send("Unknown user!");
        return;
      }
      try {
        const api: Api = await hueRemote().connectWithCode(authorizationCode);
        const remoteCredentials = api.remote!.getRemoteAccessCredentials();
        const allLights = await api.lights.getAll();
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const lights = allLights.map((light: any) => ({
          "name": light.name,
          "id": light.id,
          "color": light.type.match(/color/i) != null,
        }));
        await db.doc(`users/${user}`).update({
          "api": {
            "name": "Philips Hue",
            "credentials": remoteCredentials,
            "lights": lights,
          },
          "light": {
            "name": "Not selected", "id": "", "color": false, "last": 0,
          },
        });
        res.redirect(APP_URL);
      } catch (e) {
        console.error(e);
        res.status(500).send("Can not connect to Philips Hue!");
      }
    });

// Blinks the light of the user `userId` on behalf of the caller `me`,
// provided the caller is in the user's permission list.
export const blink = functions.https.onCall(
    {secrets: [hueClientSecret]},
    async (request) => {
      const data = request.data as {
        me: string;
        userId: string;
        userName: string;
      };

      /**
       * Removes the (no longer valid) friend from the caller's list.
       * @return {Promise<string>} status message for the client
       */
      async function removeFriend(): Promise<string> {
        try {
          await db.doc(`users/${data.me}`).update({
            "friends": admin.firestore.FieldValue.arrayRemove(
                {"uid": data.userId, "name": data.userName}),
          });
          return "Not your friend anymore";
        } catch (e) {
          console.error(e);
          return "Could not remove friend";
        }
      }

      try {
        const snapshot = await db.doc(`users/${data.userId}`).get();
        if (!snapshot.exists) return removeFriend();
        const friend = snapshot.data()!;
        const permission = friend.permissions
            .find((p: { uid: string }) => p.uid === data.me);
        if (!permission) return removeFriend();

        if (friend.api.name === "No services connected" ||
            friend.light.name === "Not selected") {
          return "Friend has no light";
        }
        if (friend.dnd === true ||
            Date.now() - friend.light.last < 30 * 1000) {
          return null;
        }
        await db.doc(`users/${data.userId}`)
            .update({"light.last": Date.now()});

        const color = hexToRgb(permission.color);
        if (friend.api.name === "Philips Hue") {
          return blinkHue(friend, color);
        }
        if (friend.api.name === "Home Assistant") {
          return blinkHomeAssistant(friend, color);
        }
        return "Could not connect to light";
      } catch (e) {
        console.error(e);
        return "Unknown Error";
      }
    });

// Validates a Home Assistant URL + long-lived access token and stores the
// available lights for the calling user.
export const connectHomeAssistant = functions.https.onCall(
    async (request) => {
      if (!request.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated", "You must be signed in");
      }
      const url = ((request.data.url as string) ?? "").trim()
          .replace(/\/+$/, "");
      const token = ((request.data.token as string) ?? "").trim();
      if (!/^https?:\/\//.test(url) || !token) {
        return "Invalid URL or token";
      }
      if (!isPublicUrl(url)) {
        return "Home Assistant must be reachable at a public address";
      }
      try {
        const resp = await fetch(`${url}/api/states`, {
          headers: haHeaders(token),
        });
        if (!resp.ok) return "Could not connect to Home Assistant";
        const states = await resp.json() as Array<{
          entity_id: string;
          attributes?: {
            friendly_name?: string;
            supported_color_modes?: string[];
          };
        }>;
        const colorModes = ["hs", "xy", "rgb", "rgbw", "rgbww"];
        const lights = states
            .filter((s) => s.entity_id.startsWith("light."))
            .map((s) => ({
              "name": s.attributes?.friendly_name ?? s.entity_id,
              "id": s.entity_id,
              "color": (s.attributes?.supported_color_modes ?? [])
                  .some((m) => colorModes.includes(m)),
            }));
        if (lights.length === 0) {
          return "No lights found in Home Assistant";
        }
        await db.doc(`users/${request.auth.uid}`).update({
          "api": {
            "name": "Home Assistant",
            "url": url,
            "token": token,
            "lights": lights,
          },
          "light": {
            "name": "Not selected", "id": "", "color": false, "last": 0,
          },
        });
        return "Connected to Home Assistant";
      } catch (e) {
        console.error(e);
        return "Could not connect to Home Assistant";
      }
    });

// Accepts a friend request: adds the accepting user to the sender's friends.
export const accept = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated", "You must be signed in");
  }
  if (request.data.friendId !== request.auth.uid) {
    throw new functions.https.HttpsError(
        "permission-denied", "You can only accept requests as yourself");
  }
  try {
    await db.doc(`users/${request.data.senderId}`).update({
      "friends": admin.firestore.FieldValue.arrayUnion({
        "name": request.data.friendName,
        "uid": request.data.friendId,
      }),
    });
    return "Request accepted";
  } catch (e) {
    console.error(e);
    return "Request could not be accepted";
  }
});

/**
 * Returns a stored `friends`/`permissions` array with every entry that
 * references `uid` removed. Both arrays hold objects keyed by `uid`, so the
 * exact object (name/color) can differ between docs — filter by uid instead.
 * @param {unknown} arr a stored friends or permissions array (may be missing)
 * @param {string} uid the uid whose entries should be dropped
 * @return {Array<{uid: string}>} the filtered array
 */
function withoutUid(arr: unknown, uid: string): Array<{uid: string}> {
  return ((arr ?? []) as Array<{uid: string}>).filter((e) => e.uid !== uid);
}

// Permanently deletes the calling user. Runs with admin privileges so it can
// remove the user from every connected person's `friends`/`permissions` lists
// (which Firestore rules forbid the client to touch), delete their pending
// invite links and user document, then delete the auth account itself.
export const deleteAccount = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated", "You must be signed in");
  }
  const uid = request.auth.uid;
  const userRef = db.doc(`users/${uid}`);
  try {
    const snap = await userRef.get();
    if (snap.exists) {
      const data = snap.data()!;
      // People whose light I can blink (my `friends`) list me in their
      // `permissions`; people who can blink my light (my `permissions`) list
      // me in their `friends`. Either way, drop every entry pointing at me.
      const others = new Set<string>();
      for (const list of [data.friends, data.permissions]) {
        for (const e of (list ?? []) as Array<{uid: string}>) {
          others.add(e.uid);
        }
      }
      await Promise.all([...others].map((other) =>
        db.runTransaction(async (tx) => {
          const ref = db.doc(`users/${other}`);
          const os = await tx.get(ref);
          if (!os.exists) return;
          const d = os.data()!;
          tx.update(ref, {
            "friends": withoutUid(d.friends, uid),
            "permissions": withoutUid(d.permissions, uid),
          });
        }).catch((e) => console.error(`Cleanup for ${other} failed`, e)),
      ));
    }
    // Invite links this user still had pending.
    const links = await db.collection("links")
        .where("senderId", "==", uid).get();
    await Promise.all(links.docs.map((d) => d.ref.delete()));
    // Feedback is keyed by uid (best effort).
    await db.doc(`feedback/${uid}`).delete().catch(() => undefined);
    await userRef.delete();
    await admin.auth().deleteUser(uid);
    return "Account deleted";
  } catch (e) {
    console.error(e);
    throw new functions.https.HttpsError(
        "internal", "Could not delete your account");
  }
});

// Refreshes Hue tokens that expire within the next six days and deletes
// friend-request links older than a week.
export const refresh = onSchedule(
    {
      schedule: "1, 7, 13, 19, 25, 31 of month 00:00",
      secrets: [hueClientSecret],
    },
    async () => {
      try {
        const expiring = await db.collection("users")
            .where("api.credentials.tokens.access.expiresAt", "<",
                Date.now() + 6 * 24 * 60 * 60 * 1000)
            .get();
        for (const user of expiring.docs) {
          try {
            const cred = user.data().api.credentials;
            const api: Api = await hueRemote().connectWithTokens(
                cred.tokens.access.value,
                cred.tokens.refresh.value,
                cred.username);
            const refreshedTokens = await api.remote!.refreshTokens();
            await db.doc(`users/${user.id}`).update({
              "api.credentials.tokens.access": refreshedTokens.accessToken,
              "api.credentials.tokens.refresh": refreshedTokens.refreshToken,
            });
          } catch (e) {
            console.error(`Could not refresh tokens for ${user.id}`, e);
          }
        }
      } catch (e) {
        console.error(e);
      }
      try {
        const expired = await db.collection("links")
            .where("time", "<", Date.now() - 7 * 24 * 60 * 60 * 1000)
            .get();
        await Promise.all(expired.docs.map((link) => link.ref.delete()));
      } catch (e) {
        console.error(e);
      }
      try {
        const staleStates = await db.collection("hueStates")
            .where("time", "<", Date.now() - 24 * 60 * 60 * 1000)
            .get();
        await Promise.all(staleStates.docs.map((s) => s.ref.delete()));
      } catch (e) {
        console.error(e);
      }
    });
