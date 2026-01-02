import express from "express";
import cors from "cors";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import dotenv from "dotenv";
import multer from "multer";
import admin from "firebase-admin";
import svgCaptcha from "svg-captcha";
import { containsForbiddenWords } from "./utils/messageFilter.js";

import { v2 as cloudinary } from "cloudinary";
import { CloudinaryStorage } from "multer-storage-cloudinary";

import { db } from "./db.js";
import { auth } from "./auth.js";
import { logError } from "./logger.js";

dotenv.config();


/* ============================================================
   EXPRESS INIT
=============================================================== */
const app = express();
app.use(cors());
app.use(express.json());

// 🔓 FICHIERS STATIQUES (privacy policy)
app.use(express.static("public"));

/* ============================================================
   CLOUDINARY CONFIG
=============================================================== */
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_NAME,
  api_key: process.env.CLOUDINARY_KEY,
  api_secret: process.env.CLOUDINARY_SECRET,
});

/* ============================================================
   MEMORY STORES
=============================================================== */
const loginAttempts = new Map();
const captchaStore = new Map();

/* ============================================================
   PASSWORD REGEX
=============================================================== */
const passwordRegex =
  /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;

/* ============================================================
   FIREBASE INIT
=============================================================== */
if (!process.env.FIREBASE_JSON_BASE64) {
  console.error("❌ FIREBASE_JSON_BASE64 missing");
  process.exit(1);
}

const firebaseJson = Buffer
  .from(process.env.FIREBASE_JSON_BASE64, "base64")
  .toString("utf8");

admin.initializeApp({
  credential: admin.credential.cert(JSON.parse(firebaseJson)),
});


const firestore = admin.firestore();

