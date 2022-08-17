import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { v3 } from "node-hue-api";
import { Api } from "node-hue-api/dist/esm/api/Api";

const CLIENT_ID = "wq9lMKlb0LypJeExHayCZgXLVQGPuInF";
const CLIENT_SECRET = "0nbdixBERjkgJClS";
const remoteBootstrap = v3.api.createRemote(CLIENT_ID, CLIENT_SECRET);

if (admin.apps.length === 0) {
    admin.initializeApp();
}
const db = admin.firestore();
db.settings({ ignoreUndefinedProperties: true })

// Create credetials
export const callback = functions.https.onRequest((req, res) => {
    const user = req.query.state;
    const authorizationCode = req.query.code?.toString();
    if (user == null || authorizationCode == null || !db.doc(`users/${user}`).get().then((snapshot: any) => snapshot.exists)) {
        res.send("Error!")
    }
    remoteBootstrap.connectWithCode(authorizationCode!)
        .then((api: Api) => {
            const remoteCredentials = api.remote!.getRemoteAccessCredentials();
            api.lights.getAll().then((allLights: any) => {
                const lights = allLights.map((light: any) => { return { "name": light.name, "id": light.id, "color": light.type.match(/color/i) != null }; });
                db.doc(`users/${user}`).set({
                    "api": {
                        "name": "Philips Hue", "credentials": remoteCredentials, "lights": lights
                    },
                }, { merge: true })
                    .then(() => res.redirect("https://app-lalo.tk/l/open"))
                    .catch((e: any) => {
                        console.error(e);
                        res.send("Can not connect to database!");
                    });
            }).catch((e: any) => {
                console.error(e);
                res.send("Can not get lights!");
            });
        }).catch((e: any) => {
            console.error(e);
            res.send("Can not connect to Philips Hue!");
        });
});

// Blink light
export const blink = functions.https.onCall((data) => {
    let x = 0;
    return db.doc(`users/${data.userId}`).get().then((snapshot: any) => {
        if (snapshot.exists) {
            for (const permission of snapshot.data().permissions) {
                if (permission.uid === data.me) {
                    if (snapshot.data().api.name === "No services connected") return "Friend has no light";
                    if (snapshot.data().dnd === true || Date.now() - snapshot.data().light.last < 30 * 1000) return;
                    db.doc(`users/${data.userId}`).update({ "light.last": Date.now() });
                    if (snapshot.data().api.name === "Philips Hue") {
                        const cred = snapshot.data().api.credentials;
                        if (!cred) return "Could not connect to light";
                        return remoteBootstrap.connectWithTokens(
                            cred.tokens.access.value, cred.tokens.refresh.value, cred.username)
                            .then((api: Api) => {
                                if (snapshot.data().light.name === "Not selected" || null) {
                                    return "Friend has no light";
                                }
                                return api.lights.getLightState(snapshot.data().light.id).then((value: any) => {
                                    const state = new v3.lightStates.LightState();
                                    const color = hexToRgb(permission.color);
                                    state.on().brightness(100).rgb(color);
                                    api.lights.setLightState(snapshot.data().light.id, state).then(() => {
                                        setTimeout(blinkLight, 1000, api, snapshot.data().light.id, true, color, value);
                                    });
                                }).catch((e) => {
                                    console.error(e);
                                    return "Could not blink light";
                                });
                            }).catch((e) => {
                                console.error(e);
                                return "Could not connect to light";
                            });
                    } else return "Could not connect to light";
                }
            }
            return removeFriend(data);
        } else {
            return removeFriend(data);
        }
    }).catch((e: any) => {
        console.error(e);
        return "Unknown Error";
    });

    /**
     * Remove a friend
     * @param {object} data
     * @return {Promise<string>}
     */
    function removeFriend(data: { me: string; userId: string, userName: string }): Promise<string> {
        return db.doc(`users/${data.me}`).update({
            "friends": admin.firestore.FieldValue.arrayRemove({ "uid": data.userId, "name": data.userName })
        }).then(() => {
            return "Not your friend anymore";
        }).catch((e) => {
            console.error(e);
            return "Could not remove friend";
        });
    }
    /**
     * Blink the light
     * @param {Api} api
     * @param {string} id
     * @param {boolean} value
     * @param {number[]} color
     * @param {any} original
     * @return {Promise<void>}
     */
    async function blinkLight(api: Api, id: string, value: boolean, color: number[], original: any): Promise<void> {
        const state = new v3.lightStates.LightState();
        if (value) state.off();
        else state.on().brightness(100).rgb(color);
        try {
            await api.lights.setLightState(id, state);
        } catch (e) {
            console.error(e);
        }
        if (++x < 3) {
            setTimeout(blinkLight, 1000, api, id, !value, color, original);
        } else try {
            await api.lights.setLightState(id, original);
        } catch (e) {
            console.error(e);
        }
    }
    /**
     * Converts HEX value to RGB
     * @param {string} hex
     * @return {[int, int, int]} rgb
     */
    function hexToRgb(hex: string) {
        const result = hex.match(/[0-F]{1,2}/gi);
        return [
          parseInt(result![0], 16),
          parseInt(result![1], 16),
          parseInt(result![2], 16)
        ]
      }
});

// Accept friend request
export const accept = functions.https.onCall((data) => {
    return db.doc(`users/${data.senderId}`).update({
        "friends": admin.firestore.FieldValue.arrayUnion({
            "name": data.friendName,
            "uid": data.friendId
        })
    }).then(() => "Request accepted").catch((e: any) => {
        console.error(e);
        return "Request could not be accepted";
    });
});

export const refresh = functions.pubsub.schedule("1, 7, 13, 19, 25, 31 of month 00:00").timeZone("Europe/Berlin").onRun((context) => {
    return db.collection("users")
        .where("api.credentials.tokens.access.expiresAt", "<", Date.now() + 6 * 24 * 60 * 60 * 1000)
        .get().then((result) => {
            result.forEach((user) => {
                db.doc(`users/${user.id}`).get().then((snapshot: any) => {
                    if (snapshot.exists) {
                        const cred = snapshot.data().api.credentials;
                        remoteBootstrap.connectWithTokens(cred.tokens.access.value,
                            cred.tokens.refresh.value,
                            cred.username
                        ).then((api: Api) => {
                            api.remote?.refreshTokens().then((refreshedTokens) => {
                                db.doc(`users/${user.id}`).update({ "api.credentials.tokens.access": refreshedTokens.accessToken, "api.credentials.tokens.refresh": refreshedTokens.refreshToken })
                                    .catch((e) => {
                                        console.error(e);
                                    });
                            }).catch((e) => {
                                console.error(e);
                            });
                        }).catch((e) => {
                            console.error(e);
                        });
                    }
                }).catch((e) => {
                    console.error(e);
                });
            });
    }).catch((e) => {
        console.error(e);
    });
});
