# Configuration du projet Allo Dakar

## Après l'installation de Flutter

### 1. Installer les dépendances

```powershell
flutter pub get
```

### 2. Configurer Google Maps (Optionnel pour le moment)

Pour utiliser Google Maps dans l'application, vous devez :

1. Créer un projet sur [Google Cloud Console](https://console.cloud.google.com/)
2. Activer l'API **Maps SDK for Android** et **Maps SDK for iOS**
3. Créer une clé API

#### Pour Android (`android/app/src/main/AndroidManifest.xml`) :

```xml
<manifest>
    <application>
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="VOTRE_CLE_API_ICI"/>
    </application>
</manifest>
```

#### Pour iOS (`ios/Runner/AppDelegate.swift`) :

```swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("VOTRE_CLE_API_ICI")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### 3. Tester l'application

#### Sur un émulateur Android :
```powershell
flutter run
```

#### Sur un appareil physique :
1. Activez le mode développeur sur votre téléphone
2. Connectez-le via USB
3. Autorisez le débogage USB
4. Exécutez : `flutter run`

#### Créer un émulateur Android :
1. Ouvrez Android Studio
2. Allez dans **Tools** > **Device Manager**
3. Cliquez sur **Create Device**
4. Sélectionnez un appareil et une image système
5. Cliquez sur **Finish**

## Structure du projet

```
allo-dakar-stitch-cursor/
├── lib/
│   ├── main.dart              # Point d'entrée
│   ├── theme/
│   │   └── app_theme.dart     # Configuration du thème
│   └── screens/
│       ├── welcome_screen.dart
│       ├── auth_screen.dart
│       ├── map_screen.dart
│       ├── booking_screen.dart
│       ├── ride_tracking_screen.dart
│       └── history_screen.dart
├── assets/
│   ├── images/                # Images de l'application
│   └── icons/                  # Icônes
├── pubspec.yaml               # Dépendances
└── README.md
```

## Commandes utiles

```powershell
# Vérifier l'état de Flutter
flutter doctor

# Nettoyer le projet
flutter clean

# Obtenir les dépendances
flutter pub get

# Lancer l'application
flutter run

# Créer un APK de production
flutter build apk --release

# Créer un bundle Android
flutter build appbundle --release
```

## Notes importantes

- **Google Maps** : L'application fonctionnera sans clé API, mais les cartes ne s'afficheront pas. Vous pouvez développer les autres fonctionnalités en attendant.

- **Localisation** : Pour tester la géolocalisation sur Android, ajoutez ces permissions dans `android/app/src/main/AndroidManifest.xml` :

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

