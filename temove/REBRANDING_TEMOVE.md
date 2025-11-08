# 🎨 Rebranding vers TeMove

## ✅ Modifications effectuées

L'application a été rebrandée de "Allo Dakar" vers **TeMove** avec le slogan **"Votre trajet, notre hospitalité"**.

### 1. Fichiers de configuration

#### `pubspec.yaml`
- ✅ Nom du package : `temove`
- ✅ Description : "TeMove - Votre trajet, notre hospitalité"

#### `lib/main.dart`
- ✅ Titre de l'application : "TeMove"

#### `android/app/src/main/AndroidManifest.xml`
- ✅ Label de l'application : "TeMove"

#### `android/app/build.gradle.kts`
- ✅ Namespace : `com.temove.app`
- ✅ Application ID : `com.temove.app`

### 2. Imports Dart

Tous les imports `package:allo_dakar` ont été remplacés par `package:temove` dans :
- ✅ `lib/main.dart`
- ✅ `lib/screens/*.dart` (tous les écrans)
- ✅ `lib/widgets/*.dart` (tous les widgets)

### 3. Interface utilisateur

#### `lib/screens/welcome_screen.dart`
- ✅ Titre : "TÉMOVE"
- ✅ Slogan : "Votre trajet, notre hospitalité"

## 📝 Prochaines étapes

### Pour compléter le rebranding :

1. **Logo et icônes**
   - Remplacer les icônes dans `assets/icons/`
   - Mettre à jour l'icône de l'application dans `android/app/src/main/res/`
   - Mettre à jour l'icône iOS dans `ios/Runner/Assets.xcassets/`

2. **Couleurs du thème** (optionnel)
   - Si vous souhaitez utiliser les couleurs du logo (jaune vif), mettre à jour `lib/theme/app_theme.dart`
   - Le logo montre un fond jaune vif avec du noir et du vert

3. **Nettoyer le build**
   ```bash
   cd C:\allo-dakar\allo-dakar-stitch-cursor
   flutter clean
   flutter pub get
   ```

4. **Reconstruire l'application**
   ```bash
   flutter run
   ```

## ⚠️ Notes importantes

- Le package name a changé de `allo_dakar` à `temove`
- L'application ID Android a changé de `com.example.allo_dakar` à `com.temove.app`
- Si vous avez déjà installé l'ancienne version, vous devrez la désinstaller avant d'installer la nouvelle version (car l'application ID a changé)

## 🎨 Couleurs du logo TeMove

D'après l'image fournie :
- **Fond principal** : Jaune vif (#FFD700 ou similaire)
- **Texte et icône** : Noir
- **Accent** : Vert (ligne courbe au-dessus de la voiture)

Vous pouvez utiliser ces couleurs dans `app_theme.dart` si vous souhaitez aligner l'interface avec le logo.

