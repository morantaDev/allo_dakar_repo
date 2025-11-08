# 🎨 Guide d'utilisation du Design System TéMove

## Vue d'ensemble

Ce guide explique comment utiliser le nouveau design system ultra-moderne TéMove dans vos applications Flutter.

---

## 🚀 Démarrage rapide

### 1. Import des composants

```dart
// Pour TéMove (Client App)
import 'package:temove/widgets/modern_card.dart';
import 'package:temove/widgets/modern_button.dart';
import 'package:temove/widgets/modern_input_field.dart';
import 'package:temove/theme/app_theme.dart';

// Pour TéMove Pro (Driver App)
import 'package:temove_pro/widgets/modern_card.dart';
import 'package:temove_pro/widgets/modern_button.dart';
import 'package:temove_pro/theme/app_theme.dart';
```

### 2. Configuration du thème

Le thème est déjà configuré dans `main.dart`. Il utilise automatiquement le mode sombre par défaut.

```dart
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.dark, // Mode sombre par défaut
  // ...
)
```

---

## 🧩 Utilisation des composants

### ModernCard

Carte moderne avec ombres douces et coins arrondis.

#### Exemple basique
```dart
ModernCard(
  child: Column(
    children: [
      Text('Titre', style: Theme.of(context).textTheme.headlineMedium),
      Text('Contenu de la carte'),
    ],
  ),
)
```

#### Exemple avec action
```dart
ModernCard(
  onTap: () {
    // Action au clic
  },
  child: ListTile(
    leading: Icon(Icons.directions_car),
    title: Text('Course disponible'),
    subtitle: Text('À 5 minutes'),
  ),
)
```

#### Exemple avec style personnalisé
```dart
ModernCard(
  padding: EdgeInsets.all(24),
  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  borderRadius: 24,
  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
  child: YourContent(),
)
```

---

### ModernButton

Bouton moderne avec animations fluides et ombres.

#### Exemple basique
```dart
ModernButton(
  label: 'Réserver',
  onPressed: () {
    // Action
  },
)
```

#### Exemple avec icône
```dart
ModernButton(
  label: 'Accepter la course',
  icon: Icons.check_circle,
  onPressed: () {
    // Action
  },
)
```

#### Exemple avec état de chargement
```dart
ModernButton(
  label: 'Se connecter',
  isLoading: isLoggingIn,
  onPressed: isLoggingIn ? null : () {
    _handleLogin();
  },
)
```

#### Exemple de bouton outlined
```dart
ModernButton(
  label: 'Annuler',
  isOutlined: true,
  onPressed: () {
    // Action
  },
)
```

#### Exemple avec style personnalisé
```dart
ModernButton(
  label: 'Action spéciale',
  backgroundColor: AppTheme.accentColor,
  foregroundColor: Colors.white,
  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
  borderRadius: 20,
  onPressed: () {
    // Action
  },
)
```

---

### ModernInputField

Champ de saisie moderne avec animations de focus.

#### Exemple basique
```dart
ModernInputField(
  label: 'Email',
  hint: 'votre@email.com',
  controller: emailController,
)
```

#### Exemple avec icône
```dart
ModernInputField(
  label: 'Mot de passe',
  hint: '••••••••',
  controller: passwordController,
  obscureText: true,
  prefixIcon: Icon(Icons.lock),
  suffixIcon: IconButton(
    icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
    onPressed: () {
      setState(() => obscurePassword = !obscurePassword);
    },
  ),
)
```

#### Exemple avec validation
```dart
ModernInputField(
  label: 'Email',
  hint: 'votre@email.com',
  controller: emailController,
  keyboardType: TextInputType.emailAddress,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }
    if (!value.contains('@')) {
      return 'Email invalide';
    }
    return null;
  },
)
```

#### Exemple multiligne
```dart
ModernInputField(
  label: 'Message',
  hint: 'Votre message...',
  controller: messageController,
  maxLines: 5,
)
```

---

## 🎨 Utilisation des couleurs

### Couleurs principales
```dart
AppTheme.primaryColor    // Jaune #FFD60A
AppTheme.secondaryColor  // Noir #0C0C0C
AppTheme.accentColor     // Vert #00C897
```

