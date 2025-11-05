"""
Script pour visualiser les données dans la base de données SQLite
"""
import sqlite3
import os
from datetime import datetime

# Chemin de la base de données - vérifier plusieurs emplacements
possible_paths = [
    'allo_dakar.db',  # Racine (selon .env)
    os.path.join('instance', 'allo_dakar.db'),  # Dossier instance
]

db_path = None
for path in possible_paths:
    if os.path.exists(path):
        db_path = path
        break

if not db_path:
    print(f"❌ Base de données non trouvée dans: {possible_paths}")
    exit(1)

if not os.path.exists(db_path):
    print(f"❌ Base de données non trouvée: {db_path}")
    exit(1)

conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row  # Pour accéder aux colonnes par nom
cur = conn.cursor()

print("\n" + "="*80)
print("📊 DONNÉES DANS LA BASE DE DONNÉES")
print("="*80)

# Utilisateurs
print("\n👥 UTILISATEURS:")
print("-" * 80)
cur.execute("SELECT * FROM users")
users = cur.fetchall()
if users:
    for user in users:
        print(f"  ID: {user['id']}")
        print(f"  📧 Email: {user['email']}")
        print(f"  👤 Nom: {user['full_name']}")
        print(f"  📱 Téléphone: {user['phone'] or 'Non renseigné'}")
        print(f"  💰 Crédit: {user['credit_balance']} XOF")
        print(f"  ✅ Actif: {'Oui' if user['is_active'] else 'Non'}")
        print(f"  📅 Créé le: {user['created_at']}")
        print()
else:
    print("  ❌ Aucun utilisateur")

# Codes de parrainage
print("\n🎁 CODES DE PARRAINAGE:")
print("-" * 80)
cur.execute("SELECT * FROM referral_codes")
referrals = cur.fetchall()
if referrals:
    for ref in referrals:
        print(f"  Code: {ref['code']}")
        print(f"  User ID: {ref['user_id']}")
        print(f"  Utilisations: {ref['uses']}/{ref['max_uses'] or '∞'}")
        print(f"  Crédit: {ref['credit_amount']} XOF")
        print()
else:
    print("  ❌ Aucun code de parrainage")

# Points de fidélité
print("\n⭐ POINTS DE FIDÉLITÉ:")
print("-" * 80)
cur.execute("SELECT * FROM loyalty_points")
loyalty = cur.fetchall()
if loyalty:
    for loy in loyalty:
        print(f"  User ID: {loy['user_id']}")
        print(f"  Points: {loy['points']}")
        print(f"  Niveau: {loy['level']}")
        print(f"  Courses totales: {loy['total_rides']}")
        print()
else:
    print("  ❌ Aucun point de fidélité")

# Courses
print("\n🚗 COURSES:")
print("-" * 80)
cur.execute("SELECT * FROM rides ORDER BY requested_at DESC LIMIT 10")
rides = cur.fetchall()
if rides:
    for ride in rides:
        print(f"  ID: {ride['id']}")
        print(f"  User ID: {ride['user_id']}")
        print(f"  Statut: {ride['status']}")
        print(f"  Prix: {ride['final_price']} XOF")
        if ride['scheduled_at']:
            print(f"  📅 Programmée pour: {ride['scheduled_at']}")
        print(f"  Créée le: {ride['requested_at']}")
        print()
else:
    print("  ❌ Aucune course")

# Statistiques
print("\n📈 STATISTIQUES:")
print("-" * 80)
cur.execute("SELECT COUNT(*) as total FROM users")
total_users = cur.fetchone()['total']
print(f"  Total utilisateurs: {total_users}")

cur.execute("SELECT COUNT(*) as total FROM rides")
total_rides = cur.fetchone()['total']
print(f"  Total courses: {total_rides}")

cur.execute("SELECT COUNT(*) as total FROM referral_codes")
total_codes = cur.fetchone()['total']
print(f"  Total codes de parrainage: {total_codes}")

print("\n" + "="*80)
print(f"📍 Base de données: {os.path.abspath(db_path)}")
print("="*80 + "\n")

conn.close()

