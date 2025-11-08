# Configuration du Favicon TéMove Pro

## Problème

Le favicon par défaut de Flutter s'affiche dans l'onglet du navigateur au lieu du logo TéMove.

## Solution

### Option 1 : Copier le favicon depuis l'application Client

1. **Copier le favicon depuis `temove/web/` vers `temove-pro/web/` :**
   ```bash
   # Depuis la racine du projet
   cp temove/web/favicon.png temove-pro/web/favicon.png
   cp temove/web/favicon.svg temove-pro/web/favicon.svg
   ```

2. **Ou créer un nouveau favicon TéMove :**
   - Créer une image PNG 32x32 ou 64x64 avec le logo TéMove
   - Sauvegarder dans `temove-pro/web/favicon.png`

### Option 2 : Générer les icônes depuis le logo

1. **Utiliser le logo existant :**
   ```bash
   # Le logo se trouve dans temove-pro/assets/icons/app_logo.png
   # Copier ce logo vers web/favicon.png
   cp temove-pro/assets/icons/app_logo.png temove-pro/web/favicon.png
   ```

2. **Redimensionner si nécessaire :**
   - Ouvrir `app_logo.png` dans un éditeur d'images
   - Redimensionner à 32x32 ou 64x64 pixels
   - Sauvegarder comme `favicon.png` dans `temove-pro/web/`

### Option 3 : Utiliser un outil en ligne

1. Aller sur https://favicon.io/ ou https://realfavicongenerator.net/
2. Uploader le logo TéMove
3. Télécharger les fichiers générés
4. Placer les fichiers dans `temove-pro/web/`

## Fichiers à mettre à jour

- `temove-pro/web/favicon.png` - Favicon principal (32x32 ou 64x64)
- `temove-pro/web/favicon.svg` - Favicon vectoriel (optionnel)
- `temove-pro/web/icons/Icon-192.png` - Icône pour PWA (192x192)
- `temove-pro/web/icons/Icon-512.png` - Icône pour PWA (512x512)

## Vérification

Après avoir copié/configuré le favicon :

1. Vider le cache du navigateur (Ctrl+Shift+Delete)
2. Redémarrer l'application Flutter Web
3. Vérifier que le favicon TéMove s'affiche dans l'onglet

## Note

Le fichier `web/index.html` est déjà configuré pour utiliser `favicon.png`.
Il suffit de placer le fichier au bon endroit.

