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
app.post("/register", async (req, res) => {
    const { username, password, country, region, birthdate } = req.body;

    const hash = await bcrypt.hash(password, 10);

    await db.execute(
        "INSERT INTO users (username, password_hash, country, region, birthdate) VALUES (?,?,?,?,?)",
        [username, hash, country, region, birthdate]
    );

    res.json({ status: "ok" });
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

// SERVER
app.listen(process.env.PORT, () => {
    console.log(`Backend OK → http://localhost:${process.env.PORT}`);
});
