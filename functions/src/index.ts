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
                        .catch((e) => {
                            console.error(e);
                            res.send("Error!");
                        });
                }).catch((e) => {
                    console.error(e);
                    res.send("Error!");
                });
            }).catch((e) => {
                console.error(e);
                res.send("Error!");
            });
    } else res.send("Error!");
});

// Blink light
export const blink = functions.https.onCall(async (data, context) => {
    const user = data.uid;
    const prom = db.doc(`users/${user}`).get().then((snapshot: any) => {
        if (snapshot.exists) {
            console.log(snapshot.data().permissions, data.me)
            if (snapshot?.data().permissions.includes(data.me)) {
                if (snapshot?.data().api.name === "Philips Hue") {
                    const cred = snapshot?.data()?.api?.credentials;
                    if (!cred) return "Could not connect to light";
                    return remoteBootstrap.connectWithTokens(
                        cred.tokens.access.value, cred.tokens.refresh.value, cred.username)
                        .then((api: Api) => {
                            if (snapshot.data().light.name === "Not selected" || null) {
                                return "User has no lights";
                            }
                            return api.lights.setLightState(snapshot.data().light.id, { on: true }).then((result) => {
                                return "Success!";
                            }).catch((e) => {
                                console.error(e);
                                return "Could not blink light";
                            });
                        }).catch((e) => {
                            console.error(e);
                            return "Could not connect to light";
                        });
                } else return "Wrong API";
            } else return "You have no permissions";
        } else return "Could not connect to light";
    }).catch((e) => {
        console.error(e);
        return "Could not find user";
    });
    return await prom;
});
