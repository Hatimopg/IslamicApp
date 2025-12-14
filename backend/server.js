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
import { logInfo, logWarn, logError } from "./logger.js";
import { auth } from "./auth.js";

dotenv.config();

/* ============================================================
            FIREBASE ADMIN INIT
=============================================================== */
if (!process.env.FIREBASE_JSON) {
  logError("❌ FIREBASE_JSON missing");
  process.exit(1);
}

const serviceAccount = JSON.parse(process.env.FIREBASE_JSON);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const firestore = admin.firestore();

/* ============================================================
                    EXPRESS INIT
=============================================================== */
const app = express();
app.use(cors());
app.use(express.json());

/* ============================================================
              STATIC UPLOAD FOLDER (persistant)
=============================================================== */
const uploadFolder = "uploads";
if (!fs.existsSync(uploadFolder)) fs.mkdirSync(uploadFolder);

app.use("/uploads", express.static(uploadFolder));

/* ============================================================
                      MULTER UPLOAD
=============================================================== */
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadFolder),
  filename: (req, file, cb) => {
    const unique = Date.now() + "-" + Math.floor(Math.random() * 1e9);
    cb(null, unique + path.extname(file.originalname));
  },
});
const upload = multer({ storage });

/* ============================================================
                        ROOT
=============================================================== */
app.get("/", (req, res) => {
  res.json({ ok: true });
});

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

    const uid = result.insertId.toString();

    await firestore.collection("users").doc(uid).set({
      uid,
      username,
      profile: null,
      country,
      region,
      isOnline: false,
      lastSeen: new Date(),
    });

    res.json({ status: "ok", userId: uid });
  } catch (err) {
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

    await firestore.collection("users").doc(user.id.toString()).update({
      isOnline: true,
      lastSeen: new Date(),
    });

    res.json({
      userId: user.id,
      username: user.username,
      country: user.country,
      region: user.region,
      profile: user.profile, // 🔥 ON NE RENVOIE PAS L'URL COMPLÈTE
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* ============================================================
                     GET PROFILE
=============================================================== */
app.get("/profile/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const [rows] = await db.execute(
      "SELECT id, username, country, region, birthdate, profile FROM users WHERE id = ?",
      [id]
    );

    if (rows.length === 0)
      return res.status(404).json({ error: "User not found" });

    const u = rows[0];

    // 🔥 IMPORTANT : ON RENVOIE JUSTE FILENAME
    res.json({
      id: u.id,
      username: u.username,
      country: u.country,
      region: u.region,
      birthdate: u.birthdate,
      profile: u.profile ?? "",
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* ============================================================
                    USER LIST (PRIVATE CHAT)
=============================================================== */
app.get("/users-full/:id", async (req, res) => {
  try {
    const myId = req.params.id;

    const [users] = await db.execute(
      `SELECT id, username, profile FROM users WHERE id != ?`,
      [myId]
    );

    const snapshot = await firestore.collection("users").get();
    const fsUsers = {};
    snapshot.forEach((d) => (fsUsers[d.id] = d.data()));

    const final = users.map((u) => ({
      id: u.id,
      username: u.username,
      profile: u.profile ?? "", // 🔥 jamais d'URL complète
      isOnline: fsUsers[u.id]?.isOnline ?? false,
      lastSeen: fsUsers[u.id]?.lastSeen ?? null,
    }));

    res.json(final);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* ============================================================
                     UPLOAD PROFILE
=============================================================== */
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

    await firestore.collection("users").doc(userId).update({
      profile: filename, // 🔥 pas d'URL ici non plus
    });

    res.json({ success: true, file: filename });
  } catch (err) {
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
      lastSeen: new Date(),
    });

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


/* ============================================================
                         AUTH JWT
=============================================================== */



app.get("/profile/:id", auth, async (req, res) => {
  if (req.userId.toString() !== req.params.id)
    return res.status(403).json({ error: "Forbidden" });

  ...
});

app.get("/users-full/:id", auth, async (req, res) => { ... });

app.post("/upload-profile", auth, upload.single("profile"), async (...) => { ... });

app.post("/logout", auth, async (...) => { ... });

/* ============================================================
                     404 HANDLER
=============================================================== */
app.use((req, res) => {
  res.status(404).json({ error: "Not found" });
});

/* ============================================================
                     START SERVER
=============================================================== */
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log("🚀 Backend running on port " + PORT);
});
