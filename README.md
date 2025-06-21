# Météo Open-Meteo Flutter

Cette application Flutter permet d'afficher les données météo d'un lieu donné, en utilisant l'API Open-Meteo. L'utilisateur peut rechercher la météo par nom de ville ou par coordonnées géographiques, et choisir un intervalle de temps précis. Il peut aussi mettre des villes dans une liste de favoris.

## Fonctionnalités

- Recherche météo par nom de ville (géocodage automatique via OpenStreetMap)
- Recherche météo par latitude/longitude
- Sélection de la date (auto-remplie avec la date du jour) et heure de début/fin (optionnelles)
- **Villes favorites** :
  - Ajout/suppression rapide d'une ville favorite (nom + coordonnées)
  - Sélection d'une ville favorite pour remplir automatiquement le formulaire et afficher la météo
  - Les favoris sont sauvegardés et restaurés automatiquement (stockage local)
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
2. Choisir la date (pré-remplie avec la date du jour) et, si besoin, l'heure de début et de fin (optionnelles).
3. Cliquer sur "Obtenir la météo".
4. Les données météo s'affichent dans un tableau responsive.
5. Pour ajouter une ville aux favoris, cliquer sur l'étoile à côté du champ ville. Les favoris sont affichés sous forme de boutons, cliquables pour relancer la recherche automatiquement.

## Structure du code

- `lib/main.dart` :
  - `WeatherHomePage` : page principale avec le formulaire de recherche, la gestion des favoris et l'affichage des résultats.
  - `WeatherDataTable` : widget qui affiche les données météo dans un tableau responsive.
  - `_fetchLatLonFromCity` : convertit un nom de ville en latitude/longitude (API Nominatim).
  - `_fetchWeather` : interroge l'API Open-Meteo avec les coordonnées et l'intervalle de temps.
  - `_combineDateTime` : fusionne une date et une heure en un objet `DateTime`.
  - **Gestion des favoris** : sauvegarde/restauration avec `shared_preferences`.

## Dépendances

- [http](https://pub.dev/packages/http) : pour les requêtes réseau
- [shared_preferences](https://pub.dev/packages/shared_preferences) : pour la sauvegarde locale des favoris
- Flutter Material

## API utilisées

- [Open-Meteo](https://open-meteo.com/)
- [Nominatim (OpenStreetMap)](https://nominatim.openstreetmap.org/)

