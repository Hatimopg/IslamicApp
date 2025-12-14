// logger.js — Version stable & optimisée BetterStack

// Node 18+ possède fetch nativement → pas besoin de node-fetch
// Si tu es en Node 16, décommente :
// import fetch from "node-fetch";

const LOG_URL = "https://s1628594.eu-nbg-2.betterstackdata.com/logs";
const TOKEN = process.env.LOGTAIL_TOKEN;

// -----------------------------
// Fonctions publiques
// -----------------------------
export function logInfo(message, data = {}) {
  sendLog("info", message, data);
}

export function logWarn(message, data = {}) {
  sendLog("warning", message, data);
}

export function logError(message, data = {}) {
  sendLog("error", message, data);
}

// -----------------------------
// Envoi du log
// -----------------------------
function sendLog(level, message, data) {
  try {
    if (!TOKEN) {
      console.warn("⚠ LOGTAIL_TOKEN manquant — Log ignoré :", message);
      return;
    }

    // ⚡ NE PAS bloquer Express : pas de await, juste un fire-and-forget
    fetch(LOG_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${TOKEN}`,
      },
      body: JSON.stringify({
        dt: new Date().toISOString(),
        level,
        message,
        data,
      }),
    }).catch(() => {
      // On ne crash JAMAIS à cause d’un log
      console.warn("⚠ Impossible d'envoyer un log BetterStack.");
    });

  } catch (err) {
    console.error("LOGGING FAILURE →", err);
  }
}
