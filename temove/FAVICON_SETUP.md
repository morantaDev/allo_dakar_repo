# 🎨 Configuration du Favicon TeMove

## Problème
Le favicon de l'application affichait le logo Flutter par défaut au lieu du logo TeMove (`app_logo.png`).

## Solution

### Méthode 1 : Script PowerShell (Recommandé)

1. **Exécuter le script de création du favicon** :
   ```powershell
   cd C:\allo_dakar_repo\temove
   .\scripts\create_favicon.ps1
   ```

   **Note** : Si ImageMagick est installé, le script redimensionnera automatiquement le logo à 32x32 pixels. Sinon, il copiera le logo original (les navigateurs le redimensionneront automatiquement).

2. **Installer ImageMagick (optionnel, pour un meilleur résultat)** :
   - Télécharger depuis : https://imagemagick.org/script/download.php
   - Ou installer via Chocolatey : `choco install imagemagick`

### Méthode 2 : Outil en ligne

1. Aller sur un outil de conversion d'images en ligne (ex: https://convertio.co/fr/png-ico/, https://www.favicon-generator.org/)
2. Uploader `assets/icons/app_logo.png`
3. Générer un favicon 32x32 pixels
4. Télécharger et remplacer `web/favicon.png`

### Méthode 3 : Manuel (si vous avez un éditeur d'images)

1. Ouvrir `assets/icons/app_logo.png` dans un éditeur d'images
2. Redimensionner à 32x32 pixels (ou 16x16 pour une version plus petite)
3. Sauvegarder comme `web/favicon.png`

## Vérification

Après avoir créé le favicon :

1. **Reconstruire l'application web** :
   ```powershell
   cd C:\allo_dakar_repo\temove
   flutter clean
   flutter pub get
   flutter build web
   ```

2. **Tester localement** :
   ```powershell
   flutter run -d chrome
   ```

3. **Vérifier le favicon** :
   - Ouvrir l'application dans Chrome
   - Vérifier l'onglet du navigateur (le favicon devrait apparaître)
   - Vérifier les DevTools → Network → chercher "favicon" pour confirmer le chargement

## Fichiers concernés

- `web/favicon.png` - Favicon PNG (32x32 ou 16x16 pixels)
- `web/favicon.svg` - Favicon SVG (référence le PNG)
- `web/index.html` - Références aux favicons (déjà configuré)

## Notes

- Le favicon SVG est configuré pour référencer le PNG, ce qui permet une meilleure compatibilité
- Les navigateurs modernes préfèrent le SVG, mais utilisent le PNG comme fallback
- Le favicon peut prendre quelques secondes à se mettre à jour dans le navigateur (cache)

## Résolution des problèmes

### Le favicon ne s'affiche pas
1. Vider le cache du navigateur (Ctrl+Shift+Delete)
2. Reconstruire l'application : `flutter clean && flutter build web`
3. Vérifier que les fichiers `favicon.png` et `favicon.svg` existent dans `web/`

### Le favicon est flou
- S'assurer que le logo source est de bonne qualité
- Utiliser ImageMagick pour un redimensionnement de qualité
- Vérifier que la taille est bien 32x32 pixels (ou un multiple)

### Le favicon ne se met pas à jour
- Vider le cache du navigateur
- Faire un hard refresh (Ctrl+F5)
- Vérifier les références dans `web/index.html`

