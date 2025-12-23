import express from "express";
import cors from "cors";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import dotenv from "dotenv";
import multer from "multer";
import path from "path";
import fs from "fs";
import admin from "firebase-admin";
import svgCaptcha from "svg-captcha";

import { db } from "./db.js";
import { auth } from "./auth.js";
import { logError } from "./logger.js";

dotenv.config();

/* ============================================================
   MEMORY STORES
=============================================================== */
const loginAttempts = new Map(); // ip -> { count, blockedUntil }
const captchaStore = new Map();  // ip -> { text, expires }

/* ============================================================
   PASSWORD REGEX
=============================================================== */
const passwordRegex =
  /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;

/* ============================================================
   FIREBASE INIT
=============================================================== */
if (!process.env.FIREBASE_JSON) {
  logError("❌ FIREBASE_JSON missing");
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(
    JSON.parse(process.env.FIREBASE_JSON)
  ),
});

const firestore = admin.firestore();

/* ============================================================
   EXPRESS INIT
=============================================================== */
const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static("public"));

/* ============================================================
   CAPTCHA IMAGE (SVG)
=============================================================== */
app.get("/captcha-image", (req, res) => {
  const ip = req.ip;

  const captcha = svgCaptcha.create({
    size: 5,
    noise: 3,
    color: true,
    background: "#f2f2f2",
  });

  captchaStore.set(ip, {
    text: captcha.text.toLowerCase(),
    expires: Date.now() + 2 * 60 * 1000, // 2 minutes
  });

  res.type("svg");
  res.status(200).send(captcha.data);
});

/* ============================================================
   LOGIN (CAPTCHA IMAGE + DELAY ESCALATION)
=============================================================== */
app.post("/login", async (req, res) => {
  const { username, password, captcha } = req.body;
  const ip = req.ip;
  const now = Date.now();

  // ⏱️ CHECK DELAY
  const attempt = loginAttempts.get(ip);
  if (attempt && attempt.blockedUntil > now) {
    const min = Math.ceil((attempt.blockedUntil - now) / 60000);
    return res
      .status(429)
      .json({ error: `Réessaie dans ${min} minute(s)` });
  }

  // 🔐 CAPTCHA CHECK (SI PRÉSENT)
  const captchaData = captchaStore.get(ip);
  if (captchaData) {
    if (captchaData.expires < now) {
      captchaStore.delete(ip);
      return res.status(400).json({ error: "Captcha expiré" });
    }

    if (!captcha || captcha.toLowerCase() !== captchaData.text) {
      return res.status(400).json({ error: "Captcha incorrect" });
    }

    captchaStore.delete(ip);
  }

  // 🔎 USER CHECK
  const [rows] = await db.execute(
    "SELECT * FROM users WHERE username = ?",
    [username]
  );

  if (rows.length === 0) {
    registerFail(ip);
    return res.status(400).json({ error: "Identifiants incorrects" });
  }

  const user = rows[0];
  const ok = await bcrypt.compare(password, user.password_hash);

  if (!ok) {
    registerFail(ip);
    return res.status(400).json({ error: "Identifiants incorrects" });
  }

  // ✅ SUCCESS → RESET SECURITY
  loginAttempts.delete(ip);
  captchaStore.delete(ip);

  await firestore.collection("users").doc(user.id.toString()).update({
    isOnline: true,
    lastSeen: new Date(),
  });

  const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET, {
    expiresIn: "7d",
  });

  res.json({
    token,
    userId: user.id,
    username: user.username,
    country: user.country,
    region: user.region,
    profile: user.profile ?? "",
  });
});

