# 🚀 Guide de démarrage rapide - Allo Dakar Backend

## Étape 1 : Ouvrir le terminal dans le dossier backend

### Sur Windows (PowerShell) :

1. Ouvrir PowerShell
2. Naviguer vers le dossier :
   ```powershell
   cd C:\allo_dakar_repo\allo-dakar-backend
   ```

### Ou depuis l'explorateur Windows :

1. Ouvrir le dossier `allo-dakar-backend` dans l'explorateur
2. Clic droit dans le dossier → "Ouvrir dans le terminal" ou "Ouvrir PowerShell ici"

---

## Étape 2 : Activer l'environnement virtuel (si déjà créé)

Si vous avez déjà un environnement virtuel :

```powershell
.\venv\Scripts\activate
```

Vous devriez voir `(venv)` au début de votre ligne de commande.

Si vous n'avez pas encore d'environnement virtuel, passez à l'étape 3.

---

## Étape 3 : Créer l'environnement virtuel Python (si nécessaire)

Si l'environnement virtuel n'existe pas encore :

```powershell
python -m venv venv
```

Ensuite, activez-le :

```powershell
.\venv\Scripts\activate
```

---

## Étape 4 : Installer les dépendances

```powershell
pip install -r requirements.txt
```

Cela va installer toutes les bibliothèques nécessaires (Flask, SQLAlchemy, JWT, etc.).

---

## Étape 5 : Initialiser la base de données

```powershell
python init_db.py
```

Cela va créer :
- La base de données SQLite (`allo_dakar.db`)
- Les tables nécessaires
- Les codes promo de test (BIENVENUE10, DAKAR500, WEEKEND20)

---

## Étape 6 : Lancer le serveur

```powershell
python app.py
```

Ou utilisez le script de démarrage :

```powershell
python run.py
```

Vous devriez voir :
```
 * Running on http://0.0.0.0:5000
 * Debug mode: on
```

---

## ✅ Le backend est maintenant accessible en local !

- **URL de base** : `http://localhost:5000`
- **Route de test** : `http://localhost:5000/health`
- **API** : `http://localhost:5000/api/v1`

---

## 📝 Tester que ça fonctionne

Dans un autre terminal, tester :

```powershell
curl http://localhost:5000/health
```

Ou ouvrir dans le navigateur : http://localhost:5000/health

Vous devriez voir :
```json
{
  "status": "ok",
  "message": "Allo Dakar API is running"
}
```

---

## 🔌 Connexion avec le frontend Flutter

Une fois le backend lancé, vous pouvez :

1. Configurer l'URL de l'API dans votre app Flutter
2. L'API sera accessible sur : `http://localhost:5000/api/v1`
3. Pour Android Emulator : utiliser `http://10.0.2.2:5000/api/v1`
4. Pour un appareil physique : utiliser l'IP de votre PC (ex: `http://192.168.1.100:5000/api/v1`)

---

## ⚠️ Important

- Le backend doit rester **toujours lancé** quand vous utilisez l'app Flutter
- Pour arrêter : `Ctrl + C` dans le terminal
- Pour relancer : `python app.py` (après avoir activé le venv)

---

## 🆘 Problèmes courants

### Erreur "Module not found"
→ Vérifier que vous avez bien activé l'environnement virtuel (`venv`)
→ Réinstaller les dépendances : `pip install -r requirements.txt`

### Erreur "Port already in use"
→ Un autre processus utilise le port 5000. Changer le port dans `app.py` ligne 66 ou `run.py` ligne 15

### Erreur de base de données
→ Supprimer `allo_dakar.db` et relancer `python init_db.py`

### Erreur d'import
→ Vérifier que tous les fichiers sont bien copiés (models/, routes/, services/)
→ Vérifier que vous êtes dans le bon dossier (`C:\allo_dakar_repo\allo-dakar-backend`)

---

## 📚 Commandes utiles

### Réactiver l'environnement virtuel
```powershell
.\venv\Scripts\activate
```

### Mettre à jour les dépendances
```powershell
pip install -r requirements.txt --upgrade
```

### Voir les routes disponibles
Une fois le serveur lancé, consulter le code dans `routes/` ou tester avec :
```powershell
curl http://localhost:5000/api/v1/auth/register
```

---

## 📄 Documentation complète

Voir `README.md` pour la documentation complète de l'API avec tous les endpoints disponibles.

