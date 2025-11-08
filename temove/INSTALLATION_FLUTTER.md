# Guide d'installation de Flutter pour Windows

## Étapes d'installation

### 1. Télécharger Flutter SDK

1. Allez sur https://docs.flutter.dev/get-started/install/windows
2. Téléchargez le SDK Flutter pour Windows
3. Vous pouvez aussi télécharger directement depuis : https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.0-stable.zip (version actuelle)

### 2. Extraire Flutter

1. Extrayez le fichier ZIP dans un dossier (par exemple `C:\src\flutter`)
2. **IMPORTANT** : Ne pas extraire dans un dossier nécessitant des privilèges administrateur comme `C:\Program Files\`

### 3. Ajouter Flutter au PATH

1. Ouvrez le **Panneau de configuration** > **Système** > **Paramètres système avancés**
2. Cliquez sur **Variables d'environnement**
3. Sous **Variables système**, trouvez **Path** et cliquez sur **Modifier**
4. Cliquez sur **Nouveau** et ajoutez le chemin vers Flutter :
   - Exemple : `C:\src\flutter\bin`
5. Cliquez sur **OK** pour sauvegarder

### 4. Vérifier l'installation

Ouvrez un nouveau terminal PowerShell et exécutez :
```powershell
flutter doctor
```

Cette commande vérifie votre installation et vous indique ce qui manque.

### 5. Prérequis supplémentaires

Flutter vous guidera, mais vous aurez probablement besoin de :

- **Git** : Téléchargez depuis https://git-scm.com/download/win
- **Android Studio** (pour développer pour Android) : https://developer.android.com/studio
  - Lors de l'installation, cochez **Android SDK**, **Android SDK Platform**, et **Android Virtual Device**
- **Visual Studio** (pour développer pour Windows desktop) : https://visualstudio.microsoft.com/downloads/
  - Installez le workload "Développement Desktop en C++"

### 6. Configurer Android Studio (pour Android)

1. Ouvrez Android Studio
2. Allez dans **File** > **Settings** > **Plugins**
3. Installez le plugin **Flutter** (qui installera aussi Dart automatiquement)
4. Redémarrez Android Studio

### 7. Accepter les licences Android

Exécutez dans PowerShell :
```powershell
flutter doctor --android-licenses
```

Acceptez toutes les licences en tapant `y` pour chaque licence.

## Installation rapide avec PowerShell (méthode alternative)

Si vous préférez une installation automatisée, vous pouvez utiliser Chocolatey :

1. Installez Chocolatey si vous ne l'avez pas : https://chocolatey.org/install
2. Dans PowerShell (en tant qu'administrateur) :
```powershell
choco install flutter
```

## Vérification finale

Après installation, ouvrez un **nouveau terminal** et exécutez :

```powershell
flutter --version
flutter doctor -v
```

## Prochaines étapes pour Allo Dakar

Une fois Flutter installé :

1. Dans le dossier du projet, exécutez :
```powershell
flutter pub get
```

2. Vérifiez que tout fonctionne :
```powershell
flutter doctor
```

3. Lancez l'application :
```powershell
flutter run
```

## Aide supplémentaire

- Documentation Flutter : https://docs.flutter.dev/
- Communauté Flutter : https://flutter.dev/community

