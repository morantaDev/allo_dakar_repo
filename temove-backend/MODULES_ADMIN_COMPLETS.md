# 📋 Modules Admin Complets - TéMove

## ✅ Modules Implémentés

### 1. 📊 **Dashboard Admin** (`AdminScreen`)
- Statistiques globales (revenus, courses, utilisateurs, conducteurs)
- Graphiques dynamiques (courses et revenus des 7 derniers jours)
- Vue d'ensemble combinée (TeMove + TeMove Pro)

### 2. 👥 **Gestion des Utilisateurs** (`AdminUsersScreen`)
- Liste avec pagination
- Recherche par nom, email, téléphone
- Filtres par statut (Actif/Inactif)
- Activation/désactivation d'utilisateurs
- Affichage du nombre total de courses par utilisateur

### 3. 🚗 **Gestion des Conducteurs** (`AdminDriversScreen`)
- Liste avec pagination
- Recherche par nom, email, plaque
- Filtres par statut (En attente/Actif/Inactif)
- Approbation/Rejet de nouveaux conducteurs
- Activation/désactivation de conducteurs
- Affichage des notes, nombre de courses, véhicule

### 4. 🚖 **Gestion des Courses** (`AdminRidesScreen`)
- Liste avec pagination
- Filtres par statut (En attente/Assignée/En cours/Terminée)
- Sélection de période (date de début/fin)
- Détails des courses (pickup, dropoff, prix, distance)
- Affichage du chauffeur et du client

### 5. 💳 **Gestion des Paiements** (`AdminPaymentsScreen`)
- Liste avec pagination
- Statistiques rapides (total, nombre de paiements)
- Filtres par statut (Complété/En attente/Échoué)
- Sélection de période
- **Export Excel/PDF** (avec dialogue de sélection de format)
- Affichage de la méthode de paiement, montant, date

### 6. 💰 **Gestion des Commissions** (`AdminCommissionsScreen`) ⭐ NOUVEAU
- Liste avec pagination
- **Statistiques des commissions** :
  - Total des commissions
  - Commissions payées
  - Commissions en attente
