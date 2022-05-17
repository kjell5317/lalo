import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { v3 } from "node-hue-api";

export const callback = functions.https.onRequest((req, res) => {
    admin.initializeApp();
    const db = admin.firestore();
    const CLIENT_ID = "wq9lMKlb0LypJeExHayCZgXLVQGPuInF";
    const CLIENT_SECRET = "0nbdixBERjkgJClS";
    const user = req.query.state;
    const authorizationCode: string = req.query.code!.toString();
    if (user == null || authorizationCode == null || !db.doc(`user/${user}`).get().then((docSnapshot: any) => docSnapshot.exists)) {
        res.send("Fehler");
    }

    const remoteBootstrap = v3.api.createRemote(CLIENT_ID, CLIENT_SECRET);

    if (authorizationCode){
        remoteBootstrap.connectWithCode(authorizationCode)
        .catch((err: any) => {
            console.error("Failed to get a remote connection using authorization code.");
            console.error(err);
            process.exit(1);
        })
        .then((api: any) => {
            const remoteCredentials = api.remote.getRemoteAccessCredentials();
            const lights = api.lights.getAll().then((lights: any) => JSON.stringify(
                lights.map((light: any) => {
                    return { name: light.name, id: light.uniqueid }
                })
            ));
            db.doc(`user/${user}`).set({
                "api": {
                    "name": "Philips Hue",// "tokens": JSON.stringify(remoteCredentials.tokens), "lights": lights
                },
            }, { merge: true }).then(() => {
                res.redirect("https://lalo-2605.web.app");
            }).catch((e) => console.log(e, lights, remoteCredentials));
        });
    }
});
