# Guide de Configuration des Favicons et Icônes TéMove Pro

## Problème
Les favicons et icônes affichés dans l'onglet du navigateur ne correspondent pas au logo TéMove Pro.

## Solution Automatique (Recommandée)

### Avec ImageMagick

1. **Installer ImageMagick** :
   - Télécharger depuis https://imagemagick.org/script/download.php
   - Installer et s'assurer que `magick` est dans le PATH

2. **Générer les favicons** :
   ```powershell
   cd temove-pro
   powershell -ExecutionPolicy Bypass -File scripts/generate_favicons_from_logo.ps1
   ```

Le script génère automatiquement :
- `web/favicon.svg` - Favicon vectoriel
- `web/favicon.png` - Favicon PNG (32x32)
- `web/icons/Icon-192.png` - Icône PWA (192x192)
- `web/icons/Icon-512.png` - Icône PWA (512x512)
- `web/icons/Icon-maskable-192.png` - Icône maskable (192x192)
- `web/icons/Icon-maskable-512.png` - Icône maskable (512x512)

## Solution Manuelle

Si ImageMagick n'est pas installé, vous pouvez générer les icônes manuellement :

### 1. Utiliser un outil en ligne

1. Aller sur https://realfavicongenerator.net/
2. Uploader le logo TéMove Pro depuis `assets/logos/temove_pro_logo.svg` ou `assets/icons/app_logo.png`
3. Configurer les options :
   - Favicon pour les navigateurs de bureau
   - iOS touch icon
   - Android Chrome icon
   - Windows tiles
4. Télécharger le package généré
5. Extraire les fichiers dans le répertoire `web/`

### 2. Utiliser un éditeur d'images

1. Ouvrir le logo dans un éditeur d'images (GIMP, Photoshop, etc.)
2. Créer les fichiers suivants :
   - `favicon.png` - 32x32 pixels
   - `icons/Icon-192.png` - 192x192 pixels
   - `icons/Icon-512.png` - 512x512 pixels
   - `icons/Icon-maskable-192.png` - 192x192 pixels (avec padding pour maskable)
   - `icons/Icon-maskable-512.png` - 512x512 pixels (avec padding pour maskable)

### 3. Copier depuis les assets

Le script copie automatiquement le logo SVG vers `favicon.svg` et le PNG vers `favicon.png`. 
Vous devrez ensuite redimensionner manuellement le PNG aux tailles requises.

## Fichiers à Vérifier

Après génération, vérifier que les fichiers suivants existent :

- `temove-pro/web/favicon.svg`
- `temove-pro/web/favicon.png`
- `temove-pro/web/icons/Icon-192.png`
- `temove-pro/web/icons/Icon-512.png`
- `temove-pro/web/icons/Icon-maskable-192.png`
- `temove-pro/web/icons/Icon-maskable-512.png`

## Configuration HTML

Les fichiers `web/index.html` sont déjà configurés pour utiliser ces favicons :
- Favicon SVG (priorité pour les navigateurs modernes)
- Favicon PNG (fallback)
- Icônes Apple Touch (iOS)
- Icônes PWA (Android)

## Vérification

1. **Vider le cache du navigateur** :
   - Chrome/Edge : Ctrl+Shift+Delete
   - Firefox : Ctrl+Shift+Delete
   - Safari : Cmd+Option+E

2. **Redémarrer l'application Flutter Web** :
   ```bash
   flutter run -d chrome
   ```

3. **Vérifier dans l'onglet du navigateur** :
   - Le favicon TéMove Pro doit s'afficher dans l'onglet
   - Le titre doit être "TéMove Pro - Application Chauffeurs"

## Notes

- Les favicons sont mis en cache par les navigateurs. Si les changements ne s'affichent pas, vider le cache.
- Pour les PWA, les icônes doivent être au format PNG avec les tailles exactes (192x192, 512x512).
- Les icônes maskable doivent avoir un padding d'environ 20% pour être correctement masquées sur Android.

## Couleurs TéMove Pro

- **Couleur principale** : `#FFD60A` (Jaune TéMove)
- **Couleur de fond** : `#FFD60A` (pour le manifest.json)
- **Couleur de thème** : `#FFD60A` (pour le manifest.json)

Ces couleurs sont définies dans `web/manifest.json` et utilisées pour les thèmes de l'application PWA.

