# 🎨 Design System TéMove - Ultra-moderne

## Vue d'ensemble

Design system unifié pour l'écosystème TéMove (Client App, Driver App, Admin Dashboard) avec une identité visuelle forte, moderne et cohérente.

---

## 🎨 Identité Visuelle

### Couleurs principales

```dart
// Jaune TéMove (couleur primaire)
primaryColor: Color(0xFFFFD60A)  // #FFD60A

// Noir profond TéMove
secondaryColor: Color(0xFF0C0C0C)  // #0C0C0C

// Vert doux TéMove (accent)
accentColor: Color(0xFF00C897)  // #00C897
```

### Palette complète

#### Nuances de jaune
- `yellowLight`: `#FFE766`
- `yellowDark`: `#CCAA08`

#### Nuances de noir/gris
- `blackPrimary`: `#0C0C0C`
- `blackSecondary`: `#1A1A1A`
- `grayDark`: `#2C2C2C`
- `grayMedium`: `#4A4A4A`
- `grayLight`: `#6E6E6E`
- `grayLighter`: `#9E9E9E`
- `grayLightest`: `#E0E0E0`

#### Nuances de vert
- `greenLight`: `#33D4A6`
- `greenDark`: `#009A6E`

#### Couleurs sémantiques
- `successColor`: `#00C897` (vert)
- `warningColor`: `#FFB703` (orange)
- `errorColor`: `#E63946` (rouge)
- `infoColor`: `#219EBC` (bleu)

---

## 📝 Typographie

### Police principale
**Inter** - Police moderne, lisible et professionnelle

### Hiérarchie typographique

```dart
displayLarge:  32px, Bold,   -0.5 letter-spacing
displayMedium: 28px, Bold,   -0.5 letter-spacing
displaySmall:  24px, Bold,   -0.3 letter-spacing
headlineLarge: 22px, Semibold
headlineMedium: 20px, Semibold
bodyLarge:     16px, Regular
bodyMedium:    14px, Regular
labelLarge:    14px, Medium
```

---

## 🎯 Principes de Design

### Style
- **Minimaliste** : Design épuré, sans éléments superflus
- **Mobile-first** : Optimisé pour les écrans mobiles
- **Flat design** : Design plat avec ombres douces pour la profondeur
- **Coins arrondis** : Border-radius minimum de 16px pour un look moderne

### Ombres douces
```dart
// Carte (dark mode)
BoxShadow(
  color: Colors.black.withOpacity(0.15),
  blurRadius: 20,
  offset: Offset(0, 8),
  spreadRadius: 0,
)

// Carte (light mode)
BoxShadow(
  color: Colors.black.withOpacity(0.08),
  blurRadius: 20,
  offset: Offset(0, 8),
  spreadRadius: 0,
)

// Bouton
BoxShadow(
  color: primaryColor.withOpacity(0.3),
  blurRadius: 12,
  offset: Offset(0, 4),
  spreadRadius: 0,
)
```

### Espacements
- **Padding standard** : 20px
- **Margin standard** : 16px horizontal, 8px vertical
- **Border-radius standard** : 16px (boutons, inputs), 20px (cartes)

---

## 🧩 Composants UI Modernes

### ModernCard
Carte moderne avec ombres douces et coins arrondis.

```dart
ModernCard(
  padding: EdgeInsets.all(20),
  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  borderRadius: 20,
  onTap: () {}, // Optionnel
  child: YourContent(),
)
```

### ModernButton
Bouton moderne avec animations fluides et ombres.

```dart
ModernButton(
  label: 'Réserver',
  icon: Icons.directions_car,
  onPressed: () {},
  isLoading: false,
  isOutlined: false,
)
```

### ModernInputField
Champ de saisie moderne avec animations de focus.

```dart
ModernInputField(
  label: 'Email',
  hint: 'votre@email.com',
  controller: emailController,
  prefixIcon: Icon(Icons.email),
  validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
)
```

---

