# 🔄 Migration vers MySQL

## ✅ Configuration effectuée

### 1. **Configuration MySQL dans `config.py`**
- URL MySQL par défaut : `mysql+pymysql://root:1234@localhost:3306/temove_db`
- La base de données `temove_db` sera utilisée automatiquement

### 2. **Création automatique des tables**
- Les tables sont créées automatiquement au démarrage du serveur
- Ajouté dans `app.py` : `db.create_all()` au démarrage
- Toutes les tables, relations et contraintes sont créées automatiquement

### 3. **Driver MySQL installé**
- `pymysql` : Driver MySQL pour Python
- `cryptography` : Dépendance pour pymysql

## 📋 Tables créées automatiquement

Au démarrage du serveur, toutes ces tables seront créées :

1. **users** - Utilisateurs
2. **drivers** - Chauffeurs
3. **rides** - Courses
4. **payments** - Paiements
5. **credit_transactions** - Transactions de crédit
6. **promo_codes** - Codes promo
7. **referral_codes** - Codes de parrainage
8. **referral_rewards** - Récompenses de parrainage
9. **loyalty_points** - Points de fidélité
10. **user_badges** - Badges utilisateurs
11. **ratings** - Évaluations
12. **landmarks** - Points d'intérêt

Toutes les relations (clés étrangères) sont également créées automatiquement.

## 🚀 Démarrage

```powershell
.\venv\Scripts\activate
python app.py
```

**Au démarrage, vous verrez :**
```
✅ Toutes les tables ont été créées/vérifiées dans MySQL
```

## ⚙️ Configuration personnalisée

Si vous voulez changer les paramètres MySQL, modifiez le fichier `.env` :

```env
DATABASE_URL=mysql+pymysql://root:1234@localhost:3306/temove_db
```

Ou modifiez directement dans `config.py` la variable `_default_mysql_url`.

## ✅ Vérification

1. **Démarrer le serveur** : `python app.py`
2. **Vérifier les logs** : Vous devriez voir "✅ Toutes les tables ont été créées/vérifiées"
3. **Vérifier dans MySQL** :
   ```sql
   USE temove_db;
   SHOW TABLES;
   ```

## 🔧 Dépannage

### Erreur de connexion MySQL
- Vérifier que MySQL est démarré
- Vérifier les identifiants (user: root, password: 1234)
- Vérifier que la base `temove_db` existe

### Erreur "Module not found: pymysql"
```powershell
pip install pymysql cryptography
```

### Les tables ne sont pas créées
- Vérifier les logs du serveur
- Vérifier que MySQL est accessible
- Vérifier les permissions de l'utilisateur MySQL

## 📝 Note importante

Les tables sont créées **automatiquement** à chaque démarrage si elles n'existent pas. Si elles existent déjà, elles ne seront pas recréées (pas de perte de données).

