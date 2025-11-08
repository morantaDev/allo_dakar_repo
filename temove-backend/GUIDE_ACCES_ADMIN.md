# 🚀 Guide d'Accès au Tableau de Bord Admin - TéMove

## 📋 Prérequis

1. Backend Flask en cours d'exécution (`http://127.0.0.1:5000`)
2. Base de données MySQL configurée
3. Application Flutter TéMove compilée et exécutée

---

## 🔐 Étape 1 : Créer un Utilisateur Administrateur

### Option A : Script Python (Recommandé)

1. **Activer l'environnement virtuel** :
   ```powershell
   cd temove-backend
   .\venv\Scripts\Activate.ps1
   ```

2. **Exécuter le script de création d'admin** :
   ```powershell
   python scripts/create_admin.py
   ```

3. **Suivre les instructions** :
   - Entrer l'email admin (ex: `admin@temove.sn`)
   - Entrer le mot de passe
   - Entrer le nom complet (ex: `Administrateur`)

### Option B : SQL Direct

```sql
-- Se connecter à MySQL
mysql -u root -p

-- Utiliser la base de données
USE temove_db;

-- Vérifier si l'utilisateur existe
SELECT id, email, full_name, is_admin FROM users WHERE email = 'admin@temove.sn';

-- Si l'utilisateur existe, le rendre admin
UPDATE users 
SET is_admin = TRUE, is_active = TRUE, is_verified = TRUE
WHERE email = 'admin@temove.sn';

-- Si l'utilisateur n'existe pas, le créer
INSERT INTO users (
    email, 
    password_hash, 
    full_name, 
    name, 
    is_admin, 
    is_active, 
    is_verified, 
    role, 
    credit_balance, 
    created_at, 
    updated_at
)
VALUES (
    'admin@temove.sn',
    '$2b$12$VOTRE_HASH_BCRYPT_ICI',  -- Générer avec Python (voir ci-dessous)
    'Administrateur',
    'Administrateur',
    TRUE,
    TRUE,
    TRUE,
    'client',
    0,
    NOW(),
    NOW()
);
```

**Générer le hash du mot de passe avec Python** :
```python
from flask_bcrypt import generate_password_hash
password = "votre_mot_de_passe"
hashed = generate_password_hash(password).decode('utf-8')
print(hashed)
```

### Option C : Via l'API (si vous avez déjà un compte)

```bash
# 1. Se connecter avec votre compte existant
POST http://127.0.0.1:5000/api/v1/auth/login
{
  "email": "votre_email@exemple.com",
  "password": "votre_mot_de_passe"
}

# 2. Mettre à jour le compte pour le rendre admin (nécessite un accès direct à la DB)
# Utiliser l'Option B ci-dessus
```

---

## 🔑 Étape 2 : Se Connecter en Tant qu'Admin

### Option A : Via l'Application Flutter

1. **Lancer l'application Flutter** :
   ```powershell
   cd temove
   flutter run -d chrome
   ```

2. **Se connecter avec les identifiants admin** :
   - Email : `admin@temove.sn`
   - Mot de passe : votre mot de passe admin

3. **Accéder au dashboard admin** :
   - **Méthode 1** : Vérifier si l'écran de connexion détecte automatiquement le rôle admin et redirige vers le dashboard
   - **Méthode 2** : Ajouter un bouton "Admin" dans le menu de navigation
   - **Méthode 3** : Accéder directement à l'URL `/admin` (si configuré dans le routage)

### Option B : Via l'API REST (Test)

1. **Se connecter et obtenir le token JWT** :
   ```bash
   curl -X POST http://127.0.0.1:5000/api/v1/auth/login \
     -H "Content-Type: application/json" \
     -d '{
       "email": "admin@temove.sn",
       "password": "votre_mot_de_passe"
     }'
   ```

   **Réponse** :
   ```json
   {
     "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
     "user": {
       "id": 1,
       "email": "admin@temove.sn",
       "full_name": "Administrateur",
       "is_admin": true
     }
   }
   ```

2. **Utiliser le token pour accéder aux endpoints admin** :
   ```bash
   curl -X GET http://127.0.0.1:5000/api/v1/admin/dashboard/stats \
     -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc..."
   ```

---

## 🎨 Étape 3 : Accéder à l'Interface Admin Flutter

### Vérifier le Routage

Vérifiez que le routage admin est configuré dans `lib/main.dart` :

```dart
// Dans main.dart, ajouter une route pour l'admin
GoRoute(
  path: '/admin',
  builder: (context, state) => const AdminHomeScreen(),
),
```

### Détecter le Rôle Admin dans l'Écran de Connexion

Modifiez `lib/screens/auth_screen.dart` pour rediriger automatiquement les admins :

```dart
// Après une connexion réussie
if (userData['is_admin'] == true) {
  // Rediriger vers le dashboard admin
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
  );
} else {
  // Rediriger vers l'écran principal
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const WelcomeScreen()),
  );
}
```

### Ajouter un Bouton Admin dans le Menu

Dans `lib/widgets/app_drawer.dart`, ajouter un bouton conditionnel :

```dart
// Vérifier si l'utilisateur est admin
final isAdmin = await _checkIfAdmin();

if (isAdmin) {
  ListTile(
    leading: const Icon(Icons.admin_panel_settings),
    title: const Text('Administration'),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
      );
    },
  ),
}
```

---

## 🧪 Étape 4 : Tester les Endpoints Admin

### Test avec cURL