## 📱 Applications

### TéMove (Client App)
- **Thème** : Dark mode par défaut
- **Composants** : ModernCard, ModernButton, ModernInputField
- **Écrans principaux** :
  - Welcome Screen (onboarding)
  - Map Screen (réservation)
  - Ride Tracking Screen (suivi de course)
  - Booking Screen (réservation)

### TéMove Pro (Driver App)
- **Thème** : Dark mode par défaut
- **Composants** : ModernCard, ModernButton, ModernInputField
- **Écrans principaux** :
  - Login/Signup Screen
  - Dashboard (statistiques, revenus)
  - Rides List Screen (courses disponibles)
  - Profile Screen

### TéMove Backend (Admin Dashboard)
- **Thème** : Dark mode par défaut
- **Composants** : AdminStatCard, AdminChartCard, ModernCard
- **Écrans principaux** :
  - Dashboard (statistiques globales)
  - Users Management
  - Drivers Management
  - Rides Management
  - Payments Management
  - Reports

---

## 🎬 Animations

### Principes
- **Durée** : 100-200ms pour les interactions
- **Courbes** : `Curves.easeInOut` pour des transitions fluides
- **Scale** : 0.95 pour l'effet de pression sur les boutons

### Exemple d'animation de bouton
```dart
AnimationController(
  duration: Duration(milliseconds: 100),
  vsync: this,
)

Animation<double> _scaleAnimation = Tween<double>(
  begin: 1.0,
  end: 0.95,
).animate(
  CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  ),
)
```

---

## 🌓 Mode Sombre/Clair

### Support automatique
Les thèmes supportent automatiquement le mode sombre et clair selon les préférences du système.

### Couleurs adaptatives
- **Dark mode** : Fond `#0C0C0C`, Texte `#FFFFFF`, Surfaces `#1A1A1A`
- **Light mode** : Fond `#FAFAFA`, Texte `#0C0C0C`, Surfaces `#FFFFFF`

---

## 📐 Responsive Design

### Breakpoints
- **Mobile** : < 600px
- **Tablet** : 600px - 1200px
- **Desktop** : > 1200px

### Principes
- **Mobile-first** : Design optimisé d'abord pour mobile
- **Flexible layouts** : Utilisation de `Flexible` et `Expanded`
- **Adaptive spacing** : Espacements qui s'adaptent à la taille de l'écran

---

## 🚀 Utilisation

### Import des composants
```dart
import 'package:temove/widgets/modern_card.dart';
import 'package:temove/widgets/modern_button.dart';
import 'package:temove/widgets/modern_input_field.dart';
```

### Import du thème
```dart
import 'package:temove/theme/app_theme.dart';
```

### Application du thème
```dart
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.dark, // ou ThemeMode.system
  // ...
)
```

---

## 📚 Ressources

### Fichiers
- `temove/lib/theme/app_theme.dart` - Thème TéMove Client
- `temove-pro/lib/theme/app_theme.dart` - Thème TéMove Pro
- `temove/lib/widgets/modern_card.dart` - Composant carte moderne
- `temove/lib/widgets/modern_button.dart` - Composant bouton moderne
- `temove/lib/widgets/modern_input_field.dart` - Composant input moderne

### Documentation
- [Flutter Material Design](https://material.io/design)
- [Google Fonts - Inter](https://fonts.google.com/specimen/Inter)
- [Flutter Animations](https://flutter.dev/docs/development/ui/animations)

---

## ✅ Checklist Design

- [x] Couleurs uniformes (#FFD60A, #0C0C0C, #00C897)
- [x] Typographie Inter partout
- [x] Border-radius 16px minimum
- [x] Ombres douces pour la profondeur
- [x] Animations fluides (100-200ms)
- [x] Support dark/light mode
- [x] Design mobile-first
- [x] Composants réutilisables
- [x] Code commenté et documenté

---

**Dernière mise à jour** : 2025-11-08  
**Version** : 1.0.0

