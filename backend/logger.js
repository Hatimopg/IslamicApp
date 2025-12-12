import fetch from "node-fetch";

// Advanced BetterStack logger
export async function logInfo(message, data = {}) {
  await send("info", message, data);
}

export async function logWarn(message, data = {}) {
  await send("warning", message, data);
}

export async function logError(message, data = {}) {
  await send("error", message, data);
}

async function send(level, message, data) {
  try {
    await fetch("https://s1628594.eu-nbg-2.betterstackdata.com/logs", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${process.env.LOGTAIL_TOKEN}`
      },
      body: JSON.stringify({
        dt: new Date().toISOString(),
        level,
        message,
        data
      })
    });
  } catch (err) {
    console.error("LOGGING FAILURE →", err);
  }
}
