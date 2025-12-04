import express from "express";
import cors from "cors";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import dotenv from "dotenv";
import multer from "multer";
import path from "path";
import fs from "fs";
import { db } from "./db.js";
import admin from "firebase-admin";

dotenv.config();

/* --------------------------------------------------
                FIREBASE INITIALISATION
--------------------------------------------------- */

const serviceAccount = JSON.parse(
    fs.readFileSync("./firebase_key.json", "utf8")
);

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const firestore = admin.firestore();

/* --------------------------------------------------
                EXPRESS INIT
--------------------------------------------------- */

const app = express();
app.use(cors());
app.use(express.json());

/* --------------------------------------------------
                UPLOAD CONFIG
--------------------------------------------------- */

const uploadFolder = "uploads/";

if (!fs.existsSync(uploadFolder)) {
    fs.mkdirSync(uploadFolder);
}

const storage = multer.diskStorage({
    destination: (_, __, cb) => cb(null, uploadFolder),
    filename: (_, file, cb) => {
        const unique = Date.now() + "-" + Math.round(Math.random() * 1e9);
        cb(null, unique + path.extname(file.originalname));
    },
});

const upload = multer({ storage });
app.use("/uploads", express.static("uploads"));

/* --------------------------------------------------
                    REGISTER
--------------------------------------------------- */

app.post("/register", async (req, res) => {
    try {
        const { username, password, country, region, birthdate } = req.body;

        const hash = await bcrypt.hash(password, 10);

        const [result] = await db.execute(
            `INSERT INTO users (username, password_hash, country, region, birthdate)
             VALUES (?, ?, ?, ?, ?)`,
            [username, hash, country, region, birthdate]
        );

        const userId = result.insertId.toString();

        // Firestore mirror for chat system
        await firestore.collection("users").doc(userId).set({
            uid: userId,
            username,
            country,
            region,
            birthdate,
            profile: null,
            isOnline: false,
            lastSeen: new Date()
        });

        res.json({ status: "ok", userId });

    } catch (err) {
        console.error("REGISTER ERROR:", err);
        res.status(500).json({ error: err.message });
    }
});

/* --------------------------------------------------
                     LOGIN
--------------------------------------------------- */

app.post("/login", async (req, res) => {
    try {
        const { username, password } = req.body;

        const [rows] = await db.execute(
            "SELECT * FROM users WHERE username = ?",
            [username]
        );

        if (rows.length === 0)
            return res.status(400).json({ error: "Utilisateur inconnu" });

        const user = rows[0];

        const match = await bcrypt.compare(password, user.password_hash);
        if (!match)
            return res.status(400).json({ error: "Mot de passe incorrect" });

        const token = jwt.sign(
            { id: user.id },
            process.env.JWT_SECRET,
            { expiresIn: "7d" }
        );

        // Firestore: user becomes online
        await firestore.collection("users").doc(user.id.toString()).update({
            isOnline: true,
            lastSeen: new Date()
        });

        res.json({
            token,
            userId: user.id,
            username: user.username,
            country: user.country,
            region: user.region,
            profile: user.profile
        });

    } catch (err) {
        console.error("LOGIN ERROR:", err);
        res.status(500).json({ error: err.message });
    }
});

/* --------------------------------------------------
                     LOGOUT
--------------------------------------------------- */

app.post("/logout", async (req, res) => {
    try {
        const { id } = req.body;

        await firestore.collection("users").doc(id.toString()).update({
            isOnline: false,
            lastSeen: new Date()
        });

        res.json({ success: true });

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/* --------------------------------------------------
                      PROFILE
--------------------------------------------------- */

app.get("/profile/:id", async (req, res) => {
    try {
        const { id } = req.params;

        const [rows] = await db.execute(
            "SELECT id, username, country, region, birthdate, profile FROM users WHERE id = ?",
            [id]
        );

        if (rows.length === 0)
            return res.status(404).json({ error: "Utilisateur non trouvé" });

        res.json(rows[0]);

    } catch (err) {
        console.error("PROFILE ERROR:", err);
        res.status(500).json({ error: err.message });
    }
});

/* --------------------------------------------------
                UPLOAD PROFILE PHOTO
--------------------------------------------------- */

app.post("/upload-profile", upload.single("profile"), async (req, res) => {
    try {
        const userId = req.body.user_id;

        if (!req.file)
            return res.status(400).json({ error: "No file uploaded" });

        const filename = req.file.filename;

        await db.execute(
            "UPDATE users SET profile = ? WHERE id = ?",
            [filename, userId]
        );

        await firestore.collection("users").doc(userId.toString()).update({
            profile: filename
        });

        res.json({ success: true, file: filename });

    } catch (err) {
        console.error("UPLOAD ERROR:", err);
        res.status(500).json({ error: err.message });
    }
});

/* --------------------------------------------------
                  DELETE ACCOUNT
--------------------------------------------------- */

app.post("/delete-account", async (req, res) => {
    try {
        const { user_id, password, birthdate } = req.body;

        const [rows] = await db.execute(
            "SELECT * FROM users WHERE id = ?",
            [user_id]
        );

        if (rows.length === 0)
            return res.status(400).json({ error: "Utilisateur introuvable" });

        const user = rows[0];

        const match = await bcrypt.compare(password, user.password_hash);
        if (!match)
            return res.status(400).json({ error: "Mot de passe incorrect" });

        const cleanBirth = user.birthdate.toISOString().split("T")[0];
        if (cleanBirth !== birthdate)
            return res.status(400).json({ error: "Date de naissance incorrecte" });

        // Delete from MySQL
        await db.execute("DELETE FROM users WHERE id = ?", [user_id]);

        // Delete from Firestore
        await firestore.collection("users").doc(user_id.toString()).delete();

        res.json({ success: true });

    } catch (err) {
        console.error("DELETE ERROR:", err);
        res.status(500).json({ error: "Erreur serveur" });
    }
});

/* --------------------------------------------------
              GET USERS (LIST)
--------------------------------------------------- */

app.get("/users/:id", async (req, res) => {
    const myId = req.params.id;

    const [rows] = await db.execute(
        "SELECT id, username, profile FROM users WHERE id != ? ORDER BY username ASC",
        [myId]
    );

    rows.forEach(u => {
        if (u.profile) {
            u.profile = `https://exciting-learning-production-d784.up.railway.app/uploads/${u.profile}`;
        }
    });

    res.json(rows);
});

/* --------------------------------------------------
        PRIVATE MESSAGES MYSQL (LIST + SEND)
--------------------------------------------------- */

app.get("/messages/:u1/:u2", async (req, res) => {
    const { u1, u2 } = req.params;

    const [rows] = await db.execute(
        `SELECT * FROM messages_private
         WHERE (sender_id = ? AND receiver_id = ?)
            OR (sender_id = ? AND receiver_id = ?)
         ORDER BY timestamp ASC`,
        [u1, u2, u2, u1]
    );

    res.json(rows);
});

app.post("/messages/send", async (req, res) => {
    const { sender_id, receiver_id, content } = req.body;

    await db.execute(
        `INSERT INTO messages_private (sender_id, receiver_id, content)
         VALUES (?, ?, ?)`,
        [sender_id, receiver_id, content]
    );

    res.json({ success: true });
});

/* --------------------------------------------------
                     ROOT
--------------------------------------------------- */

app.get("/", (_, res) =>
    res.json({ message: "IslamicApp backend is running 🚀" })
);

/* --------------------------------------------------
                 START SERVER
--------------------------------------------------- */

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Backend Running on ${PORT}`));
