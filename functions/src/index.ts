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
 * Converts a HEX color to RGB.
 * @param {string} hex color like "ff8800"
 * @return {number[]} [r, g, b]
 */
function hexToRgb(hex: string): number[] {
  const result = hex.match(/[0-9a-fA-F]{1,2}/g);
  return [
    parseInt(result![0], 16),
    parseInt(result![1], 16),
    parseInt(result![2], 16),
  ];
}

// OAuth callback of the Hue Remote API: exchanges the authorization code for
// tokens, stores them together with the user's lights and sends the user
// back to the web app.
export const callback = functions.https.onRequest(
    {secrets: [hueClientSecret]},
    async (req, res) => {
      const user = req.query.state?.toString();
      const authorizationCode = req.query.code?.toString();
      if (!user || !authorizationCode) {
        res.status(400).send("Missing parameters!");
        return;
      }
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
        await db.doc(`users/${user}`).set({
          "api": {
            "name": "Philips Hue",
            "credentials": remoteCredentials,
            "lights": lights,
          },
        }, {merge: true});
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

        if (friend.api.name === "No services connected") {
          return "Friend has no light";
        }
        if (friend.dnd === true ||
            Date.now() - friend.light.last < 30 * 1000) {
          return null;
        }
        if (friend.api.name !== "Philips Hue" || !friend.api.credentials) {
          return "Could not connect to light";
        }
        if (friend.light.name === "Not selected") {
          return "Friend has no light";
        }
        await db.doc(`users/${data.userId}`)
            .update({"light.last": Date.now()});

        const cred = friend.api.credentials;
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

        const lightId = friend.light.id;
        const color = hexToRgb(permission.color);
        const original = await api.lights.getLightState(lightId);

        /**
         * Toggles the light, three blinks in total, then restores the
         * original state.
         * @param {boolean} on whether this step switches the light on
         * @param {number} count how many toggles happened already
         * @return {Promise<void>}
         */
        const blinkLight = async (
            on: boolean, count: number): Promise<void> => {
          const state = new v3.lightStates.LightState();
          if (on) {
            state.on().brightness(100).rgb(color);
          } else {
            state.off();
          }
          try {
            await api.lights.setLightState(lightId, state);
          } catch (e) {
            console.error(e);
          }
          await new Promise((resolve) => setTimeout(resolve, 1000));
          if (count < 3) {
            await blinkLight(!on, count + 1);
          } else {
            try {
              await api.lights.setLightState(lightId, original);
            } catch (e) {
              console.error(e);
            }
          }
        };

        await blinkLight(true, 0);
        return null;
      } catch (e) {
        console.error(e);
        return "Unknown Error";
      }
    });

// Accepts a friend request: adds the accepting user to the sender's friends.
export const accept = functions.https.onCall(async (request) => {
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
    });
