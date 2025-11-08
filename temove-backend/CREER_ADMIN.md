# 👤 Créer un Utilisateur Administrateur

## ✅ Étape 1 : Vérifier que la colonne is_admin existe

Vous avez déjà ajouté la colonne avec SQL, c'est parfait ! 

## 🚀 Étape 2 : Créer un utilisateur admin

### Méthode 1 : Script Python (Recommandé)

1. **Activer l'environnement virtuel** :
   ```powershell
   .\venv\Scripts\Activate.ps1
   ```

2. **Exécuter le script de création d'admin** :
   ```powershell
   python scripts/create_admin.py
   ```

3. **Suivre les instructions** :
   - Entrer l'email de l'admin (ou appuyer sur Entrée pour utiliser admin@temove.sn)
   - Entrer le mot de passe (ou laisser vide pour générer un mot de passe sécurisé)
   - Entrer le nom complet (ou appuyer sur Entrée pour "Administrateur")

### Méthode 2 : SQL Direct

Si vous préférez créer l'admin directement en SQL :

```sql
-- Remplacez les valeurs suivantes :
-- email: votre email admin
-- password_hash: hash du mot de passe (généré avec Flask-Bcrypt)
-- full_name: nom de l'administrateur

INSERT INTO users (email, password_hash, full_name, name, is_admin, is_active, is_verified, role, credit_balance, created_at, updated_at)
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

### Méthode 3 : Mettre à jour un utilisateur existant

Si vous avez déjà un utilisateur et voulez le rendre admin :

```sql
UPDATE users 
SET is_admin = TRUE, is_active = TRUE, is_verified = TRUE
WHERE email = 'votre_email@exemple.com';
```

---

## 🧪 Étape 3 : Vérifier que l'admin fonctionne

### Test 1 : Se connecter avec l'API

```bash
POST http://localhost:5000/api/v1/auth/login
Content-Type: application/json

{
  "email": "admin@temove.sn",
  "password": "votre_mot_de_passe"
}
```

Vous devriez recevoir un token JWT.

### Test 2 : Accéder au dashboard admin

```bash
GET http://localhost:5000/api/v1/admin/dashboard/stats
Authorization: Bearer <votre_token_jwt>
```

Vous devriez recevoir les statistiques du dashboard.

---

## 📋 Checklist

- [x] Colonne `is_admin` ajoutée à la table `users`
- [ ] Utilisateur admin créé
- [ ] Connexion testée avec l'API
- [ ] Accès au dashboard admin testé

---

## 🔐 Sécurité

⚠️ **Important** :
- Changez le mot de passe par défaut immédiatement
- Utilisez un mot de passe fort (minimum 12 caractères)
- Ne partagez jamais les identifiants admin
- Utilisez HTTPS en production

---

## 🐛 Dépannage

### Erreur : "ModuleNotFoundError: No module named 'flask'"

**Solution** : Activez d'abord l'environnement virtuel :
```powershell
.\venv\Scripts\Activate.ps1
```

### Erreur : "Accès non autorisé" lors de l'accès aux routes admin

**Vérifications** :
1. L'utilisateur a bien `is_admin = TRUE` dans la base de données
2. Le token JWT est valide et non expiré
3. Le token est bien envoyé dans le header `Authorization: Bearer <token>`

### Vérifier qu'un utilisateur est admin

```sql
SELECT id, email, is_admin, is_active FROM users WHERE email = 'votre_email@exemple.com';
```

---

## 📞 Prochaines Étapes

Une fois l'admin créé :
1. ✅ Tester l'accès au dashboard admin
2. ✅ Explorer les endpoints admin disponibles
3. ✅ Créer le dashboard frontend (optionnel)
4. ✅ Configurer les permissions et rôles

---

**Date de création** : 2024

