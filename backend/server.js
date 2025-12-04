import express from "express";
import cors from "cors";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import dotenv from "dotenv";
import multer from "multer";
import path from "path";
import fs from "fs";
import { db } from "./db.js";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

/* ----------------------------------------------
        UPLOADS FOLDER + MULTER CONFIG
------------------------------------------------ */

const uploadFolder = "uploads/";

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

app.use("/uploads", express.static("uploads"));

/* ----------------------------------------------
                    REGISTER
------------------------------------------------ */

app.post("/register", async (req, res) => {
    try {
        const { username, password, country, region, birthdate } = req.body;

        const hash = await bcrypt.hash(password, 10);

        const [result] = await db.execute(
            `INSERT INTO users (username, password_hash, country, region, birthdate)
             VALUES (?, ?, ?, ?, ?)`,
            [username, hash, country, region, birthdate]
        );

        res.json({ status: "ok", userId: result.insertId });

    } catch (err) {
        console.error("❌ REGISTER ERROR:", err);
        res.status(500).json({ error: err.message });
    }
});

/* ----------------------------------------------
                     LOGIN
------------------------------------------------ */

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

        res.json({
            token,
            userId: user.id,
            username: user.username,
            country: user.country,
            region: user.region,
            profile: user.profile
        });

    } catch (err) {
        console.error("❌ LOGIN ERROR:", err);
        res.status(500).json({ error: err.message });
    }
});

/* ----------------------------------------------
               GET USER PROFILE
------------------------------------------------ */

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
        console.error("❌ PROFILE ERROR:", err);
        res.status(500).json({ error: err.message });
    }
});

/* ----------------------------------------------
               CHANGE PASSWORD
------------------------------------------------ */

app.post("/change-password", async (req, res) => {
    const { user_id, old_password, new_password } = req.body;

    try {
        const [rows] = await db.execute("SELECT * FROM users WHERE id = ?", [user_id]);

        if (rows.length === 0)
            return res.status(400).json({ error: "Utilisateur introuvable" });

        const user = rows[0];

        const match = await bcrypt.compare(old_password, user.password_hash);
        if (!match)
            return res.status(400).json({ error: "Ancien mot de passe incorrect" });

        const newHash = await bcrypt.hash(new_password, 10);

        await db.execute(
            "UPDATE users SET password_hash = ? WHERE id = ?",
            [newHash, user_id]
        );

        res.json({ success: true });

    } catch (err) {
        console.error("❌ PASSWORD ERROR:", err);
        res.status(500).json({ error: err.message });
    }
});

/* ----------------------------------------------
               UPLOAD PROFILE PHOTO
------------------------------------------------ */

app.post("/upload-profile", upload.single("profile"), async (req, res) => {
    try {
        const userId = req.body.user_id;

        if (!req.file) return res.status(400).json({ error: "No file uploaded" });

        const filename = req.file.filename; // <-- ON ENREGISTRE JUSTE ÇA

        await db.execute(
            "UPDATE users SET profile = ? WHERE id = ?",
            [filename, userId]
        );

        res.json({ success: true, file: filename });

    } catch (err) {
        console.error("UPLOAD ERROR:", err);
        res.status(500).json({ error: err.message });
    }
});


/* ----------------------------------------------
                     SUPRESSION DU COMPTE
------------------------------------------------ */
app.post("/delete-account", async (req, res) => {
    try {
        const { user_id, password, birthdate } = req.body;

        // Vérifier si l'utilisateur existe
        const [rows] = await db.execute(
            "SELECT * FROM users WHERE id = ?",
            [user_id]
        );

        if (rows.length === 0)
            return res.status(400).json({ error: "Utilisateur introuvable" });

        const user = rows[0];

        // Vérifier mot de passe
        const match = await bcrypt.compare(password, user.password_hash);
        if (!match)
            return res.status(400).json({ error: "Mot de passe incorrect" });

        // Vérifier date de naissance
        const cleanBirth = user.birthdate.toISOString().split("T")[0];
        if (cleanBirth !== birthdate)
            return res.status(400).json({ error: "Date de naissance incorrecte" });

        // Delete user
        await db.execute("DELETE FROM users WHERE id = ?", [user_id]);

        res.json({ success: true });

    } catch (err) {
        console.error("DELETE ERROR:", err);
        res.status(500).json({ error: "Erreur serveur" });
    }
});


/* ----------------------------------------------
                     ROOT TEST
------------------------------------------------ */


app.get("/", (req, res) => {
    res.json({ message: "IslamicApp backend is running 🚀" });
});

/* ----------------------------------------------
                 START SERVER
------------------------------------------------ */

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`🚀 Backend Running on port: ${PORT}`);
});
