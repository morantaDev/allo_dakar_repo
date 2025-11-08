# ⚡ Guide Rapide d'Accès au Dashboard Admin

## 🚀 Méthode Rapide (3 étapes)

### Étape 1 : Créer un Utilisateur Admin

```powershell
# Dans temove-backend
cd temove-backend
.\venv\Scripts\Activate.ps1
python scripts/create_admin.py
```

**Suivre les instructions** :
- Email : `admin@temove.sn` (ou appuyer sur Entrée pour le défaut)
- Mot de passe : Entrer votre mot de passe (ou laisser vide pour générer un mot de passe sécurisé)
- Nom : `Administrateur` (ou appuyer sur Entrée pour le défaut)

### Étape 2 : Lancer le Backend

```powershell
# Dans temove-backend
python app.py
```

Le backend doit être accessible sur `http://127.0.0.1:5000`

### Étape 3 : Se Connecter dans l'Application Flutter

1. **Lancer l'application Flutter** :
   ```powershell
   cd temove
   flutter run -d chrome
   ```

2. **Se connecter avec les identifiants admin** :
   - Email : `admin@temove.sn`
   - Mot de passe : Le mot de passe que vous avez défini

3. **Accès automatique** :
   - L'application détecte automatiquement que vous êtes admin
   - Vous êtes redirigé vers le dashboard admin (`AdminScreen`)

---

## ✅ Vérification

### Vérifier que l'admin est créé

```sql
-- Se connecter à MySQL
mysql -u root -p

-- Utiliser la base de données
USE temove_db;

-- Vérifier l'admin
SELECT id, email, full_name, is_admin, is_active FROM users WHERE email = 'admin@temove.sn';
```

**Résultat attendu** :
```
+----+------------------+---------------+----------+-----------+
| id | email            | full_name     | is_admin | is_active |
+----+------------------+---------------+----------+-----------+
|  1 | admin@temove.sn  | Administrateur|        1 |         1 |
+----+------------------+---------------+----------+-----------+
```

### Tester l'API Admin

```bash
# 1. Obtenir le token
curl -X POST http://127.0.0.1:5000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@temove.sn", "password": "votre_mot_de_passe"}'

# 2. Utiliser le token pour accéder au dashboard
curl -X GET http://127.0.0.1:5000/api/v1/admin/dashboard/stats \
  -H "Authorization: Bearer <votre_token>"
```

---

## 🎯 Accès Direct via URL (Flutter Web)

Si vous utilisez Flutter Web, vous pouvez accéder directement au dashboard admin en modifiant l'URL :

```
http://localhost:port/#/admin
```

Mais cela nécessite de configurer le routage dans `main.dart`.

---

## 🔧 Dépannage Rapide

### Problème : "Accès non autorisé" (403)

**Solution** :
```sql
UPDATE users SET is_admin = TRUE, is_active = TRUE WHERE email = 'admin@temove.sn';
```

### Problème : Le dashboard ne s'affiche pas

**Vérifications** :
1. ✅ Backend en cours d'exécution
2. ✅ Utilisateur connecté avec `is_admin = TRUE`
3. ✅ Token JWT valide
4. ✅ Endpoint `/admin/dashboard/stats` accessible

### Problème : Erreur de connexion

**Solution** :
```powershell
# Réinitialiser le mot de passe admin
python scripts/create_admin.py
```

---

## 📱 Interface Admin Flutter

Une fois connecté en tant qu'admin, vous verrez :

1. **Dashboard principal** avec :
   - Statistiques globales (revenus, courses, utilisateurs, conducteurs)
   - Graphiques des 7 derniers jours
   - Détails des trajets, utilisateurs, conducteurs, revenus

2. **Menu latéral** (`AdminDrawer`) avec :
   - Dashboard
   - Gestion des utilisateurs
   - Gestion des conducteurs
   - Gestion des courses
   - Gestion des paiements
   - Paramètres

---

## 🎉 C'est Prêt !

Une fois ces 3 étapes terminées, vous pouvez :
- ✅ Voir les statistiques du dashboard
- ✅ Gérer les utilisateurs
- ✅ Gérer les conducteurs
- ✅ Voir les courses et paiements
- ✅ Accéder à toutes les fonctionnalités admin

---

**Besoin d'aide ?** Consultez le guide complet : `GUIDE_ACCES_ADMIN.md`

