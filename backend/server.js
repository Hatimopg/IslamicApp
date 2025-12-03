import express from "express";
import cors from "cors";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import dotenv from "dotenv";
import { db } from "./db.js";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

// REGISTER
// REGISTER
app.post("/register", async (req, res) => {
    try {
        const { username, password, country, region, birthdate } = req.body;

        console.log("📩 /register received:", req.body);

        const hash = await bcrypt.hash(password, 10);

        const [result] = await db.execute(
            "INSERT INTO users (username, password_hash, country, region, birthdate) VALUES (?, ?, ?, ?, ?)",
            [username, hash, country, region, birthdate]
        );

        console.log("✅ INSERT OK:", result);

        res.json({ status: "ok" });

    } catch (err) {
        console.error("❌ ERROR IN /register:", err);
        res.status(500).json({ error: "server error", details: err.message });
    }
});


// LOGIN
app.post("/login", async (req, res) => {
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
        {
            id: user.id,
            country: user.country,
            region: user.region
        },
        process.env.JWT_SECRET,
        { expiresIn: "7d" }
    );

    res.json({ token });
});

app.post("/change-password", async (req, res) => {
    const { user_id, old_password, new_password } = req.body;

    const [rows] = await db.execute("SELECT * FROM users WHERE id = ?", [user_id]);

    if (rows.length === 0)
        return res.status(400).json({ error: "Utilisateur introuvable" });

    const user = rows[0];

    const match = await bcrypt.compare(old_password, user.password_hash);
    if (!match)
        return res.status(400).json({ error: "Ancien mot de passe incorrect" });

    const newHash = await bcrypt.hash(new_password, 10);

    await db.execute("UPDATE users SET password_hash = ? WHERE id = ?", [newHash, user_id]);

    res.json({ success: true });
});

app.get("/profile/:id", async (req, res) => {
    const { id } = req.params;
    const [rows] = await db.execute("SELECT id, username, country, region, birthdate FROM users WHERE id = ?", [id]);

    if (rows.length === 0)
        return res.status(404).json({ error: "Utilisateur non trouvé" });

    res.json(rows[0]);
});


app.get("/", (req, res) => {
  res.json({ message: "IslamicApp backend is running 🚀" });
});


// SERVER
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`🚀 Backend Running on port: ${PORT}`);
});
