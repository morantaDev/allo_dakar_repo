# 🔍 Problème : Frontend n'envoie pas la requête

## ❌ Diagnostic

**Aucune requête dans Network** = Le code Flutter n'envoie pas la requête HTTP vers le backend.

## 🔍 Vérifications à faire dans le code Flutter

### 1. Trouver le fichier d'inscription

Cherchez dans votre code Flutter :
- `lib/screens/register_screen.dart` ou `signup_screen.dart`
- `lib/pages/register_page.dart`
- `lib/views/auth/register_view.dart`

### 2. Vérifier la fonction d'inscription

Dans ce fichier, cherchez la fonction qui gère le bouton "S'inscrire". Elle devrait ressembler à :

```dart
void _register() async {
  // Doit appeler l'API ici
  final response = await api.register(...);
}
```

### 3. Vérifier la configuration de l'API

Cherchez le fichier de configuration API :
- `lib/api/api.dart` ou `api_service.dart`
- `lib/services/auth_service.dart`
- `lib/config/api_config.dart`

**Vérifiez que l'URL est :**
```dart
const String API_BASE_URL = 'http://localhost:5000/api/v1';
```

### 4. Vérifier que la fonction est appelée

Dans le code d'inscription, vérifiez :
- Le bouton "S'inscrire" appelle-t-il bien la fonction ?
- Y a-t-il des conditions qui empêchent l'appel ?
- Y a-t-il des try/catch qui masquent les erreurs ?

## 🧪 Test rapide : Vérifier que le backend fonctionne

Depuis PowerShell (dans le dossier backend) :

```powershell
$body = @{
    email = "test@example.com"
    password = "test123"
    full_name = "Test User"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5000/api/v1/auth/register" `
    -Method Post `
    -Body $body `
    -ContentType "application/json"
```

Si ça fonctionne, le problème vient du code Flutter.

## 📝 Prochaines étapes

1. **Trouvez le fichier d'inscription** dans Flutter
2. **Vérifiez la fonction** qui gère l'inscription
3. **Vérifiez l'URL de l'API** dans la configuration
4. **Ajoutez des logs** pour voir si la fonction est appelée :
   ```dart
   print('🔵 Tentative d\'inscription...');
   print('🔵 URL: $API_BASE_URL/auth/register');
   ```

## 🆘 Si vous ne trouvez pas le code

Dites-moi :
- Quel est le nom du projet Flutter ?
- Où se trouve le code d'inscription ?
- Quelle bibliothèque utilisez-vous pour les appels HTTP (http, dio, etc.) ?

