# 📦 Installation flutter_map

## ⚠️ Important

J'ai ajouté `flutter_map` et `latlong2` dans `pubspec.yaml` pour afficher une vraie carte OpenStreetMap.

## 🔧 Installation

Exécutez cette commande pour installer les nouvelles dépendances :

```bash
cd C:\allo_dakar_repo\allo-dakar-stitch-cursor
flutter pub get
```

## ✅ Ce qui a été fait

1. **Carte OpenStreetMap** : Remplacement du placeholder par une vraie carte interactive
2. **Favicon TeMove** : Création d'un favicon SVG avec le logo TeMove
3. **Recherche de destination** : 
   - Recherche manuelle (appuyez sur Entrée ou cliquez sur le bouton de recherche)
   - Bouton de géolocalisation pour utiliser votre position actuelle
   - Plus d'erreurs de recherche automatique

## 🗺️ Fonctionnalités de la carte

- ✅ Carte OpenStreetMap réelle (gratuite, pas besoin de clé API)
- ✅ Marqueur de position avec votre localisation
- ✅ Zoom et déplacement de la carte
- ✅ Bouton pour actualiser la position
- ✅ Affichage automatique de votre position au chargement

## 🎯 Utilisation

1. **Départ** : Rempli automatiquement avec votre position
2. **Destination** : 
   - Tapez une adresse et appuyez sur Entrée
   - OU cliquez sur le bouton de recherche (loupe)
   - OU cliquez sur le bouton de localisation pour utiliser votre position actuelle

## 📝 Note

La carte OpenStreetMap nécessite une connexion Internet pour charger les tuiles de carte.

