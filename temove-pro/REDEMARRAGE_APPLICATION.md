# Instructions pour redémarrer l'application

## Problème de cache Flutter

Si vous voyez encore des erreurs après la correction du code, c'est probablement dû au cache Flutter.

### Solution rapide (dans le terminal Flutter) :

1. **Hot Restart complet** : Appuyez sur `R` (majuscule) au lieu de `r` (minuscule)
   - Cela redémarre complètement l'application sans perdre l'état de connexion

2. **Si le problème persiste** :
   - Appuyez sur `q` pour quitter l'application
   - Relancez avec : `flutter run -d chrome`

### Pour l'erreur d'asset (app_logo.png) :

Le fichier existe bien dans `assets/icons/app_logo.png`. Si l'erreur persiste :

1. Vérifiez que le fichier existe : `assets/icons/app_logo.png`
2. Vérifiez que `pubspec.yaml` contient bien :
   ```yaml
   assets:
     - assets/images/
     - assets/icons/
   ```
3. Après modification de `pubspec.yaml`, exécutez :
   ```bash
   flutter clean
   flutter pub get
   flutter run -d chrome
   ```

### Résumé des commandes :

```powershell
# Nettoyer et redémarrer
cd C:\allo_dakar_repo\temove-pro
flutter clean
flutter pub get
flutter run -d chrome
```