/* ============================================================
   FAIL HANDLER (DELAY + CAPTCHA)
=============================================================== */
function registerFail(ip) {
  const now = Date.now();
  let entry = loginAttempts.get(ip) || { count: 0, blockedUntil: 0 };
  entry.count++;

  let delay;
  if (entry.count === 1) delay = 5;
  else if (entry.count === 2) delay = 15;
  else if (entry.count === 3) delay = 30;
  else delay = 60;

  entry.blockedUntil = now + delay * 60 * 1000;
  loginAttempts.set(ip, entry);

  // 🔐 CAPTCHA AFTER 2 FAILS
  if (entry.count >= 2) {
    const captcha = svgCaptcha.create({
      size: 5,
      noise: 3,
      color: true,
    });

    captchaStore.set(ip, {
      text: captcha.text.toLowerCase(),
      expires: now + 2 * 60 * 1000,
    });
  }
}

/* ============================================================
   REGISTER
=============================================================== */
app.post("/register", async (req, res) => {
  const { username, password, country, region, birthdate } = req.body;

  if (!passwordRegex.test(password))
    return res.status(400).json({ error: "Mot de passe faible" });

  const [check] = await db.execute(
    "SELECT id FROM users WHERE username = ?",
    [username]
  );
  if (check.length > 0)
    return res.status(400).json({ error: "Username déjà utilisé" });

  const hash = await bcrypt.hash(password, 12);
  const [r] = await db.execute(
    `INSERT INTO users (username,password_hash,country,region,birthdate)
     VALUES (?,?,?,?,?)`,
    [username, hash, country, region, birthdate]
  );

  await firestore.collection("users").doc(r.insertId.toString()).set({
    uid: r.insertId.toString(),
    username,
    country,
    region,
    isOnline: false,
    lastSeen: new Date(),
  });

  res.json({ success: true });
});

/* ============================================================
   CHANGE PASSWORD (JWT)
=============================================================== */
app.post("/change-password", auth, async (req, res) => {
  const { old_password, new_password } = req.body;

  if (!passwordRegex.test(new_password))
    return res.status(400).json({ error: "Mot de passe faible" });

  const [rows] = await db.execute(
    "SELECT password_hash FROM users WHERE id = ?",
    [req.userId]
  );

  const ok = await bcrypt.compare(old_password, rows[0].password_hash);
  if (!ok)
    return res.status(400).json({ error: "Ancien mot de passe incorrect" });

  const hash = await bcrypt.hash(new_password, 12);
  await db.execute(
    "UPDATE users SET password_hash=? WHERE id=?",
    [hash, req.userId]
  );

  res.json({ success: true });
});

/* ============================================================
   DELETE ACCOUNT (JWT)
=============================================================== */
app.post("/delete-account", auth, async (req, res) => {
  const { password, birthdate } = req.body;

  const [rows] = await db.execute(
    "SELECT password_hash,birthdate FROM users WHERE id=?",
    [req.userId]
  );

  const ok = await bcrypt.compare(password, rows[0].password_hash);
  if (!ok || rows[0].birthdate !== birthdate)
    return res.status(400).json({ error: "Infos incorrectes" });

  await db.execute("DELETE FROM users WHERE id=?", [req.userId]);
  await firestore.collection("users").doc(req.userId.toString()).delete();

  res.json({ success: true });
});

/* ============================================================
   UPLOAD PROFILE
=============================================================== */
const uploadFolder = "uploads";
if (!fs.existsSync(uploadFolder)) fs.mkdirSync(uploadFolder);

const upload = multer({
  storage: multer.diskStorage({
    destination: (_, __, cb) => cb(null, uploadFolder),
    filename: (_, file, cb) =>
      cb(null, Date.now() + "-" + file.originalname),
  }),
});

app.post("/upload-profile", auth, upload.single("profile"), async (req, res) => {
  await db.execute("UPDATE users SET profile=? WHERE id=?", [
    req.file.filename,
    req.userId,
  ]);

  await firestore.collection("users").doc(req.userId.toString()).update({
    profile: req.file.filename,
  });

  res.json({ success: true });
});

/* ============================================================
   START SERVER
=============================================================== */
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log("🚀 Backend prêt sur port " + PORT));
