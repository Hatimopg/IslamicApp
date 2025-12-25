import jwt from "jsonwebtoken";
import { db } from "./db.js";

export async function auth(req, res, next) {
  const header = req.headers.authorization;

  // 🔐 Header absent ou mal formé
  if (!header || !header.startsWith("Bearer ")) {
    return res.status(401).json({ error: "No or malformed token" });
  }

  // 🔑 Extraction propre du token
  const token = header.split(" ")[1];

  if (!token) {
    return res.status(401).json({ error: "Token missing" });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // 🔥 ID utilisateur
    req.userId = decoded.id;

    // 🔥 RÉCUPÉRATION DU RÔLE
    const [rows] = await db.execute(
      "SELECT role FROM users WHERE id=?",
      [req.userId]
    );

    if (!rows.length) {
      return res.status(401).json({ error: "User not found" });
    }

    req.userRole = rows[0].role; // user | moderator | admin

    next();
  } catch (err) {
    console.error("JWT ERROR =>", err.message);
    return res.status(401).json({ error: "Invalid token" });
  }
}
