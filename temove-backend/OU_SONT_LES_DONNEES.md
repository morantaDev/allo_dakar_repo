# 📍 Où sont les données ?

## Situation actuelle

D'après les logs du serveur, l'inscription a réussi (code HTTP 201), mais les données ne sont pas dans la base de données que nous avons consultée.

## Emplacements possibles de la base de données

### 1. Base de données actuelle (selon .env)
- **Chemin dans .env** : `DATABASE_URL=sqlite:///allo_dakar.db`
- **Emplacement** : À la racine du projet (`C:\allo_dakar_repo\allo-dakar-backend\allo_dakar.db`)
- **Statut** : ❌ Non trouvée

### 2. Base de données par défaut (selon config.py)
- **Chemin** : `instance/allo_dakar.db`
- **Emplacement** : `C:\allo_dakar_repo\allo-dakar-backend\instance\allo_dakar.db`
- **Statut** : ✅ Existe mais vide

## 🔍 Pour trouver où sont réellement les données

### Option 1 : Vérifier pendant que le serveur tourne

Quand le serveur est lancé, regardez dans les logs SQLAlchemy :
```
2025-11-03 23:56:17,625 INFO sqlalchemy.engine.Engine COMMIT
```

Cela indique que la transaction a été commitée. Le chemin de la base de données est visible dans les logs au démarrage.

### Option 2 : Vérifier dans le code qui tourne

Le serveur utilise `app.py` qui lit la configuration depuis `.env`. Vérifiez :
- Le fichier `.env` contient : `DATABASE_URL=sqlite:///allo_dakar.db`
- Cela crée la base à la **racine** du projet, pas dans `instance/`

### Option 3 : Vérifier toutes les bases de données

```powershell
# Chercher toutes les bases de données
Get-ChildItem -Recurse -Filter "*.db" | Select-Object FullName, Length, LastWriteTime
```

## 🔧 Solution : Vérifier la base de données active

Quand le serveur Flask tourne, il utilise la base de données définie dans `.env`. 

**Pour voir les données réelles :**

1. **Vérifier le fichier `.env`** :
   ```powershell
   Get-Content .env
   ```

2. **Chercher la base de données à la racine** :
   ```powershell
   if (Test-Path "allo_dakar.db") { 
       Write-Host "Base de données trouvée à la racine"
   }
   ```

3. **Si elle n'existe pas, elle sera créée au prochain commit**

## 📝 Note importante

Les logs montrent que l'inscription a réussi (201), donc les données **devraient** être dans la base de données. Si elles ne sont pas là, c'est peut-être parce que :

1. La base de données est dans un autre emplacement
2. Il y a eu un rollback après le commit (visible dans les logs)
3. Le serveur utilise une autre configuration

## 🎯 Pour vérifier maintenant

Exécutez ce script pendant que le serveur tourne :

```powershell
# Chercher toutes les bases de données modifiées récemment
Get-ChildItem -Recurse -Filter "*.db" | 
    Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-10) } | 
    Select-Object FullName, Length, LastWriteTime
```

Cela vous montrera quelle base de données a été modifiée récemment (pendant votre test d'inscription).

