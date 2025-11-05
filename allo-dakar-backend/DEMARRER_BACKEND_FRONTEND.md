# 🚀 Démarrer Backend + Frontend en même temps

Guide pour démarrer le backend Flask et le frontend Flutter simultanément.

## 📋 Prérequis

- Python 3.8+ avec environnement virtuel configuré
- Flutter SDK installé
- Dart installé

---

## 🎯 Méthode 1 : Deux terminaux séparés (RECOMMANDÉ)

### Terminal 1 : Backend

```powershell
# 1. Aller dans le dossier backend
cd C:\allo_dakar_repo\allo-dakar-backend

# 2. Activer l'environnement virtuel
.\venv\Scripts\activate

# 3. Lancer le serveur backend
python app.py
```

Le backend sera accessible sur : `http://localhost:5000`

### Terminal 2 : Frontend Flutter

```powershell
# 1. Aller dans le dossier frontend
cd C:\allo_dakar_repo\allo-dakar-stitch-cursor

# 2. Installer les dépendances (si nécessaire)
flutter pub get

# 3. Lancer l'application
flutter run
```

Ou pour un appareil spécifique :
```powershell
# Pour Android Emulator
flutter run -d android

# Pour Chrome (web)
flutter run -d chrome

# Pour Windows
flutter run -d windows
```

---

## 🎯 Méthode 2 : Script PowerShell pour démarrer les deux

Créez un fichier `start-all.ps1` à la racine de votre projet :

```powershell
# start-all.ps1 - Démarrer backend et frontend

# Couleurs pour la sortie
$host.ui.RawUI.ForegroundColor = "Green"
Write-Host "🚀 Démarrage de Backend + Frontend" -ForegroundColor Cyan

# Backend
Write-Host "`n📦 Démarrage du Backend..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd C:\allo_dakar_repo\allo-dakar-backend; .\venv\Scripts\activate; python app.py"

# Attendre 3 secondes pour que le backend démarre
Start-Sleep -Seconds 3

# Frontend
Write-Host "📱 Démarrage du Frontend Flutter..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd C:\allo_dakar_repo\allo-dakar-stitch-cursor; flutter run"

Write-Host "`n✅ Backend et Frontend lancés dans des fenêtres séparées!" -ForegroundColor Green
Write-Host "Pour arrêter : Fermez les fenêtres PowerShell ou appuyez sur Ctrl+C" -ForegroundColor Gray
```

**Utilisation :**
```powershell
.\start-all.ps1
```

---

## 🎯 Méthode 3 : Script batch (Windows)

Créez un fichier `start-all.bat` :

```batch
@echo off
echo 🚀 Démarrage de Backend + Frontend

echo 📦 Démarrage du Backend...
start "Backend Flask" cmd /k "cd /d C:\allo_dakar_repo\allo-dakar-backend && .\venv\Scripts\activate && python app.py"

timeout /t 3 /nobreak

echo 📱 Démarrage du Frontend Flutter...
start "Frontend Flutter" cmd /k "cd /d C:\allo_dakar_repo\allo-dakar-stitch-cursor && flutter run"

echo ✅ Backend et Frontend lancés!
pause
```

**Utilisation :** Double-cliquez sur `start-all.bat`

---

## 🔧 Configuration de l'URL API dans Flutter

Assurez-vous que votre application Flutter pointe vers le bon endpoint :

### Pour Android Emulator :
```dart
const String API_BASE_URL = 'http://10.0.2.2:5000/api/v1';
```

### Pour iOS Simulator :
```dart
const String API_BASE_URL = 'http://localhost:5000/api/v1';
```

### Pour appareil physique :
```dart
// Remplacez par l'IP de votre PC (ex: 192.168.1.100)
const String API_BASE_URL = 'http://192.168.1.100:5000/api/v1';
```

### Pour Web :
```dart
const String API_BASE_URL = 'http://localhost:5000/api/v1';
```

---

## 📍 Vérifier que tout fonctionne

### 1. Backend (dans le navigateur) :
http://localhost:5000/health

Devrait afficher :
```json
{
  "status": "ok",
  "message": "Allo Dakar API is running"
}
```

### 2. Frontend :
- L'application Flutter devrait se lancer sur l'émulateur/appareil
- Tester la connexion à l'API depuis l'app

---

## ⚠️ Points importants

1. **Ordre de démarrage** : Toujours démarrer le **backend en premier**
2. **Ports** : 
   - Backend : Port 5000
   - Frontend : Port variable selon la plateforme
3. **Environnement virtuel** : Ne pas oublier d'activer `venv` pour le backend
4. **Flutter doctor** : Vérifier que Flutter est bien configuré :
   ```powershell
   flutter doctor
   ```

---

## 🛑 Arrêter les services

### Pour arrêter :
1. **Backend** : Appuyez sur `Ctrl + C` dans le terminal backend
2. **Frontend** : Appuyez sur `q` dans le terminal Flutter, ou `Ctrl + C`

---

## 🆘 Problèmes courants

### Le frontend ne peut pas se connecter au backend
- Vérifier que le backend est bien lancé sur le port 5000
- Vérifier l'URL de l'API dans le code Flutter
- Pour Android Emulator : utiliser `10.0.2.2` au lieu de `localhost`
- Pour appareil physique : utiliser l'IP de votre PC et vérifier le firewall

### Port 5000 déjà utilisé
- Changer le port dans `app.py` ligne 66 :
  ```python
  app.run(debug=True, host='0.0.0.0', port=5001)  # Changer 5000 en 5001
  ```
- Mettre à jour l'URL dans le frontend

### Erreur "flutter: command not found"
- Vérifier que Flutter est dans le PATH
- Relancer le terminal après installation de Flutter

---

## 📝 Commandes rapides

### Backend uniquement :
```powershell
cd C:\allo_dakar_repo\allo-dakar-backend
.\venv\Scripts\activate
python app.py
```

### Frontend uniquement :
```powershell
cd C:\allo_dakar_repo\allo-dakar-stitch-cursor
flutter run
```

### Les deux en même temps :
Utilisez la méthode 1 (deux terminaux) ou les scripts ci-dessus.




