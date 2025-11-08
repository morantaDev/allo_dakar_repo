# 🔧 Résolution : Erreur "pandas/reportlab n'est pas installé"

## 📋 Problème

Lors de la génération d'un rapport, vous obtenez l'erreur :
```
Exception: pandas n'est pas installé. Installez-le avec: pip install pandas openpyxl
```
ou
```
Exception: reportlab n'est pas installé. Installez-le avec: pip install reportlab
```

## 🔍 Diagnostic

Cette erreur indique que les bibliothèques ne sont **pas installées dans l'environnement virtuel** utilisé par le serveur Flask.

### Vérifier quel Python est utilisé

```powershell
# Dans le terminal où le backend tourne
python --version
where python
```

Le chemin devrait pointer vers :
```
C:\allo_dakar_repo\temove-backend\venv\Scripts\python.exe
```

## ✅ Solution Rapide

### Étape 1 : Arrêter le serveur Flask

Appuyez sur `Ctrl+C` dans le terminal où le serveur tourne.

### Étape 2 : Activer l'environnement virtuel

```powershell
cd C:\allo_dakar_repo\temove-backend
.\venv\Scripts\activate.ps1
```

**Si vous obtenez une erreur d'exécution de script**, exécutez d'abord :
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Étape 3 : Installer les dépendances

```powershell
# Vérifier que vous êtes dans le bon environnement (vous devriez voir (venv) dans le prompt)
pip install pandas openpyxl reportlab
```

### Étape 4 : Vérifier l'installation

```powershell
python -c "import pandas; import openpyxl; import reportlab; print('✅ Installation réussie')"
```

### Étape 5 : Redémarrer le serveur Flask

```powershell
python app.py
```

## 🚀 Script Automatique

Utilisez le script `install_report_dependencies.ps1` :

```powershell
cd C:\allo_dakar_repo\temove-backend
.\install_report_dependencies.ps1
```

## ⚠️ Problème d'espace disque

Si vous obtenez l'erreur `No space left on device` :

1. **Libérer de l'espace disque** :
   ```powershell
   # Nettoyer le cache pip
   pip cache purge
   
   # Supprimer les anciens packages
   pip list --outdated
   ```

2. **Installer les packages un par un** :
   ```powershell
   pip install pandas
   pip install openpyxl
   pip install reportlab
   ```

3. **Vérifier l'espace disque disponible** :
   ```powershell
   Get-PSDrive C | Select-Object Used,Free
   ```

## 🔄 Alternative : Installation minimale

Si l'espace disque est vraiment limité, vous pouvez installer uniquement ce dont vous avez besoin :

```powershell
# Pour Excel uniquement
pip install pandas openpyxl

# Pour PDF uniquement
pip install reportlab
```

## 📝 Vérification Finale

Après l'installation, testez la génération d'un rapport :

1. Connectez-vous en tant qu'admin
2. Allez dans **Rapports**
3. Sélectionnez un type de rapport
4. Choisissez une période
5. Sélectionnez le format (Excel ou PDF)
6. Cliquez sur **"Générer le rapport"**

Le fichier devrait être généré et téléchargé automatiquement.

## 🐛 Dépannage

### Les packages sont installés mais l'erreur persiste

1. **Vérifier que le serveur Flask utilise le bon Python** :
   - Arrêtez le serveur
   - Activez l'environnement virtuel
   - Redémarrez le serveur : `python app.py`

2. **Vérifier l'installation** :
   ```powershell
   python -c "import sys; print(sys.executable)"
   ```
   Le chemin devrait pointer vers `venv\Scripts\python.exe`

3. **Réinstaller les packages** :
   ```powershell
   pip uninstall pandas openpyxl reportlab
   pip install pandas openpyxl reportlab
   ```

### Le serveur ne trouve toujours pas les packages

Vérifiez que vous utilisez bien l'environnement virtuel du projet :

```powershell
# Vérifier le chemin de Python
python -c "import sys; print(sys.executable)"

# Devrait afficher quelque chose comme :
# C:\allo_dakar_repo\temove-backend\venv\Scripts\python.exe
```

Si ce n'est pas le cas, vous utilisez probablement un autre Python. Activez le bon environnement virtuel.

---

**Document créé le** : 2025-11-08  
**Dernière mise à jour** : 2025-11-08

