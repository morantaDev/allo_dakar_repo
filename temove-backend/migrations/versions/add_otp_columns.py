"""Add OTP columns: method, is_used, verified_at

Revision ID: add_otp_columns
Revises: 5034cf32b0a8
Create Date: 2025-11-09 05:10:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'add_otp_columns'
down_revision: Union[str, Sequence[str], None] = '5034cf32b0a8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema - Add missing OTP columns."""
    # Vérifier et ajouter la colonne method si elle n'existe pas
    try:
        op.add_column('otps', sa.Column('method', sa.String(length=10), nullable=False, server_default='SMS'))
    except Exception:
        # La colonne existe peut-être déjà, on vérifie avec une requête SQL brute
        from sqlalchemy import inspect
        conn = op.get_bind()
        inspector = inspect(conn)
        columns = [col['name'] for col in inspector.get_columns('otps')]
        if 'method' not in columns:
            op.execute("ALTER TABLE otps ADD COLUMN method VARCHAR(10) NOT NULL DEFAULT 'SMS'")
    
    # Vérifier et ajouter la colonne is_used si elle n'existe pas
    try:
        op.add_column('otps', sa.Column('is_used', sa.Boolean(), nullable=False, server_default='0'))
    except Exception:
        from sqlalchemy import inspect
        conn = op.get_bind()
        inspector = inspect(conn)
        columns = [col['name'] for col in inspector.get_columns('otps')]
        if 'is_used' not in columns:
            op.execute("ALTER TABLE otps ADD COLUMN is_used BOOLEAN NOT NULL DEFAULT 0")
    
    # Vérifier et ajouter la colonne verified_at si elle n'existe pas
    try:
        op.add_column('otps', sa.Column('verified_at', sa.DateTime(), nullable=True))
    except Exception:
        from sqlalchemy import inspect
        conn = op.get_bind()
        inspector = inspect(conn)
        columns = [col['name'] for col in inspector.get_columns('otps')]
        if 'verified_at' not in columns:
            op.execute("ALTER TABLE otps ADD COLUMN verified_at DATETIME NULL")
    
    # Rendre user_id nullable (pour permettre les nouveaux utilisateurs)
    # Note: On vérifie d'abord si la colonne existe et si elle est nullable
    try:
        from sqlalchemy import inspect
        conn = op.get_bind()
        inspector = inspect(conn)
        columns = inspector.get_columns('otps')
        user_id_col = next((col for col in columns if col['name'] == 'user_id'), None)
        if user_id_col and not user_id_col.get('nullable', False):
            op.alter_column('otps', 'user_id',
                           existing_type=sa.Integer(),
                           nullable=True)
    except Exception:
        pass


def downgrade() -> None:
    """Downgrade schema - Remove OTP columns."""
    # Supprimer les colonnes ajoutées
    try:
        op.drop_column('otps', 'verified_at')
    except Exception:
        pass
    
    try:
        op.drop_column('otps', 'is_used')
    except Exception:
        pass
    
    try:
        op.drop_column('otps', 'method')
    except Exception:
        pass