```bash
# 1. Obtenir le token
TOKEN=$(curl -X POST http://127.0.0.1:5000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@temove.sn", "password": "votre_mot_de_passe"}' \
  | jq -r '.access_token')

# 2. Tester le dashboard stats
curl -X GET http://127.0.0.1:5000/api/v1/admin/dashboard/stats \
  -H "Authorization: Bearer $TOKEN"

# 3. Tester la liste des utilisateurs
curl -X GET http://127.0.0.1:5000/api/v1/admin/users \
  -H "Authorization: Bearer $TOKEN"

# 4. Tester la liste des conducteurs
curl -X GET http://127.0.0.1:5000/api/v1/admin/drivers \
  -H "Authorization: Bearer $TOKEN"
```

### Test avec Postman

1. **Créer une nouvelle requête POST** :
   - URL : `http://127.0.0.1:5000/api/v1/auth/login`
   - Body (JSON) :
     ```json
     {
       "email": "admin@temove.sn",
       "password": "votre_mot_de_passe"
     }
     ```
   - Copier le `access_token` de la réponse

2. **Créer une nouvelle requête GET** :
   - URL : `http://127.0.0.1:5000/api/v1/admin/dashboard/stats`
   - Headers :
     - `Authorization`: `Bearer <votre_token>`
     - `Content-Type`: `application/json`

---

## 📱 Étape 5 : Interface Flutter Admin

### Structure Actuelle

- ✅ `lib/screens/admin_home_screen.dart` - Écran d'accueil admin
- ✅ `lib/screens/admin_screen.dart` - Dashboard principal
- ✅ `lib/widgets/admin_drawer.dart` - Menu de navigation admin
- ✅ `lib/widgets/admin_stat_card.dart` - Cartes statistiques
- ✅ `lib/widgets/admin_chart_card.dart` - Graphiques

### Accès Direct via URL (Web)

Si vous utilisez Flutter Web, vous pouvez accéder directement à :
- `http://localhost:port/#/admin`

### Navigation Programmée

```dart
// Dans n'importe quel écran
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AdminHomeScreen(),
  ),
);
```

---

## 🔒 Vérification de l'Accès Admin

### Vérifier si un Utilisateur est Admin

```python
# Dans le backend (Python)
user = User.query.filter_by(email='admin@temove.sn').first()
if user and user.is_admin:
    print("Utilisateur est admin")
```

```dart
// Dans Flutter
final userData = await ApiService.getCurrentUser();
if (userData['is_admin'] == true) {
  // Afficher le bouton/admin
}
```

### Tester l'Endpoint de Vérification

```bash
# Obtenir les informations de l'utilisateur connecté
curl -X GET http://127.0.0.1:5000/api/v1/auth/me \
  -H "Authorization: Bearer $TOKEN"
```

---

## 🐛 Dépannage

### Problème : "Accès non autorisé" (403)

**Causes possibles** :
1. L'utilisateur n'a pas `is_admin = TRUE` dans la base de données
2. Le token JWT est invalide ou expiré
3. Le token n'est pas envoyé dans les headers

**Solution** :
```sql
-- Vérifier le statut admin
SELECT id, email, is_admin, is_active FROM users WHERE email = 'admin@temove.sn';

-- Si is_admin = FALSE, le mettre à TRUE
UPDATE users SET is_admin = TRUE WHERE email = 'admin@temove.sn';
```

### Problème : Le dashboard n'affiche pas de données

**Causes possibles** :
1. La base de données est vide (pas d'utilisateurs, courses, etc.)
2. Les endpoints retournent des erreurs

**Solution** :
```bash
# Vérifier les logs du backend
# Vérifier que les tables existent
# Tester les endpoints directement avec cURL/Postman
```

### Problème : Impossible de se connecter

**Causes possibles** :
1. Le mot de passe est incorrect
2. L'utilisateur n'existe pas
3. Le backend n'est pas en cours d'exécution

**Solution** :
```bash
# Vérifier que le backend est en cours d'exécution
curl http://127.0.0.1:5000/health

# Réinitialiser le mot de passe
python scripts/create_admin.py
```

---

## ✅ Checklist d'Accès

- [ ] Utilisateur admin créé dans la base de données
- [ ] Backend Flask en cours d'exécution
- [ ] Token JWT obtenu avec succès
- [ ] Endpoint `/admin/dashboard/stats` accessible
- [ ] Interface Flutter admin accessible
- [ ] Navigation configurée dans `main.dart`
- [ ] Détection du rôle admin dans l'écran de connexion

---

## 📞 Support

Si vous rencontrez des problèmes :

1. **Vérifier les logs du backend** :
   ```bash
   # Dans le terminal où le backend est lancé
   # Vérifier les erreurs Python
   ```

2. **Vérifier les logs Flutter** :
   ```bash
   # Dans la console du navigateur (F12)
   # Vérifier les erreurs de requêtes API
   ```

3. **Tester les endpoints directement** :
   ```bash
   # Utiliser cURL ou Postman
   # Vérifier que les réponses sont correctes
   ```

---

## 🎯 Résumé Rapide

1. **Créer un admin** : `python scripts/create_admin.py`
2. **Se connecter** : Utiliser l'email et mot de passe admin
3. **Accéder au dashboard** : Navigation vers `/admin` ou bouton admin
4. **Tester** : Vérifier les endpoints avec cURL/Postman

---

**Document créé le** : 2025-11-08  
**Dernière mise à jour** : 2025-11-08

