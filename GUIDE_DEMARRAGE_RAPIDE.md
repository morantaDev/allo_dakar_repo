# Guide de Démarrage Rapide - TeMove

## 🚀 Démarrage du Projet

### Prérequis

- Python 3.8+
- Flutter SDK 3.0+
- MySQL ou SQLite
- Node.js (optionnel, pour le développement)

### 1. Configuration du Backend (Flask)

```bash
# Aller dans le dossier backend
cd temove-backend

# Créer un environnement virtuel
python -m venv venv

# Activer l'environnement virtuel
# Sur Windows:
venv\Scripts\activate
# Sur Linux/Mac:
source venv/bin/activate

# Installer les dépendances
pip install -r requirements.txt

# Configurer les variables d'environnement
# Créer un fichier .env avec:
DATABASE_URL=sqlite:///instance/allo_dakar.db
# ou pour MySQL:
DATABASE_URL=mysql+pymysql://user:password@localhost:3306/temove_db
JWT_SECRET_KEY=your-secret-key-here
SECRET_KEY=your-secret-key-here

# Initialiser la base de données
python init_db.py

# Démarrer le serveur
python app.py
```

Le backend sera accessible sur `http://localhost:5000`

### 2. Configuration de l'Application Client (Flutter)

```bash
# Aller dans le dossier client
cd temove

# Installer les dépendances
flutter pub get

# Démarrer l'application
flutter run
```

### 3. Configuration de l'Application Chauffeur (Flutter)

```bash
# Aller dans le dossier chauffeur
cd temove-pro

# Installer les dépendances
flutter pub get

# Démarrer l'application
flutter run
```

## 📋 Configuration CORS

### Développement

Par défaut, le backend autorise toutes les origines (`*`) en développement.

### Production

Configurer les origines autorisées dans le fichier `.env` :

```bash
CORS_ORIGINS=https://app.temove.com,https://pro.temove.com
```

## 🔑 Authentification

### Créer un utilisateur admin

```python
# Dans le terminal Python
python
>>> from app import create_app
>>> from extensions import db
>>> from models.user import User
>>> app = create_app()
>>> with app.app_context():
...     admin = User(email='admin@temove.com', full_name='Admin', role='admin')
...     admin.set_password('admin123')
...     admin.is_admin = True
...     db.session.add(admin)
...     db.session.commit()
```

### Se connecter

**Endpoint :** `POST /api/v1/auth/login`

```json
{
  "email": "admin@temove.com",
  "password": "admin123"
}
```

## 📊 Dashboard Admin

Accéder au dashboard admin depuis l'application client :

1. Se connecter avec un compte admin
2. Le dashboard s'affichera automatiquement
3. Voir les statistiques globales :
   - Revenus du mois
   - Courses du jour
   - Utilisateurs actifs
   - Conducteurs actifs

## 🧪 Tester les API

### Avec curl

```bash
# Test de santé
curl http://localhost:5000/health

# Test de connexion
curl -X POST http://localhost:5000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

### Avec Postman

1. Importer la collection d'API (à créer)
2. Configurer l'URL de base : `http://localhost:5000/api/v1`
3. Tester les endpoints

## 📚 Documentation

- [Documentation CORS](temove-backend/DOCUMENTATION_CORS.md)
- [Exemples de Requêtes API](temove-backend/EXEMPLE_REQUETE_API.md)
- [Résumé des Améliorations](RESUME_AMELIORATIONS_COMPLET.md)

## 🔧 Dépannage

### Erreur CORS

Si vous rencontrez des erreurs CORS :

1. Vérifier que le backend est démarré sur le port 5000
2. Vérifier la configuration CORS dans `app.py`
3. Vérifier que l'origine de la requête est autorisée
4. Consulter les logs du serveur pour plus de détails

### Erreur de connexion à la base de données

1. Vérifier que MySQL/SQLite est démarré
2. Vérifier les credentials dans `.env`
3. Vérifier que la base de données existe

### Erreur JWT

1. Vérifier que `JWT_SECRET_KEY` est défini dans `.env`
2. Vérifier que le token est correctement envoyé dans l'en-tête `Authorization`
3. Vérifier que le token n'est pas expiré

## 📞 Support

Pour toute question ou problème, consultez :
- Les logs du serveur Flask
- La documentation dans le dossier `temove-backend/`
- Les commentaires dans le code

## ✅ Checklist de Vérification

- [ ] Backend Flask démarré et accessible
- [ ] Base de données initialisée
- [ ] Application Flutter Client fonctionnelle
- [ ] Application Flutter Pro fonctionnelle
- [ ] Configuration CORS correcte
- [ ] Authentification fonctionnelle
- [ ] Dashboard admin accessible

---

**Bon développement ! 🚀**

