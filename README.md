# Météo Open-Meteo Flutter

Cette application Flutter permet d'afficher les données météo d'un lieu donné, en utilisant l'API Open-Meteo. L'utilisateur peut rechercher la météo par nom de ville ou par coordonnées géographiques, et choisir un intervalle de temps précis.

## Fonctionnalités

- Recherche météo par **nom de ville** (géocodage automatique via OpenStreetMap)
- Recherche météo par **latitude/longitude**
- Sélection **date et heure de début/fin**
- Affichage des données météo :
  - Température
  - Température ressentie
  - Humidité
  - Vent
  - Précipitations
  - Couverture nuageuse
- **Tableau responsive** : s'adapte à la largeur de l'écran, scroll horizontal sur mobile

## Utilisation

1. Saisir le nom d'une ville ou les coordonnées (latitude/longitude).
2. Choisir la date (l'heure est optionnelle) de début et de fin.
3. Cliquer sur "Obtenir la météo".
4. Les données météo s'affichent dans un tableau.

## Structure du code

- `lib/main.dart` :
  - `WeatherHomePage` : page principale avec le formulaire de recherche et l'affichage des résultats.
  - `WeatherDataTable` : widget qui affiche les données météo dans un tableau responsive.
  - `_fetchLatLonFromCity` : convertit un nom de ville en latitude/longitude (API Nominatim).
  - `_fetchWeather` : interroge l'API Open-Meteo avec les coordonnées et l'intervalle de temps.
  - `_combineDateTime` : fusionne une date et une heure en un objet `DateTime`.

## Dépendances

- [http](https://pub.dev/packages/http) : pour les requêtes réseau
- Flutter Material

## API utilisées

- [Open-Meteo](https://open-meteo.com/)
- [Nominatim (OpenStreetMap)](https://nominatim.openstreetmap.org/)
