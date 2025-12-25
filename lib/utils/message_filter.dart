class MessageFilter {
  static final List<String> forbiddenWords = [
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

  static bool containsForbidden(String text) {
    final normalized = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '');

    return forbiddenWords.any(
          (word) => RegExp(r'\b' + word + r'\b').hasMatch(normalized),
    );
  }
}
