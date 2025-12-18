import jwt from "jsonwebtoken";

export function auth(req, res, next) {
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

    // 🔥 TRÈS IMPORTANT
    req.userId = decoded.id;

    next();
  } catch (err) {
    console.error("JWT ERROR =>", err.message);
    return res.status(401).json({ error: "Invalid token" });
  }
}
