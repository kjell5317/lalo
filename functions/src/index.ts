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
    const authorizationCode: string = req.query.code!.toString();
    if (user == null || authorizationCode == null || !db.doc(`users/${user}`).get().then((snapshot: any) => snapshot.exists)) {
        res.send("Error!")
    }
    if (authorizationCode) {
        remoteBootstrap.connectWithCode(authorizationCode)
            .then((api: Api) => {
                const remoteCredentials = api.remote!.getRemoteAccessCredentials();
                api.lights.getAll().then((allLights: any) => {
                    const lights = allLights.map((light: any) => { return { "name": light.name, "id": light.id } });
                    db.doc(`users/${user}`).set({
                        "api": {
                            "name": "Philips Hue", "credentials": remoteCredentials, "lights": lights
                        },
                    }, { merge: true })
                        .then(() => res.send(`
                            <script>window.close();</script>
                            <h1 style="text-align: center; vertical-align: middle;">
                                You can close this tab now.
                            </h1>
                        `))
                        .catch((e: any) => {
                            console.error(e);
                            res.send("Error!");
                        });
                }).catch((e: any) => {
                    console.error(e);
                    res.send("Error!");
                });
            }).catch((e: any) => {
                console.error(e);
                res.send("Error!");
            });
    } else res.send("Error!");
});
// TODO: renew credentials
// Blink light
export const blink = functions.https.onCall((data) => {
    let x = 0;
    return db.doc(`users/${data.userId}`).get().then((snapshot: any) => {
        if (snapshot.exists) {
            if (snapshot.data().permissions.includes(data.me)) {
                if (snapshot?.data().api.name === "No services connected") return "Friend has no light";
                if (snapshot.data().dnd === true) return;
                if (snapshot?.data().api.name === "Philips Hue") {
                    const cred = snapshot?.data()?.api?.credentials;
                    if (!cred) return "Could not connect to light";
                    return remoteBootstrap.connectWithTokens(
                        cred.tokens.access.value, cred.tokens.refresh.value, cred.username)
                        .then((api: Api) => {
                            if (snapshot.data().light.name === "Not selected" || null) {
                                return "Friend has no light";
                            }
                            return api.lights.getLightState(snapshot.data().light.id).then((value: any) => {
                                blinkLight(api, snapshot.data().light.id, value.on);
                            }).catch((e) => {
                                console.error(e);
                                return "Could not blink light";
                            });
                        }).catch((e) => {
                            console.error(e);
                            return "Could not connect to light";
                        });
                } else return "Wrong API";

            } else {
                return removeFriend(data)
            }
        } else {
            return removeFriend(data);
        }
    }).catch((e: any) => {
        console.error(e);
        return removeFriend(data);
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
     * @return {Promise<void>}
     */
    async function blinkLight(api: Api, id: string, value: boolean): Promise<void> {
        try {
            await api.lights.setLightState(id, { on: !value });
        } catch (e) {
            console.error(e);
        }
        if (++x <= 4) {
            setTimeout(blinkLight, 2000, api, id, !value);
        }
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
