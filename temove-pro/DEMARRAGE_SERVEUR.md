# Guide de démarrage du serveur Flask

## Problème : "Failed to fetch" ou "ClientException"

Si vous rencontrez l'erreur `ClientException: Failed to fetch`, cela signifie que le serveur Flask n'est pas accessible.

## Solution : Démarrer le serveur Flask

### Étape 1 : Ouvrir un terminal dans le dossier backend

```powershell
cd C:\allo_dakar_repo\allo-dakar-backend
```

### Étape 2 : Activer l'environnement virtuel (si vous en avez un)

```powershell
.\venv\Scripts\activate
```

### Étape 3 : Démarrer le serveur Flask

```powershell
python app.py
```

Ou avec Flask CLI :

```powershell
python -m flask run --host=0.0.0.0 --port=5000
```

### Étape 4 : Vérifier que le serveur est démarré

Le serveur devrait afficher :
```
* Running on all addresses (0.0.0.0)
* Running on http://127.0.0.1:5000
* Running on http://[VOTRE_IP]:5000
```

### Étape 5 : Tester l'endpoint de santé

Ouvrez dans votre navigateur : http://127.0.0.1:5000/health

Vous devriez voir :
```json
{
  "status": "ok",
  "message": "Allo Dakar API is running",
  "timestamp": "..."
}
```

## Vérification dans l'application Flutter

L'application Témove Pro teste automatiquement la connexion au serveur avant de tenter la connexion. Les logs dans la console afficheront :

- ✅ `[CONNECTION_TEST] Serveur accessible` - Le serveur est démarré
- ❌ `[CONNECTION_TEST] Erreur: ...` - Le serveur n'est pas accessible

## Dépannage

### Le serveur ne démarre pas

1. Vérifiez que Python est installé : `python --version`
2. Vérifiez que les dépendances sont installées : `pip install -r requirements.txt`
3. Vérifiez que le port 5000 n'est pas déjà utilisé par un autre processus

### Le serveur démarre mais l'application ne peut pas se connecter

1. Vérifiez que le serveur écoute sur `0.0.0.0` et pas seulement sur `127.0.0.1`
2. Vérifiez que CORS est configuré (déjà fait dans `app.py`)
3. Vérifiez qu'aucun firewall ne bloque la connexion

### Erreur CORS

Si vous voyez des erreurs CORS dans la console du navigateur, vérifiez que `flask-cors` est installé :

```powershell
pip install flask-cors
```

