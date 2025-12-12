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
import { Logtail } from "@logtail/node";

dotenv.config();

/* ============================================================
                    LOGTAIL LOGGER INIT
=============================================================== */
const logger = new Logtail(process.env.LOGTAIL_TOKEN);

// flush logs when Railway pauses the container
process.on("beforeExit", async () => {
  await logger.flush();
});

// Capture global crashes
process.on("uncaughtException", (err) => {
  logger.error("Uncaught Exception", { error: err.message });
});
process.on("unhandledRejection", (reason) => {
  logger.error("Unhandled Rejection", { reason });
});

/* ============================================================
                    FIREBASE ADMIN INIT
=============================================================== */
if (!process.env.FIREBASE_JSON) {
  logger.error("FIREBASE_JSON variable missing!");
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
                    TEST ENDPOINT FOR LOGTAIL
=============================================================== */
app.get("/log-test", (req, res) => {
  logger.info("🔥 Logtail test triggered!");
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

    logger.info("User registered", { userId: newUserId });

    res.json({ status: "ok", userId: newUserId });

  } catch (err) {
    logger.error("REGISTER ERROR", { error: err.message });
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
      logger.warn("LOGIN FAILED: unknown username", { username });
      return res.status(400).json({ error: "Utilisateur inconnu" });
    }

    const user = rows[0];

    const match = await bcrypt.compare(password, user.password_hash);
    if (!match) {
      logger.warn("LOGIN FAILED: wrong password", { username });
      return res.status(400).json({ error: "Mot de passe incorrect" });
    }

    const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET, {
      expiresIn: "7d",
    });

    await firestore.collection("users").doc(user.id.toString()).update({
      isOnline: true,
      lastSeen: new Date()
    });

    logger.info("User logged in", { userId: user.id });

    res.json({
      token,
      userId: user.id,
      username: user.username,
      country: user.country,
      region: user.region,
      profile: user.profile
    });

  } catch (err) {
    logger.error("LOGIN ERROR", { error: err.message });
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

    logger.info("User logged out", { userId: id });

    res.json({ success: true });

  } catch (err) {
    logger.error("LOGOUT ERROR", { error: err.message });
    res.status(500).json({ error: err.message });
  }
});

/* ============================================================
                        ROOT
=============================================================== */

app.get("/", (req, res) => {
  logger.info("Root endpoint hit");
  res.json({ message: "IslamicApp backend is running 🚀" });
});

/* ============================================================
                        START SERVER
=============================================================== */

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  logger.info("Server started", { port: PORT });
  console.log(`🚀 Backend running on port ${PORT}`);
});
