"""
Script de démarrage simplifié
"""
import importlib.util
import sys
import os
import argparse

# Charger app.py directement depuis le fichier (pas le module app/)
spec = importlib.util.spec_from_file_location("app_module", "app.py")
app_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(app_module)

if __name__ == '__main__':
    # Parser les arguments de ligne de commande
    parser = argparse.ArgumentParser(description='Démarrer le serveur Flask TeMove')
    parser.add_argument('--host', type=str, default=None, 
                       help='Adresse IP pour écouter (défaut: 0.0.0.0 depuis variable d\'environnement ou 0.0.0.0)')
    parser.add_argument('--port', type=int, default=None,
                       help='Port pour écouter (défaut: 5000 depuis variable d\'environnement PORT ou 5000)')
    parser.add_argument('--env', type=str, default=None,
                       help='Environnement (development, production, testing)')
    
    args = parser.parse_args()
    
    # Déterminer l'environnement
    env = args.env or os.environ.get('FLASK_ENV', 'development')
    
    # Convertir en nom de configuration valide
    config_name = env if env in ['development', 'production', 'testing', 'default'] else 'development'
    
    # Déterminer l'hôte et le port
    host = args.host or os.environ.get('HOST', '0.0.0.0')
    port = args.port or int(os.environ.get('PORT', 5000))
    
    app = app_module.create_app(config_name)
    
    print(f"🚀 Démarrage du serveur Flask TeMove")
    print(f"📍 Environnement: {config_name}")
    print(f"🌐 Host: {host}")
    print(f"🔌 Port: {port}")
    print(f"🔗 URL: http://{host}:{port}")
    print(f"🔗 API: http://{host}:{port}/api/v1")
    print(f"💚 Health: http://{host}:{port}/health")
    print("")
    
    app.run(
        debug=(config_name == 'development'),
        host=host,
        port=port
    )
