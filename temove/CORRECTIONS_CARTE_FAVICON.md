# 🔧 Corrections Carte et Favicon

## ✅ Corrections apportées

### 1. **Favicon TeMove**
- ✅ Ajout de plusieurs formats de favicon dans `web/index.html`
- ✅ Le favicon SVG devrait maintenant s'afficher correctement
- ✅ Si le SVG ne fonctionne pas, le navigateur utilisera le PNG

**Pour forcer le rafraîchissement du favicon :**
- Chrome/Edge : `Ctrl + Shift + R` (hard refresh)
- Firefox : `Ctrl + F5`
- Ou vider le cache du navigateur

### 2. **Carte OpenStreetMap**
- ✅ Configuration améliorée avec subdomains pour meilleure compatibilité
- ✅ Ajout de contrôles de zoom (+ et -)
- ✅ Bouton pour recentrer sur votre position
- ✅ Gestion d'erreurs pour le chargement des tuiles

## 🗺️ Si la carte ne s'affiche toujours pas

### Vérifications :

1. **Connexion Internet** : Les tuiles OpenStreetMap nécessitent Internet
2. **Console du navigateur** : Ouvrez la console (F12) pour voir les erreurs
3. **Permissions réseau** : Le navigateur doit autoriser les requêtes réseau

### Alternative : Utiliser une autre source de tuiles

Si OpenStreetMap ne fonctionne pas, on peut utiliser :
- CartoDB (gratuit, compatible)
- Mapbox (nécessite une clé API gratuite)

## 📝 Commandes à exécuter

```bash
cd C:\allo_dakar_repo\allo-dakar-stitch-cursor
flutter pub get
flutter clean
flutter run -d chrome
```

## 🔍 Diagnostic

Si vous voyez seulement un point avec des coordonnées :
1. Ouvrez la console du navigateur (F12)
2. Regardez les erreurs réseau (onglet Network)
3. Vérifiez si les requêtes vers `tile.openstreetmap.org` fonctionnent

Si les tuiles ne chargent pas, cela peut être dû à :
- Restrictions CORS
- Blocage du navigateur
- Problème de connexion Internet

