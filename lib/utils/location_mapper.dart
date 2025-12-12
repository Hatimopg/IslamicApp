final Map<String, String> belgiumCities = {
  "Bruxelles": "Brussels",
  "Hainaut": "Mons",
  "Liège": "Liège",
  "Flandre Occidentale": "Bruges",
  "Flandre Orientale": "Gand",
  "Luxembourg": "Arlon",
  "Namur": "Namur",
  "Brabant Wallon": "Wavre",
};

final Map<String, String> franceCities = {
  "Île-de-France": "Paris",
  "Auvergne-Rhône-Alpes": "Lyon",
  "Occitanie": "Toulouse",
  "Hauts-de-France": "Lille",
  "Grand Est": "Strasbourg",
  "Normandie": "Rouen",
  "Nouvelle-Aquitaine": "Bordeaux",
  "Bretagne": "Rennes",
};

final Map<String, String> moroccoCities = {
  "Casablanca-Settat": "Casablanca",
  "Rabat-Salé-Kénitra": "Rabat",
  "Fès-Meknès": "Fes",
  "Marrakech-Safi": "Marrakech",
  "Tanger-Tétouan-Al Hoceima": "Tanger",
  "Souss-Massa": "Agadir",
  "Oriental": "Oujda",
  "Laâyoune-Sakia El Hamra": "Laayoune",
};

String resolveCity(String country, String region) {
  if (country == "Belgique") {
    return belgiumCities[region] ?? "Brussels";
  }
  if (country == "France") {
    return franceCities[region] ?? "Paris";
  }
  if (country == "Maroc") {
    return moroccoCities[region] ?? "Casablanca";
  }

  return "Brussels"; // fallback
}
