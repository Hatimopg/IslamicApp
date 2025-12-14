import dotenv from "dotenv";
dotenv.config();

import mysql from "mysql2";
import { logError, logInfo } from "./logger.js";

/*
  db.js — Pool MySQL optimisé pour Railway / Serverless
  ------------------------------------------------------
  - SSL automatique si DB_SSL=true dans .env
  - Pool avec reconnexion automatique
  - Logs propres en cas d'erreur
*/

const useSSL = process.env.DB_SSL === "true";

logInfo("🔌 Initialisation MySQL", {
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  ssl: useSSL,
});

export const db = mysql
  .createPool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    port: Number(process.env.DB_PORT) || 3306,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    ssl: useSSL ? { rejectUnauthorized: false } : false,
  })
  .promise();

// Test immédiat de connexion + log
db.query("SELECT 1")
  .then(() => logInfo("🟢 MySQL connecté avec succès"))
  .catch((err) => {
    logError("🔴 ERREUR lors de la connexion MySQL", {
      message: err.message,
      stack: err.stack,
    });
  });
