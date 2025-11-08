# 📍 Géolocalisation sans Google Maps API

## ✅ Solution implémentée

Votre application Flutter utilise maintenant la géolocalisation native avec les packages `geolocator` et `geocoding`, **sans avoir besoin de Google Maps API**.

## 🎯 Ce qui a été fait

### 1. Service de géolocalisation (`lib/services/location_service.dart`)

Création d'un service complet qui permet de :
- ✅ Obtenir la position actuelle de l'utilisateur
- ✅ Calculer les distances entre deux points
- ✅ Obtenir l'adresse à partir de coordonnées (géocodage inversé)
- ✅ Obtenir les coordonnées à partir d'une adresse (géocodage)
- ✅ Gérer les permissions de localisation
- ✅ Suivre la position en temps réel

### 2. Amélioration du MapPlaceholder

Le widget `MapPlaceholder` a été amélioré pour :
- ✅ Afficher automatiquement la position actuelle de l'utilisateur
- ✅ Afficher un marqueur de position
- ✅ Afficher l'adresse correspondante
- ✅ Afficher les coordonnées GPS
- ✅ Permettre de rafraîchir la position

### 3. Mise à jour des écrans

Les écrans `map_screen.dart` et `booking_screen.dart` utilisent maintenant le placeholder avec géolocalisation native au lieu de Google Maps.

## 📦 Packages utilisés

Les packages suivants sont déjà dans votre `pubspec.yaml` :
- `geolocator: ^11.0.0` - Pour la géolocalisation
- `geocoding: ^3.0.0` - Pour le géocodage (adresses ↔ coordonnées)

## 🔧 Permissions requises

### Android (`android/app/src/main/AndroidManifest.xml`)

Assurez-vous d'avoir ces permissions :

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS (`ios/Runner/Info.plist`)

Ajoutez ces clés :

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Cette application a besoin de votre localisation pour trouver des taxis près de vous.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Cette application a besoin de votre localisation pour suivre vos trajets.</string>
```

## 💻 Utilisation

### Obtenir la position actuelle

```dart
import 'package:allo_dakar/services/location_service.dart';

// Obtenir la position
final position = await LocationService.getCurrentPosition();
if (position != null) {
  print('Latitude: ${position.latitude}');
  print('Longitude: ${position.longitude}');
}
```

### Calculer une distance

```dart
final distanceKm = LocationService.calculateDistanceInKm(
  startLatitude,
  startLongitude,
  endLatitude,
  endLongitude,
);
```

### Obtenir l'adresse

```dart
final address = await LocationService.getAddressFromCoordinates(
  latitude,
  longitude,
);
```

### Suivre la position en temps réel

```dart
final positionStream = LocationService.getPositionStream();
positionStream?.listen((Position position) {
  print('Nouvelle position: ${position.latitude}, ${position.longitude}');
});
```

## 🎨 Affichage dans l'interface

Le `MapPlaceholder` affiche maintenant :
- 🎯 Un marqueur de position au centre
- 📍 L'adresse de l'utilisateur
- 📐 Les coordonnées GPS précises
- 🔄 Un bouton pour rafraîchir la position

## ✅ Avantages de cette solution

1. **Pas besoin de clé API** - Fonctionne sans Google Maps API
2. **Gratuit** - Aucun coût associé
3. **Fonctionnel** - Toutes les fonctionnalités de base sont disponibles
4. **Privé** - Les données de localisation restent sur l'appareil
5. **Compatible** - Fonctionne sur Android, iOS et Web

## 🔄 Pour activer Google Maps plus tard

Si vous obtenez une clé Google Maps API plus tard, vous pouvez :
1. Ajouter la clé dans `android/app/src/main/AndroidManifest.xml`
2. Décommenter le code Google Maps dans `map_screen.dart` et `booking_screen.dart`
3. L'application utilisera automatiquement Google Maps si disponible, sinon le placeholder

## 📝 Notes importantes

- La géolocalisation nécessite des permissions utilisateur
- Sur Android 6+, les permissions sont demandées à l'exécution
- Sur iOS, les permissions sont demandées la première fois
- Le service de localisation doit être activé sur l'appareil

## 🆘 Dépannage

### La position n'est pas obtenue

1. Vérifier que les permissions sont accordées dans les paramètres
2. Vérifier que le service de localisation est activé
3. Vérifier que l'appareil a un signal GPS/Internet

### Erreur de permissions

Le service gère automatiquement les demandes de permissions. Si elles sont refusées, l'utilisateur peut les activer depuis les paramètres de l'appareil.

