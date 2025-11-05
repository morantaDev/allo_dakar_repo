import os
import sys
from dotenv import load_dotenv

# Ensure repo root is on sys.path so we can import project modules when run
# from the scripts/ folder.
ROOT = os.path.dirname(os.path.dirname(__file__))
sys.path.insert(0, ROOT)

load_dotenv()
import config
print('cwd:', os.getcwd())
print('DATABASE_URL from env:', os.environ.get('DATABASE_URL'))
print('config SQLALCHEMY_DATABASE_URI:', config.Config.SQLALCHEMY_DATABASE_URI if hasattr(config.Config,'SQLALCHEMY_DATABASE_URI') else config.config['development'].SQLALCHEMY_DATABASE_URI)

# If sqlite file path was relative, print absolute resolved path
db_uri = os.environ.get('DATABASE_URL') or config.Config.SQLALCHEMY_DATABASE_URI
if db_uri.startswith('sqlite:///'):
    path = db_uri.replace('sqlite:///', '')
    print('resolved sqlite path:', os.path.abspath(path))
    print('exists:', os.path.exists(os.path.abspath(path)))
else:
    print('DB is not sqlite, uri:', db_uri)
