#!/usr/bin/env python3
"""
Script pour générer les favicons à partir du logo de l'application
"""
import os
import sys
from PIL import Image

def generate_favicon():
    """Générer les favicons à partir du logo de l'application"""
    
    # Chemins
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    logo_path = os.path.join(project_root, 'assets', 'icons', 'app_logo.png')
    web_dir = os.path.join(project_root, 'web')
    favicon_png_path = os.path.join(web_dir, 'favicon.png')
    favicon_svg_path = os.path.join(web_dir, 'favicon.svg')
    
    # Vérifier que le logo existe
    if not os.path.exists(logo_path):
        print(f"❌ Logo non trouvé : {logo_path}")
        return False
    
    try:
        # Charger le logo
        print(f"📷 Chargement du logo depuis : {logo_path}")
        logo = Image.open(logo_path)
        
        # Convertir en RGBA si nécessaire
        if logo.mode != 'RGBA':
            logo = logo.convert('RGBA')
        
        # Créer le favicon PNG (32x32)
        print("🔄 Création du favicon.png (32x32)...")
        favicon_png = logo.resize((32, 32), Image.Resampling.LANCZOS)
        favicon_png.save(favicon_png_path, 'PNG')
        print(f"✅ Favicon PNG créé : {favicon_png_path}")
        
        # Créer aussi un favicon 16x16 pour compatibilité
        favicon_16 = logo.resize((16, 16), Image.Resampling.LANCZOS)
        # On peut sauvegarder un 16x16 séparé si nécessaire, mais généralement 32x32 suffit
        
        # Créer un favicon SVG simple (basé sur le PNG)
        # Note: Pour un vrai SVG, il faudrait vectoriser l'image, ce qui est complexe
        # On va créer un SVG simple qui référence le PNG
        print("🔄 Création du favicon.svg...")
        svg_content = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <image href="favicon.png" width="32" height="32"/>
</svg>'''
        
        with open(favicon_svg_path, 'w', encoding='utf-8') as f:
            f.write(svg_content)
        print(f"✅ Favicon SVG créé : {favicon_svg_path}")
        
        print("\n✅ Favicons générés avec succès!")
        print(f"   - PNG: {favicon_png_path}")
        print(f"   - SVG: {favicon_svg_path}")
        
        return True
        
    except Exception as e:
        print(f"❌ Erreur lors de la génération des favicons: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == '__main__':
    print("🎨 Génération des favicons TeMove...\n")
    success = generate_favicon()
    sys.exit(0 if success else 1)

