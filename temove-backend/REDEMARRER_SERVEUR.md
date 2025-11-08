# 🔄 Redémarrer le Serveur Flask

## ⚠️ Important

Le serveur Flask doit être **redémarré** pour que les modifications CORS prennent effet.

## 📋 Étapes

### 1. Arrêter le serveur actuel

Dans le terminal où le serveur Flask est en cours d'exécution :
- Appuyez sur `Ctrl+C` pour arrêter le serveur

### 2. Redémarrer le serveur

```powershell
cd C:\allo_dakar_repo\allo-dakar-backend
python run.py
```

ou

```powershell
python app.py
```

### 3. Vérifier que le serveur démarre correctement

Vous devriez voir dans les logs :
```
🚀 Démarrage du serveur Flask TeMove
📍 Environnement: development
🌐 Host: 0.0.0.0
🔌 Port: 5000
🔗 URL: http://0.0.0.0:5000
🔗 API: http://0.0.0.0:5000/api/v1
💚 Health: http://0.0.0.0:5000/health
```

### 4. Tester la connexion

Ouvrez un navigateur et allez sur :
```
http://127.0.0.1:5000/health
```

Vous devriez voir :
```json
{
  "message": "TeMove API is running",
  "status": "ok",
  "timestamp": "..."
}
```

## ✅ Après redémarrage

1. Reconnectez-vous en tant qu'admin dans l'application Flutter
2. Le dashboard admin devrait maintenant fonctionner sans erreur CORS
3. Les tables `commissions` et `revenues` seront créées automatiquement si elles n'existent pas

