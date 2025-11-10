# 📦 Guide d'Utilisation des Assets TéMove Pro

## 🎨 Logos

### Fichiers Disponibles

- `assets/logos/temove_pro_logo.svg` - Logo full-color (violet)
- `assets/logos/temove_pro_logo_monochrome.svg` - Logo monochrome (noir sur blanc)

### Utilisation dans Flutter

```dart
import 'package:temove_pro/widgets/temove_logo.dart';

// Logo full-color avec texte
TeMoveLogo(
  size: 150,
  showText: true,
)

// Logo monochrome
TeMoveLogo(
  size: 150,
  monochrome: true,
)

// Logo compact (pour navigation)
TeMoveLogoCompact(size: 40)

// Logo sans fond (pour fonds colorés)
TeMoveLogoOutline(
  size: 150,
  showText: true,
)
```

## 🎯 Icônes

### Utilisation

```dart
import 'package:temove_pro/assets/icons/app_icons.dart';

// Icône simple
AppIcons.styledIcon(
  icon: AppIcons.dashboard,
  size: 24,
  isPrimary: true,
)

// Icône avec badge (notifications)
AppIcons.iconWithBadge(
  icon: AppIcons.notification,
  count: 3,
  size: 24,
)

// Icône avec gradient
AppIcons.gradientIcon(
  icon: AppIcons.dashboard,
  size: 24,
)
```

### Icônes Disponibles

- **Navigation** : `dashboard`, `availableRides`, `activeRides`, `history`, `earnings`, `profile`, `settings`
- **Statut de Course** : `pending`, `accepted`, `arrived`, `inProgress`, `completed`, `cancelled`
- **Actions** : `accept`, `reject`, `navigate`, `call`, `message`, `complete`

## 🌐 Favicons

### Génération des Favicons PNG

1. **Installer ImageMagick** : https://imagemagick.org/
2. **Exécuter le script** :
   ```powershell
   cd temove-pro
   .\scripts\generate_favicons.ps1
   ```

### Fichiers Générés

- `web/favicon.svg` - Favicon vectoriel (recommandé)
- `web/favicon.png` - Favicon PNG 32x32
- `web/favicon-16.png` - Favicon 16x16
- `web/favicon-32.png` - Favicon 32x32
- `web/favicon-48.png` - Favicon 48x48
- `web/favicon-192.png` - Favicon 192x192 (Apple Touch Icon)
- `web/favicon-512.png` - Favicon 512x512 (Apple Touch Icon)

## 📱 Icônes d'Application

### Android

Les icônes Android doivent être configurées manuellement dans le projet Android.

### iOS

Les icônes iOS doivent être ajoutées manuellement dans Xcode.

## 🎨 Palette de Couleurs

Voir `IDENTITE_VISUELLE_TEMOVE.md` pour la palette complète.

### Couleurs Principales

- **Violet vibrant** : `#8B5CF6` (primaryColor - différenciation)
- **Bleu électrique** : `#3B82F6` (secondaryColor)
- **Rose vibrant** : `#EC4899` (accentColor)
- **Turquoise néon** : `#06B6D4` (successColor)
- **Rouge corail** : `#F43F5E` (errorColor)

## 📝 Notes

- Tous les logos sont en SVG pour une scalabilité parfaite
- Les icônes utilisent Material Icons pour la cohérence
- Les favicons SVG sont préférés aux PNG pour le web moderne
- Respecter les guidelines d'espacement (20% de la hauteur du logo)
- **Différenciation** : TéMove Pro utilise le violet comme couleur principale pour se distinguer de TéMove Client

## 🔗 Liens Utiles

- [Documentation Identité Visuelle](../IDENTITE_VISUELLE_TEMOVE.md)
- [Flutter SVG Package](https://pub.dev/packages/flutter_svg)
- [ImageMagick](https://imagemagick.org/)

