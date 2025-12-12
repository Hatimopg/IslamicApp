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

dotenv.config();

/* ============================================================
                GLOBAL CRASH HANDLING (ADVANCED)
=============================================================== */
process.on("uncaughtException", (err) => {
  logError("🔥 UNCAUGHT EXCEPTION", {
    message: err.message,
    stack: err.stack,
  });
});

process.on("unhandledRejection", (reason) => {
  logError("🔥 UNHANDLED PROMISE", {
    reason: reason?.message ?? reason,
    stack: reason?.stack ?? null,
  });
});

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
             REQUEST LOGGER + RESPONSE TIME
=============================================================== */
app.use((req, res, next) => {
  const start = Date.now();

  res.on("finish", () => {
    const duration = Date.now() - start;
    logInfo("🟦 Request handled", {
      method: req.method,
      url: req.originalUrl,
      status: res.statusCode,
      duration_ms: duration,
    });
  });

  next();
});

/* ============================================================
                    MULTER UPLOAD
=============================================================== */
const uploadFolder = "uploads";
if (!fs.existsSync(uploadFolder)) fs.mkdirSync(uploadFolder);

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadFolder),
  filename: (req, file, cb) => {
    const unique = Date.now() + "-" + Math.floor(Math.random() * 1e9);
    cb(null, unique + path.extname(file.originalname));
  },
});
const upload = multer({ storage });

app.use("/uploads", express.static(uploadFolder));

/* ============================================================
                    ROOT (Fix Flutter 404)
=============================================================== */
app.get("/", (req, res) => {
  logInfo("📡 ROOT ping");
  res.json({ ok: true, message: "Backend running 🚀" });
});

/* ============================================================
                    TEST LOG
=============================================================== */
app.get("/log-test", async (req, res) => {
  logInfo("🔥 TEST — Logging OK!");
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
      lastSeen: new Date(),
    });

    logInfo("👤 User created", { userId: newUserId });

    res.json({ status: "ok", userId: newUserId });
  } catch (err) {
    logError("❌ REGISTER ERROR", {
      error: err.message,
      stack: err.stack,
    });
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
      logWarn("⚠ Login failed: unknown user", { username });
      return res.status(400).json({ error: "Utilisateur inconnu" });
    }

    const user = rows[0];
    const match = await bcrypt.compare(password, user.password_hash);

    if (!match) {
      logWarn("⚠ Login failed: wrong password", { username });
      return res.status(400).json({ error: "Mot de passe incorrect" });
    }

    const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET, {
      expiresIn: "7d",
    });

    await firestore.collection("users").doc(user.id.toString()).update({
      isOnline: true,
      lastSeen: new Date(),
    });

    logInfo("🔓 User logged in", { userId: user.id });

    res.json({
      token,
      userId: user.id,
      username: user.username,
      country: user.country,
      region: user.region,
      profile: user.profile,
    });
  } catch (err) {
    logError("❌ LOGIN ERROR", {
      error: err.message,
      stack: err.stack,
    });
    res.status(500).json({ error: err.message });
  }
});

/* ============================================================
                     PROFILE (Fix Flutter)
=============================================================== */
app.get("/profile/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const [rows] = await db.execute(
      "SELECT id, username, country, region, birthdate, profile FROM users WHERE id = ?",
      [id]
    );

    if (rows.length === 0) {
      logWarn("⚠ Profile not found", { userId: id });
      return res.status(404).json({ error: "Utilisateur non trouvé" });
    }

    if (rows[0].profile) {
      rows[0].profile = `https://exciting-learning-production-d784.up.railway.app/uploads/${rows[0].profile}`;
    }

    logInfo("📄 Profile fetched", { userId: id });

    res.json(rows[0]);
  } catch (err) {
    logError("❌ PROFILE ERROR", {
      error: err.message,
      stack: err.stack,
    });
    res.status(500).json({ error: err.message });
  }
});

/* ============================================================
                     USERS FULL (Messenger)
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
    snapshot.forEach((doc) => (fsUsers[doc.id] = doc.data()));

    users.forEach((u) => {
      if (u.profile) {
        u.profile = `https://exciting-learning-production-d784.up.railway.app/uploads/${u.profile}`;
      }
      u.isOnline = fsUsers[u.id]?.isOnline ?? false;
      u.lastSeen = fsUsers[u.id]?.lastSeen ?? null;
    });

    logInfo("👥 Users list fetched", { count: users.length });

    res.json(users);
  } catch (err) {
    logError("❌ USERS-FULL ERROR", {
      error: err.message,
      stack: err.stack,
    });
    res.status(500).json({ error: err.message });
  }
});

/* ============================================================
                     UPLOAD PROFILE
=============================================================== */
app.post("/upload-profile", upload.single("profile"), async (req, res) => {
  try {
    const userId = req.body.user_id;

    if (!req.file) {
      logWarn("⚠ Upload failed: no file", { userId });
      return res.status(400).json({ error: "No file uploaded" });
    }

    const filename = req.file.filename;

    await db.execute("UPDATE users SET profile = ? WHERE id = ?", [
      filename,
      userId,
    ]);

    await firestore.collection("users").doc(userId.toString()).update({
      profile: filename,
    });

    logInfo("🖼 Profile updated", { userId, file: filename });

    res.json({ success: true, file: filename });
  } catch (err) {
    logError("❌ UPLOAD ERROR", {
      error: err.message,
      stack: err.stack,
    });
    res.status(500).json({ error: err.message });
  }
});

/* ============================================================
                     404 HANDLER
=============================================================== */
app.use((req, res) => {
  logWarn("❌ 404 Not Found", { url: req.originalUrl });
  res.status(404).json({ error: "Not found" });
});

/* ============================================================
                    START SERVER
=============================================================== */
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  logInfo("🚀 Server started", { port: PORT });
  console.log(`🚀 Backend running on port ${PORT}`);
});
