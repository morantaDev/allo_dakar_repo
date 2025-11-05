# 🔍 Vérification de l'Inscription Frontend

## ✅ Ce qui devrait se passer

Quand vous vous inscrivez depuis le frontend Flutter :

1. **Requête POST** vers : `http://localhost:5000/api/v1/auth/register`
2. **Données envoyées** : `{ email, password, full_name, phone }`
3. **Réponse attendue** : Code 201 avec `{ message, user, access_token, refresh_token }`

## 🔍 Comment vérifier

### 1. Vérifier dans les logs du serveur

Dans le terminal où le serveur Flask tourne, vous devriez voir :

```
INFO sqlalchemy.engine.Engine INSERT INTO users (...)
INFO sqlalchemy.engine.Engine COMMIT
127.0.0.1 - - [DATE] "POST /api/v1/auth/register HTTP/1.1" 201 -
```

### 2. Vérifier dans Chrome DevTools

1. Ouvrez Chrome DevTools (F12) dans la fenêtre Flutter
2. Onglet **Network**
3. Cherchez la requête `register`
4. Vérifiez :
   - **Status** : Devrait être `201 Created`
   - **Response** : Devrait contenir `access_token` et `user`

### 3. Vérifier dans MySQL

Exécutez :
```powershell
python scripts/view_mysql_users.py
```

Ou directement dans MySQL :
```sql
USE temove_db;
SELECT * FROM users;
```

## ❌ Si l'inscription ne fonctionne pas

### Problèmes possibles

1. **Erreur CORS**
   - Vérifier que le backend accepte les requêtes depuis `localhost`
   - Vérifier dans Chrome DevTools > Console

2. **URL incorrecte**
   - Frontend doit utiliser : `http://localhost:5000/api/v1/auth/register`
   - Pas : `http://localhost:5000/api/auth/register`

3. **Format des données**
   - Le frontend doit envoyer : `{ email, password, full_name }`
   - Vérifier dans Network > Payload

4. **Erreur de validation**
   - Vérifier les messages d'erreur dans la réponse
   - Vérifier dans Chrome DevTools > Network > Response

## 🧪 Test rapide

Pour tester si l'inscription fonctionne :

```powershell
$body = @{
    email = "test_frontend@example.com"
    password = "test123"
    full_name = "Test Frontend"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5000/api/v1/auth/register" `
    -Method Post `
    -Body $body `
    -ContentType "application/json"
```

Si ça fonctionne, vous devriez voir l'utilisateur dans MySQL.

