# Guide de construction de l'APK Android

## Structure Android créée

La structure Android a été générée automatiquement. Vous pouvez maintenant construire l'APK.

## Construire l'APK de production

```powershell
flutter build apk --release
```

## Construire un App Bundle (recommandé pour Google Play)

```powershell
flutter build appbundle --release
```

## Configuration Google Maps (Optionnel)

Pour activer Google Maps sur Android, éditez le fichier `android/app/src/main/AndroidManifest.xml` et ajoutez votre clé API dans la section commentée :

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="VOTRE_CLE_API_ICI"/>
```

## Permissions

Les permissions de localisation ont été ajoutées automatiquement dans le manifeste pour permettre l'utilisation de la géolocalisation.

## Emplacement des fichiers générés

- **APK** : `build/app/outputs/flutter-apk/app-release.apk`
- **App Bundle** : `build/app/outputs/bundle/release/app-release.aab`

## Notes importantes

1. **Première compilation** : La première compilation peut prendre plusieurs minutes car Gradle doit télécharger les dépendances.

2. **Version minimale Android** : L'application est configurée pour Android 5.0 (API 21) et supérieur par défaut.

3. **Signature** : Pour publier sur Google Play, vous devrez créer une clé de signature. Voir la documentation Flutter pour plus de détails.

