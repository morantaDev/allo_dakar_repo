# 📊 Génération de Rapports - TéMove

## 📋 Vue d'ensemble

Le système de génération de rapports permet aux administrateurs de générer et télécharger des rapports Excel (`.xlsx`) et PDF (`.pdf`) pour différents types de données :

- **Revenus** : Revenus quotidiens avec nombre de courses
- **Courses** : Liste complète des courses avec détails
- **Conducteurs** : Informations sur les conducteurs
- **Utilisateurs** : Liste des utilisateurs avec statistiques
- **Commissions** : Détails des commissions et paiements
- **Paiements** : Historique des paiements

## 🔧 Installation

### 1. Installer les dépendances Python

Les bibliothèques nécessaires doivent être installées dans l'environnement virtuel :

```bash
cd temove-backend
pip install pandas openpyxl reportlab
```

Ou installer toutes les dépendances :

```bash
pip install -r requirements.txt
```

### 2. Vérifier l'installation

```python
python -c "import pandas; import openpyxl; import reportlab; print('Toutes les bibliothèques sont installées')"
```

## 📁 Structure des fichiers

### Répertoire de stockage

Les rapports sont générés dans le répertoire `reports/` à la racine du projet `temove-backend/`.

```
temove-backend/
├── reports/              # Répertoire des rapports générés
│   ├── revenue_20251101_20251108_20251108_143022.xlsx
│   ├── rides_20251101_20251108_20251108_143045.pdf
│   └── ...
├── services/
│   └── report_service.py  # Service de génération
└── routes/
    └── admin_routes.py    # Endpoint de génération
```

### Nommage des fichiers

Les fichiers sont nommés automatiquement selon le format :
```
{report_type}_{start_date}_{end_date}_{timestamp}.{extension}
```

Exemple :
- `revenue_20251101_20251108_20251108_143022.xlsx`
- `rides_20251101_20251108_20251108_143045.pdf`

## 🚀 Utilisation

### 1. Via l'interface Admin (Flutter Web)

1. Se connecter en tant qu'administrateur
2. Aller dans **Rapports** (menu latéral)
3. Sélectionner le type de rapport
4. Choisir la période (date de début et date de fin)
5. Sélectionner le format (Excel ou PDF)
6. Cliquer sur **"Générer le rapport"**
7. Le fichier sera automatiquement téléchargé

### 2. Via l'API REST

#### Endpoint

```
POST /api/v1/admin/reports/generate
```

#### Headers

```
Authorization: Bearer <token_admin>
Content-Type: application/json
```

#### Body

```json
{
  "report_type": "revenue",
  "start_date": "2025-11-01",
  "end_date": "2025-11-08",
  "format": "excel"
}
```

#### Types de rapports disponibles

- `revenue` : Revenus
- `rides` : Courses
- `drivers` : Conducteurs
- `users` : Utilisateurs
- `commissions` : Commissions
- `payments` : Paiements

#### Formats disponibles

- `excel` : Fichier Excel (`.xlsx`)
- `pdf` : Fichier PDF (`.pdf`)

#### Exemple avec cURL

```bash
curl -X POST http://localhost:5000/api/v1/admin/reports/generate \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "report_type": "revenue",
    "start_date": "2025-11-01",
    "end_date": "2025-11-08",
    "format": "excel"
  }' \
  --output rapport.xlsx
```

## 📊 Format des données

### Rapport Revenus

| Date | Revenus (XOF) | Nombre de courses |
|------|---------------|-------------------|
| 2025-11-01 | 50000 | 25 |
| 2025-11-02 | 75000 | 38 |

### Rapport Courses

| ID | Client | Chauffeur | Départ | Destination | Distance (km) | Prix (XOF) | Statut | Date |
|----|--------|-----------|--------|-------------|---------------|------------|--------|------|
| 1 | John Doe | Amadou Diallo | Dakar | Liberté 4 | 4.15 | 3346 | COMPLETED | 2025-11-08 |

### Rapport Conducteurs

| ID | Nom | Email | Téléphone | Plaque | Véhicule | Note | Courses | Statut |
|----|-----|-------|-----------|--------|----------|------|---------|--------|
| 1 | Amadou Diallo | amadou@example.com | +221... | 501234AB | Toyota Yaris | 4.9 | 150 | ONLINE |

## 🔍 Dépannage

### Erreur : "pandas n'est pas installé"

**Solution** :
```bash
pip install pandas openpyxl
```

### Erreur : "reportlab n'est pas installé"

**Solution** :
```bash
pip install reportlab
```

### Erreur : "Permission denied" lors de la création du dossier reports/

**Solution** : Vérifier les permissions du répertoire `temove-backend/` et créer manuellement le dossier `reports/` :

```bash
mkdir reports
chmod 755 reports
```

### Les fichiers ne sont pas téléchargés dans le navigateur

**Vérifications** :
1. Vérifier que le backend renvoie bien le fichier (status 200)
2. Vérifier la console du navigateur pour les erreurs JavaScript
3. Vérifier que `dart:html` est disponible (Flutter Web uniquement)

### Les fichiers générés sont vides

**Causes possibles** :
1. Aucune donnée dans la période sélectionnée
2. Erreur lors de la récupération des données
3. Vérifier les logs du backend pour plus de détails

## 📝 Notes importantes

### Stockage des fichiers

- Les fichiers sont générés **sur le serveur** dans le dossier `reports/`
- Les fichiers sont **renvoyés directement** au client pour téléchargement
- Les fichiers ne sont **pas stockés de manière permanente** (peuvent être supprimés)
- Pour un stockage permanent, implémenter un système de nettoyage automatique

### Performance

- Les rapports peuvent prendre plusieurs secondes pour les grandes quantités de données
- Les rapports sont limités à **1000 enregistrements** maximum
- Pour des rapports plus volumineux, utiliser la pagination ou filtrer par période

### Sécurité

- Seuls les administrateurs peuvent générer des rapports
- L'authentification JWT est requise
- Les données sensibles (mots de passe, etc.) ne sont pas incluses dans les rapports

## 🚧 Améliorations futures

- [ ] Nettoyage automatique des anciens rapports
- [ ] Génération de rapports en arrière-plan (tâches asynchrones)
- [ ] Envoi de rapports par email
- [ ] Rapports programmés (cron jobs)
- [ ] Export CSV en plus d'Excel et PDF
- [ ] Graphiques dans les rapports PDF
- [ ] Personnalisation des colonnes à exporter

---

**Document créé le** : 2025-11-08  
**Dernière mise à jour** : 2025-11-08