### Couleurs sémantiques
```dart
AppTheme.successColor    // Vert succès
AppTheme.warningColor    // Orange avertissement
AppTheme.errorColor      // Rouge erreur
AppTheme.infoColor       // Bleu information
```

### Exemple d'utilisation
```dart
Container(
  color: AppTheme.primaryColor,
  child: Text(
    'Texte',
    style: TextStyle(color: AppTheme.secondaryColor),
  ),
)
```

---

## 📐 Utilisation de la typographie

### Styles de texte prédéfinis
```dart
// Titres
Text('Titre principal', style: Theme.of(context).textTheme.displayLarge)
Text('Sous-titre', style: Theme.of(context).textTheme.headlineMedium)

// Corps
Text('Texte normal', style: Theme.of(context).textTheme.bodyLarge)
Text('Texte secondaire', style: Theme.of(context).textTheme.bodyMedium)

// Labels
Text('Label', style: Theme.of(context).textTheme.labelLarge)
```

### Exemple complet
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      'Titre de la section',
      style: Theme.of(context).textTheme.headlineMedium,
    ),
    SizedBox(height: 8),
    Text(
      'Description de la section',
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  ],
)
```

---

## 🎬 Animations

### Animation de transition
```dart
AnimatedContainer(
  duration: Duration(milliseconds: 200),
  curve: Curves.easeInOut,
  padding: EdgeInsets.all(isExpanded ? 20 : 10),
  child: YourContent(),
)
```

### Animation de fade
```dart
FadeTransition(
  opacity: _fadeAnimation,
  child: YourWidget(),
)
```

---

## 📱 Responsive Design

### Utilisation de MediaQuery
```dart
final screenWidth = MediaQuery.of(context).size.width;
final isMobile = screenWidth < 600;
final isTablet = screenWidth >= 600 && screenWidth < 1200;
final isDesktop = screenWidth >= 1200;
```

### Layout adaptatif
```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 600) {
      return MobileLayout();
    } else {
      return DesktopLayout();
    }
  },
)
```

---

## 🌓 Mode Sombre/Clair

### Détection du mode actuel
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
```

### Couleurs adaptatives
```dart
final backgroundColor = isDark 
  ? AppTheme.surfaceDark 
  : AppTheme.surfaceLight;

final textColor = isDark 
  ? AppTheme.textPrimary 
  : AppTheme.textSecondary;
```

---

## ✅ Bonnes pratiques

### 1. Utilisez les composants modernes
- Préférez `ModernCard` aux `Card` standards
- Préférez `ModernButton` aux `ElevatedButton` standards
- Préférez `ModernInputField` aux `TextFormField` standards

### 2. Respectez les espacements
- Utilisez des multiples de 4px ou 8px
- Padding standard : 20px
- Margin standard : 16px horizontal, 8px vertical

### 3. Respectez les border-radius
- Boutons et inputs : 16px
- Cartes : 20px
- Éléments spéciaux : 24px

### 4. Utilisez les ombres douces
- Cartes : `blurRadius: 20, offset: Offset(0, 8)`
- Boutons : `blurRadius: 12, offset: Offset(0, 4)`

### 5. Animations fluides
- Durée : 100-200ms
- Courbe : `Curves.easeInOut`

---

## 🐛 Dépannage

### Problème : Les couleurs ne s'affichent pas correctement
**Solution** : Vérifiez que le thème est bien appliqué dans `main.dart`

### Problème : Les animations ne fonctionnent pas
**Solution** : Assurez-vous que `SingleTickerProviderStateMixin` est utilisé pour les animations

### Problème : Les ombres ne s'affichent pas
**Solution** : Vérifiez que `elevation: 0` est défini et que les `boxShadow` sont correctement configurés

---

## 📚 Ressources

- [Design System TéMove](./DESIGN_SYSTEM_TEMOVE.md) - Documentation complète du design system
- [Flutter Material Design](https://material.io/design) - Documentation Material Design
- [Google Fonts - Inter](https://fonts.google.com/specimen/Inter) - Documentation de la police Inter

---

**Dernière mise à jour** : 2025-11-08  
**Version** : 1.0.0