- **Taux de commission : 10%** (affiché dans l'interface)
- Filtres par statut (En attente/Payées)
- Sélection de période
- **Marquer une commission comme payée**
- Affichage du conducteur, montant, date de création/paiement

### 7. 📱 **Gestion des Abonnements** (`AdminSubscriptionsScreen`) ⭐ NOUVEAU
- Liste avec pagination
- Filtres par type (Conducteurs/Utilisateurs)
- Filtres par statut (Actifs/Expirés/Annulés)
- Affichage du plan (Basique/Premium/Entreprise)
- Affichage du prix, dates de début/fin
- **Note** : La table `subscriptions` n'existe pas encore dans la base de données. L'endpoint retourne une liste vide avec un message informatif.

### 8. 📈 **Rapports** (`AdminReportsScreen`) ⭐ NOUVEAU
- **Types de rapports disponibles** :
  - Revenus
  - Courses
  - Conducteurs
  - Utilisateurs
  - Commissions
- **Formats d'export** :
  - Excel (`.xlsx`)
  - PDF (`.pdf`)
- Sélection de période (date de début/fin)
- Génération de rapports avec retour de l'URL du fichier
- **Note** : La génération réelle de fichiers Excel/PDF nécessite l'installation de bibliothèques supplémentaires (`pandas`, `openpyxl` pour Excel, `reportlab` pour PDF). L'endpoint retourne pour l'instant une réponse de succès avec un message informatif.

### 9. ⚙️ **Paramètres Admin** (`AdminSettingsScreen`) ⭐ NOUVEAU
- **Paramètres configurables** :
  - **Taux de commission** : 10% par défaut (modifiable)
  - **Frais de service** : Frais fixes par course (XOF)
  - **Prix minimum** : Prix minimum d'une course (XOF)
  - **Prix maximum** : Prix maximum d'une course (XOF)
- Validation des valeurs (taux entre 0-100%, prix valides)
- Sauvegarde des paramètres
- **Note** : Les paramètres sont pour l'instant stockés en mémoire. Une table `settings` devrait être créée pour la persistance.

### 10. 🗺️ **Suivi Temps Réel** (À créer)
- Affichage d'une carte avec les trajets en cours
- Affichage des conducteurs actifs
- Mise à jour en temps réel
- **Status** : Module préparé mais écran non créé (menu présent avec message "À venir")

---

## 🔗 Routes Backend

### Commissions
- `GET /api/v1/admin/commissions` - Liste des commissions avec pagination et filtres
- `POST /api/v1/admin/commissions/<id>/mark-paid` - Marquer une commission comme payée

### Abonnements
- `GET /api/v1/admin/subscriptions` - Liste des abonnements avec pagination et filtres

### Rapports
- `POST /api/v1/admin/reports/generate` - Générer un rapport (Excel/PDF)

### Paramètres
- `GET /api/v1/admin/settings` - Obtenir les paramètres administratifs
- `PUT /api/v1/admin/settings` - Mettre à jour les paramètres administratifs

---

## 📱 Navigation

Tous les modules sont accessibles via le menu latéral (`AdminDrawer`) :
1. Dashboard
2. Utilisateurs
3. Conducteurs
4. Courses
5. Paiements
6. Commissions ⭐
7. Abonnements ⭐
8. Suivi Temps Réel (À venir)
9. Rapports ⭐
10. Paramètres ⭐

---

## 🎨 Fonctionnalités Communes

Tous les écrans partagent :
- **Pagination** : Navigation entre les pages
- **Recherche** : Recherche en temps réel (quand applicable)
- **Filtres** : Filtrage par statut, type, période
- **Actualisation** : Bouton de rafraîchissement et `RefreshIndicator`
- **Gestion d'erreurs** : Messages d'erreur clairs avec possibilité de réessayer
- **Thème sombre** : Support du thème sombre/clair
- **Design cohérent** : Utilisation des couleurs TéMove (jaune, noir, vert)

---

## 📝 Notes Importantes

### Commissions
- Le taux de commission est actuellement fixé à **10%** (affiché dans l'interface)
- Les commissions sont créées automatiquement lors de la création d'une course (si la table `commissions` existe)
- Les commissions peuvent être marquées comme payées via l'interface admin

### Abonnements
- La table `subscriptions` n'existe pas encore dans la base de données
- L'endpoint retourne une liste vide avec un message informatif
- **À implémenter** : Création de la table `subscriptions` avec les champs nécessaires

### Rapports
- La génération réelle de fichiers Excel/PDF nécessite l'installation de bibliothèques supplémentaires
- **Pour Excel** : `pandas`, `openpyxl`
- **Pour PDF** : `reportlab`
- L'endpoint retourne pour l'instant une réponse de succès avec un message informatif

### Paramètres
- Les paramètres sont pour l'instant stockés en mémoire (non persistants)
- **À implémenter** : Création d'une table `settings` pour la persistance
- Les paramètres par défaut sont :
  - Taux de commission : 10%
  - Frais de service : 0 XOF
  - Prix minimum : 500 XOF
  - Prix maximum : 50000 XOF

---

## 🚀 Prochaines Étapes

1. **Créer la table `subscriptions`** dans la base de données
2. **Créer la table `settings`** dans la base de données
3. **Implémenter la génération réelle de rapports** (Excel/PDF)
4. **Créer l'écran de suivi temps réel** avec carte interactive
5. **Ajouter des tests unitaires** pour les nouveaux endpoints
6. **Améliorer la gestion des permissions** (rôles admin/super admin)

---

## 📚 Documentation API

### Exemple de requête : Liste des commissions
```bash
GET /api/v1/admin/commissions?page=1&per_page=20&status=pending
Authorization: Bearer <token>
```

### Exemple de requête : Marquer une commission comme payée
```bash
POST /api/v1/admin/commissions/1/mark-paid
Authorization: Bearer <token>
```

### Exemple de requête : Générer un rapport
```bash
POST /api/v1/admin/reports/generate
Authorization: Bearer <token>
Content-Type: application/json

{
  "report_type": "revenue",
  "start_date": "2025-11-01",
  "end_date": "2025-11-08",
  "format": "excel"
}
```

### Exemple de requête : Mettre à jour les paramètres
```bash
PUT /api/v1/admin/settings
Authorization: Bearer <token>
Content-Type: application/json

{
  "commission_rate": 12.0,
  "service_fee": 100,
  "min_ride_price": 500,
  "max_ride_price": 50000
}
```

---

**Document créé le** : 2025-11-08  
**Dernière mise à jour** : 2025-11-08

