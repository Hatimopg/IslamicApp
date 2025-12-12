import express from "express";
import cors from "cors";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import dotenv from "dotenv";
import multer from "multer";
import path from "path";
import fs from "fs";
import fetch from "node-fetch";  // IMPORTANT
import { db } from "./db.js";
import admin from "firebase-admin";

dotenv.config();

/* ============================================================
                    BETTERSTACK LOGGING (HTTP)
=============================================================== */

async function sendLog(message, data = {}) {
  try {
    await fetch("https://s1628594.eu-nbg-2.betterstackdata.com/logs", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${process.env.LOGTAIL_TOKEN}`   // TON TOKEN mZpv27...
      },
      body: JSON.stringify({
        dt: new Date().toISOString(),
        level: "info",
        message,
        data
      })
    });
  } catch (err) {
    console.error("LOG ERROR →", err.message);
  }
}

/* ============================================================
                    FIREBASE ADMIN INIT
=============================================================== */

if (!process.env.FIREBASE_JSON) {
  console.error("❌ FIREBASE_JSON variable missing!");
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
                      TEST LOG ENDPOINT
=============================================================== */

app.get("/log-test", async (req, res) => {
  await sendLog("🔥 TEST — Log system working!");
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

    const newUserId = result.insertId.toString();

    await firestore.collection("users").doc(newUserId).set({
      uid: newUserId,
      username,
      profile: null,
      country,
      region,
      isOnline: false,
      lastSeen: new Date()
    });

    sendLog("User registered", { userId: newUserId });

    res.json({ status: "ok", userId: newUserId });

  } catch (err) {
    sendLog("REGISTER ERROR", { error: err.message });
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

    if (rows.length === 0) {
      sendLog("LOGIN FAILED: username unknown", { username });
      return res.status(400).json({ error: "Utilisateur inconnu" });
    }

    const user = rows[0];

    const match = await bcrypt.compare(password, user.password_hash);
    if (!match) {
      sendLog("LOGIN FAILED: wrong password", { username });
      return res.status(400).json({ error: "Mot de passe incorrect" });
    }

    const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET, {
      expiresIn: "7d",
    });

    await firestore.collection("users").doc(user.id.toString()).update({
      isOnline: true,
      lastSeen: new Date()
    });

    sendLog("User logged in", { userId: user.id });

    res.json({
      token,
      userId: user.id,
      username: user.username,
      country: user.country,
      region: user.region,
      profile: user.profile
    });

  } catch (err) {
    sendLog("LOGIN ERROR", { error: err.message });
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

    sendLog("User logged out", { userId: id });

    res.json({ success: true });

  } catch (err) {
    sendLog("LOGOUT ERROR", { error: err.message });
    res.status(500).json({ error: err.message });
  }
});

/* ============================================================
                            ROOT
=============================================================== */

app.get("/", (req, res) => {
  sendLog("Root endpoint hit");
  res.json({ message: "IslamicApp backend is running 🚀" });
});

/* ============================================================
                        START SERVER
=============================================================== */

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  sendLog("Server started", { port: PORT });
  console.log(`🚀 Backend running on port ${PORT}`);
});
