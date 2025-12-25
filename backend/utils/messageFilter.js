export const forbiddenWords = [
  "zebi",
      "con",
      "connard",
      "pute",
      "salope",
      "merde",
      "fuck",
      "fdp",
      "nique",
      "enculé",
      "sex",
      "porno",
      "xxx",
      "tabon",
      "l7wa",
      "mok",
      "putain",
      "ptn",
      "9wd",
      "9owed",
      "sybau",
      "baiser",
      "bz",
      "enculé",
      "encule",
      "chatte",
      "bite",
];

export function containsForbiddenWords(message) {
  const normalized = message
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, "");

  return forbiddenWords.some(word =>
    new RegExp(`\\b${word}\\b`, "i").test(normalized)
  );
}
