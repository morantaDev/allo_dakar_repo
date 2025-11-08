# 🚀 Démarrer le Backend Flask pour TéMove

## 📋 Prérequis

- Python 3.8+ installé
- Environnement virtuel créé et activé
- Dépendances installées (`pip install -r requirements.txt`)

---

## 🎯 Méthode 1 : Utiliser app.py (RECOMMANDÉ)

### Dans PowerShell :

```powershell
# 1. Aller dans le dossier backend
cd C:\allo_dakar_repo\temove-backend

# 2. Activer l'environnement virtuel
.\venv\Scripts\activate

# 3. Lancer le serveur
python app.py
```

Le backend sera accessible sur : `http://127.0.0.1:5000`

---

## 🎯 Méthode 2 : Utiliser run.py

```powershell
# 1. Aller dans le dossier backend
cd C:\allo_dakar_repo\temove-backend

# 2. Activer l'environnement virtuel
.\venv\Scripts\activate

# 3. Lancer avec run.py
python run.py
```

---

## ✅ Vérifier que le backend fonctionne

### 1. Endpoint Health Check

Ouvrez dans votre navigateur : `http://127.0.0.1:5000/health`

Vous devriez voir :
```json
{
  "status": "ok",
  "message": "TeMove API is running"
}
```

### 2. Tester avec curl (PowerShell)

```powershell
# Test de santé
Invoke-WebRequest -Uri "http://127.0.0.1:5000/health" -Method GET

# Test des routes drivers
Invoke-WebRequest -Uri "http://127.0.0.1:5000/api/v1/drivers/me" -Method GET -Headers @{"Authorization"="Bearer YOUR_TOKEN"}
```

---

## 🔧 Configuration

### Port par défaut : 5000

Si le port 5000 est déjà utilisé, modifiez dans `app.py` :
```python
app.run(debug=True, host='0.0.0.0', port=5001)  # Changer le port
```

### Variables d'environnement

Créez un fichier `.env` dans `temove-backend/` :
```env
SECRET_KEY=your-secret-key-here
DATABASE_URL=sqlite:///instance/allo_dakar.db
JWT_SECRET_KEY=your-jwt-secret-key-here
FLASK_ENV=development
```

---

## 🛑 Arrêter le serveur

Appuyez sur `Ctrl + C` dans le terminal où le serveur est en cours d'exécution.

---

## 🆘 Problèmes courants

### Port 5000 déjà utilisé

```powershell
# Trouver le processus qui utilise le port 5000
netstat -ano | findstr :5000

# Tuer le processus (remplacez PID par le numéro du processus)
taskkill /PID <PID> /F
```

### Erreur "Module not found"

```powershell
# Réinstaller les dépendances
pip install -r requirements.txt
```

### Erreur de connexion à la base de données

Vérifiez que le fichier `.env` existe et contient la bonne `DATABASE_URL`.

---

## 📝 Routes disponibles

- **Health Check** : `GET /health`
- **Authentification** : `POST /api/v1/auth/login`
- **Courses disponibles** : `GET /api/v1/drivers/rides`
- **Profil chauffeur** : `GET /api/v1/drivers/me`
- **Définir statut** : `POST /api/v1/drivers/set-status`

---

## 🔗 URLs importantes

- **Backend API** : `http://127.0.0.1:5000/api/v1`
- **Health Check** : `http://127.0.0.1:5000/health`
- **Documentation Swagger** (si disponible) : `http://127.0.0.1:5000/docs`

---

## 📌 Commandes rapides

```powershell
# Démarrer le backend
cd C:\allo_dakar_repo\temove-backend
.\venv\Scripts\activate
python app.py

# Dans un autre terminal, démarrer le frontend
cd C:\allo_dakar_repo\temove-pro
flutter run -d chrome
```