/* ============================================================
   CAPTCHA IMAGE
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
    expires: Date.now() + 2 * 60 * 1000,
  });

  res.type("svg").status(200).send(captcha.data);
});

/* ============================================================
   LOGIN
=============================================================== */
app.post("/login", async (req, res) => {
  const { username, password, captcha } = req.body;
  const ip = req.ip;
  const now = Date.now();

  const attempt = loginAttempts.get(ip);
  if (attempt && attempt.blockedUntil > now) {
    const min = Math.ceil((attempt.blockedUntil - now) / 60000);
    return res.status(429).json({ error: `Réessaie dans ${min} minute(s)` });
  }

  const captchaData = captchaStore.get(ip);
  if (captchaData) {
    if (captchaData.expires < now)
      return res.status(400).json({ error: "Captcha expiré" });

    if (!captcha || captcha.toLowerCase() !== captchaData.text)
      return res.status(400).json({ error: "Captcha incorrect" });

    captchaStore.delete(ip);
  }

  const [rows] = await db.execute(
    "SELECT * FROM users WHERE username=?",
    [username]
  );

  if (!rows.length) {
    registerFail(ip);
    return res.status(400).json({ error: "Identifiants incorrects" });
  }

  const user = rows[0];
  const ok = await bcrypt.compare(password, user.password_hash);

  if (!ok) {
    registerFail(ip);
    return res.status(400).json({ error: "Identifiants incorrects" });
  }

  loginAttempts.delete(ip);

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
   FAIL HANDLER
=============================================================== */
function registerFail(ip) {
  const now = Date.now();
  const entry = loginAttempts.get(ip) || { count: 0, blockedUntil: 0 };
  entry.count++;

  const delay = entry.count === 1 ? 5 : entry.count === 2 ? 15 : 30;
  entry.blockedUntil = now + delay * 60 * 1000;

  loginAttempts.set(ip, entry);
}

/* ============================================================
   REGISTER
=============================================================== */
app.post("/register", async (req, res) => {
  const { username, password, country, region, birthdate } = req.body;

  if (!passwordRegex.test(password))
    return res.status(400).json({ error: "Mot de passe faible" });

  const [check] = await db.execute(
    "SELECT id FROM users WHERE username=?",
    [username]
  );

  if (check.length)
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
   UPLOAD PROFILE (CLOUDINARY)
=============================================================== */
const storage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder: "profiles",
    allowed_formats: ["jpg", "jpeg", "png", "webp"],
    transformation: [{ width: 256, height: 256, crop: "fill", gravity: "face" }],
  },
});

const upload = multer({ storage });

app.post("/upload-profile", auth, upload.single("profile"), async (req, res) => {
  const imageUrl = req.file.path;

  await db.execute("UPDATE users SET profile=? WHERE id=?", [
    imageUrl,
    req.userId,
  ]);

  await firestore.collection("users").doc(req.userId.toString()).update({
    profile: imageUrl,
  });

  res.json({ success: true, profile: imageUrl });
});

/* ============================================================
   PROFILE
=============================================================== */
app.get("/profile", auth, async (req, res) => {
  const [rows] = await db.execute(
    "SELECT id,username,country,region,birthdate,profile FROM users WHERE id=?",
    [req.userId]
  );

  if (!rows.length)
    return res.status(404).json({ error: "User not found" });

  res.json(rows[0]);
});

app.post("/delete-account", auth, async (req, res) => {
  const { password } = req.body;

  const [rows] = await db.execute(
    "SELECT password_hash FROM users WHERE id=?",
    [req.userId]
  );

  const ok = await bcrypt.compare(password, rows[0].password_hash);
  if (!ok) return res.status(401).json({ error: "Mot de passe incorrect" });

  await db.execute("DELETE FROM users WHERE id=?", [req.userId]);
  await firestore.collection("users").doc(req.userId.toString()).delete();

  res.json({ success: true });
});

/* ============================================================
   filtre des bad words
=============================================================== */

app.post("/chat/send", auth, async (req, res) => {
  try {
    const { message, chatType, chatId, toUserId } = req.body;

    if (!message || !message.trim()) {
      return res.status(400).json({ error: "Message vide" });
    }

    // 🚫 FILTRE LANGAGE
    if (containsForbiddenWords(message)) {
      return res.status(403).json({
        error: "Message refusé : langage interdit",
      });
    }

    // 🔥 PRIVATE CHAT
    if (chatType === "private") {
      await firestore
        .collection("private_chats")
        .doc(chatId)
        .collection("messages")
        .add({
          from: req.userId,
          to: toUserId,
          text: message,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          seen: false,
        });
    }

    // 🔥 COMMUNITY CHAT
    if (chatType === "community") {
      await firestore.collection("community_messages").add({
        message,
        sender_id: req.userId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    res.json({ success: true });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: "Erreur serveur" });
  }
});


/* ============================================================
   admin
=============================================================== */

app.post("/chat/send", auth, async (req, res) => {
  try {
    const { message, chatType, chatId, toUserId } = req.body;

    if (!message || !message.trim()) {
      return res.status(400).json({ error: "Message vide" });
    }

    // 🚫 Filtre langage
    if (containsForbiddenWords(message)) {
      return res.status(403).json({
        error: "Message refusé : langage interdit",
      });
    }

    // 🔇 Vérif mute
    const userDoc = await firestore
      .collection("users")
      .doc(req.userId.toString())
      .get();

    if (userDoc.data()?.mutedUntil > Date.now()) {
      return res.status(403).json({
        error: "Vous êtes temporairement mute",
      });
    }

    // 🔥 COMMUNITY
    if (chatType === "community") {
      await firestore.collection("community_messages").add({
        message,
        sender_id: req.userId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // 🔥 PRIVATE
    if (chatType === "private") {
      await firestore
        .collection("private_chats")
        .doc(chatId)
        .collection("messages")
        .add({
          from: req.userId,
          to: toUserId,
          text: message,
          seen: false,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
    }

    res.json({ success: true });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: "Erreur serveur" });
  }
});


app.delete("/moderation/message/:collection/:id", auth, async (req, res) => {
  if (req.userRole !== "moderator" && req.userRole !== "admin") {
    return res.status(403).json({ error: "Accès refusé" });
  }

  await firestore
    .collection(req.params.collection)
    .doc(req.params.id)
    .delete();

  res.json({ success: true });
});



app.post("/moderation/mute/:userId", auth, async (req, res) => {
  if (req.userRole !== "moderator" && req.userRole !== "admin") {
    return res.status(403).json({ error: "Accès refusé" });
  }

  await firestore.collection("users").doc(req.params.userId).update({
    mutedUntil: Date.now() + 24 * 60 * 60 * 1000, // 24h
  });

  res.json({ success: true });
});

/* ============================================================
   START SERVER
=============================================================== */
const PORT = process.env.PORT || 3000;
app.listen(PORT, () =>
  console.log("🚀 Backend prêt sur port " + PORT)
);