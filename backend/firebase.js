import admin from "firebase-admin";
import fs from "fs";

// Charger la clé privée Firebase (qui n'est PAS envoyée au GitHub)
const serviceAccount = JSON.parse(
  fs.readFileSync("./firebase_key.json", "utf8")
);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

export const firestore = admin.firestore();
