# Note sur l'affichage de la carte

## Pourquoi la carte ne s'affiche pas ?

L'application utilise actuellement un **placeholder de carte** (carte de secours) au lieu de Google Maps pour plusieurs raisons :

### Sur le Web
- Google Maps Flutter n'est pas encore pleinement supporté sur le web
- L'application détecte automatiquement si elle tourne sur le web et utilise le placeholder

### Sans clé API Google Maps
- Google Maps nécessite une clé API configurée
- Sans clé API, l'application utilise automatiquement le placeholder pour éviter les erreurs

## Comment activer Google Maps ?

### 1. Obtenir une clé API Google Maps

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Créez un nouveau projet ou sélectionnez un projet existant
3. Activez les APIs suivantes :
   - Maps SDK for Android
   - Maps SDK for iOS
   - Maps JavaScript API (pour le web)

4. Créez une clé API :
   - Allez dans "Identifiants" > "Créer des identifiants" > "Clé API"
   - Copiez la clé API générée

### 2. Configuration Android

Ajoutez dans `android/app/src/main/AndroidManifest.xml` :

```xml
<application>
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="VOTRE_CLE_API_ICI"/>
</application>
```

### 3. Configuration iOS

Ajoutez dans `ios/Runner/AppDelegate.swift` :

```swift
import GoogleMaps

func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    GMSServices.provideAPIKey("VOTRE_CLE_API_ICI")
    return true
}
```

### 4. Configuration Web

Ajoutez dans `web/index.html` :

```html
<script src="https://maps.googleapis.com/maps/api/js?key=VOTRE_CLE_API_ICI"></script>
```

## Le placeholder actuel

En attendant la configuration de Google Maps, vous verrez :
- Un fond sombre avec un motif de grille (simulant des routes)
- Une icône de carte
- Le texte "Carte de Dakar"
- Un message indiquant de configurer Google Maps

**C'est normal et l'application fonctionne parfaitement avec ce placeholder !**

