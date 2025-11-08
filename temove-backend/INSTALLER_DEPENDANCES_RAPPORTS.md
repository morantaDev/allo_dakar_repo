# 📦 Installation des Dépendances pour la Génération de Rapports

## 🔴 Problème

L'erreur `pandas n'est pas installé` ou `reportlab n'est pas installé` indique que les bibliothèques nécessaires ne sont pas installées dans l'environnement virtuel utilisé par le backend.

## ✅ Solution

### 1. Activer l'environnement virtuel

**Important** : Assurez-vous d'activer le bon environnement virtuel avant d'installer les packages.

```powershell
# Naviguer vers le répertoire du backend
cd C:\allo_dakar_repo\temove-backend

# Activer l'environnement virtuel
.\venv\Scripts\activate.ps1
```

Si vous obtenez une erreur d'exécution de script PowerShell, exécutez d'abord :
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 2. Installer les dépendances

Une fois l'environnement virtuel activé (vous verrez `(venv)` dans le prompt), installez les packages :

```powershell
pip install pandas openpyxl reportlab
```

Ou installez toutes les dépendances du projet :

```powershell
pip install -r requirements.txt
```

### 3. Vérifier l'installation

```powershell
python -c "import pandas; import openpyxl; import reportlab; print('✅ Toutes les bibliothèques sont installées')"
```

### 4. Redémarrer le backend

Après l'installation, **redémarrez le serveur Flask** pour que les changements prennent effet :

```powershell
# Arrêter le serveur (Ctrl+C)
# Puis le redémarrer
python app.py
```

## 🔍 Vérification

### Vérifier quel Python est utilisé

```powershell
# Dans l'environnement virtuel
python --version
where python
```

### Vérifier où sont installés les packages

```powershell
pip show pandas
pip show openpyxl
pip show reportlab
```

Les packages doivent être installés dans :
```
C:\allo_dakar_repo\temove-backend\venv\Lib\site-packages\
```

## ⚠️ Problème d'espace disque

Si vous obtenez l'erreur `No space left on device` :

1. **Vérifier l'espace disque disponible** :
   ```powershell
   Get-PSDrive C | Select-Object Used,Free
   ```

2. **Nettoyer l'espace disque** :
   - Supprimer les fichiers temporaires
   - Nettoyer le cache pip : `pip cache purge`
   - Supprimer les anciens packages non utilisés

3. **Installer les packages un par un** :
   ```powershell
   pip install pandas
   pip install openpyxl
   pip install reportlab
   ```

## 🔄 Alternative : Installation minimale

Si l'espace disque est vraiment limité, vous pouvez installer uniquement ce dont vous avez besoin :

```powershell
# Pour Excel uniquement
pip install pandas openpyxl

# Pour PDF uniquement
pip install reportlab
```

## 📝 Notes

- **Assurez-vous toujours d'activer l'environnement virtuel** avant d'installer des packages
- Les packages doivent être installés dans le **même environnement virtuel** que Flask
- Après l'installation, **redémarrez toujours le serveur Flask**

## 🚀 Script PowerShell d'installation automatique

Créez un fichier `install_report_dependencies.ps1` :

```powershell
# Activer l'environnement virtuel
.\venv\Scripts\activate.ps1

# Installer les dépendances
pip install pandas openpyxl reportlab

# Vérifier l'installation
python -c "import pandas; import openpyxl; import reportlab; print('✅ Installation réussie')"
```

Exécutez-le avec :
```powershell
.\install_report_dependencies.ps1
```

---

**Document créé le** : 2025-11-08  
**Dernière mise à jour** : 2025-11-08

