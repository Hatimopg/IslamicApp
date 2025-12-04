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

/* ============================================================
                    FIREBASE ADMIN INIT
=============================================================== */

if (!process.env.FIREBASE_JSON) {
    console.error("❌ ERROR: FIREBASE_JSON variable missing in Railway!");
    process.exit(1);
}

const serviceAccount = JSON.parse(process.env.FIREBASE_JSON);

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const firestore = admin.firestore();

/* ============================================================
                        EXPRESS INIT
=============================================================== */

const app = express();
app.use(cors());
app.use(express.json());

/* ============================================================
                    MULTER UPLOAD CONFIG
=============================================================== */

const uploadFolder = "uploads";

if (!fs.existsSync(uploadFolder)) {
    fs.mkdirSync(uploadFolder);
}

const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, uploadFolder),
    filename: (req, file, cb) => {
        const unique = Date.now() + "-" + Math.round(Math.random() * 1e9);
        cb(null, unique + path.extname(file.originalname));
    },
});
const upload = multer({ storage });

app.use("/uploads", express.static(uploadFolder));

/* ============================================================
                        REGISTER
=============================================================== */

app.post("/register", async (req, res) => {
    try {
        const { username, password, country, region, birthdate } = req.body;

        const hash = await bcrypt.hash(password, 10);

        const [result] = await db.execute(
            `INSERT INTO users (username, password_hash, country, region, birthdate)
             VALUES (?, ?, ?, ?, ?)`,
            [username, hash, country, region, birthdate]
        );

        const newUserId = result.insertId.toString();

        // FIRESTORE USER DOCUMENT
        await firestore.collection("users").doc(newUserId).set({
            uid: newUserId,
            username,
            profile: null,
            country,
            region,
            isOnline: false,
            lastSeen: new Date()
        });

        res.json({ status: "ok", userId: newUserId });

    } catch (err) {
        console.error("REGISTER ERROR:", err);
        res.status(500).json({ error: err.message });
    }
});

/* ============================================================
                            LOGIN
=============================================================== */

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

        const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET, {
            expiresIn: "7d",
        });

        // FIRESTORE → user online
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

/* ============================================================
                            LOGOUT
=============================================================== */

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

/* ============================================================
                        PROFILE
=============================================================== */

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

/* ============================================================
                    UPLOAD PROFILE PIC
=============================================================== */

app.post("/upload-profile", upload.single("profile"), async (req, res) => {
    try {
        const userId = req.body.user_id;
        if (!req.file)
            return res.status(400).json({ error: "No file uploaded" });

        const filename = req.file.filename;

        // MySQL update
        await db.execute(
            "UPDATE users SET profile = ? WHERE id = ?",
            [filename, userId]
        );

        // Firestore update
        await firestore.collection("users").doc(userId.toString()).update({
            profile: filename
        });

        res.json({ success: true, file: filename });

    } catch (err) {
        console.error("UPLOAD ERROR:", err);
        res.status(500).json({ error: err.message });
    }
});

/* ============================================================
                     DELETE ACCOUNT
=============================================================== */

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

        await db.execute("DELETE FROM users WHERE id = ?", [user_id]);
        await firestore.collection("users").doc(user_id.toString()).delete();

        res.json({ success: true });

    } catch (err) {
        console.error("DELETE ERROR:", err);
        res.status(500).json({ error: "Erreur serveur" });
    }
});

/* ============================================================
                USERS + ONLINE/OFFLINE STATUS
=============================================================== */

app.get("/users-full/:id", async (req, res) => {
    try {
        const myId = req.params.id;

        const [users] = await db.execute(
            `SELECT id, username, profile FROM users WHERE id != ? ORDER BY username ASC`,
            [myId]
        );

        const snapshot = await firestore.collection("users").get();
        const fsUsers = {};
        snapshot.forEach(doc => fsUsers[doc.id] = doc.data());

        users.forEach(u => {
            if (u.profile) {
                u.profile = `https://exciting-learning-production-d784.up.railway.app/uploads/${u.profile}`;
            }
            u.isOnline = fsUsers[u.id]?.isOnline ?? false;
            u.lastSeen = fsUsers[u.id]?.lastSeen ?? null;
        });

        res.json(users);

    } catch (err) {
        console.error("USERS-FULL ERROR:", err);
        res.status(500).json({ error: err.message });
    }
});

/* ============================================================
                        fix le user pr firebase
=============================================================== */
app.get("/fix-users", async (req, res) => {
    const [rows] = await db.execute("SELECT * FROM users");

    for (let u of rows) {
        await firestore.collection("users").doc(u.id.toString()).set({
            uid: u.id.toString(),
            username: u.username,
            profile: u.profile ?? null,
            country: u.country,
            region: u.region,
            birthdate: u.birthdate,
            isOnline: false,
            lastSeen: new Date()
        }, { merge: true });
    }

    res.json({ status: "ok", fixed: rows.length });
});

/* ============================================================
                        ROOT
=============================================================== */

app.get("/", (req, res) => {
    res.json({ message: "IslamicApp backend is running 🚀" });
});

/* ============================================================
                        START SERVER
=============================================================== */

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Backend running on port ${PORT}`));
