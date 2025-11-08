"""
Service de génération de rapports pour l'administration
Génère des fichiers Excel et PDF pour différents types de rapports

IMPORTANT: Les fichiers sont générés SUR LE SERVEUR dans le répertoire 'reports/'
puis renvoyés au client pour téléchargement. Les fichiers sont créés temporairement
sur la machine hôte et peuvent être supprimés après téléchargement.
"""
import os
from datetime import datetime
from typing import Dict, List, Optional
import json

try:
    import pandas as pd
    PANDAS_AVAILABLE = True
except ImportError:
    PANDAS_AVAILABLE = False

try:
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import A4
    from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.units import inch
    REPORTLAB_AVAILABLE = True
except ImportError:
    REPORTLAB_AVAILABLE = False


class ReportService:
    """Service pour générer des rapports Excel et PDF"""
    
    # Répertoire de stockage des rapports
    REPORTS_DIR = 'reports'
    
    @staticmethod
    def ensure_reports_dir():
        """Créer le répertoire reports s'il n'existe pas"""
        try:
            if not os.path.exists(ReportService.REPORTS_DIR):
                os.makedirs(ReportService.REPORTS_DIR)
                print(f"Répertoire {ReportService.REPORTS_DIR} créé")
        except Exception as e:
            print(f"Erreur lors de la création du répertoire reports: {e}")
    
    @staticmethod
    def generate_excel_report(
        report_type: str,
        data: List[Dict],
        start_date: datetime,
        end_date: datetime,
        filename: Optional[str] = None
    ) -> str:
        """
        Générer un rapport Excel
        
        Args:
            report_type: Type de rapport (revenue, rides, drivers, users, commissions, payments)
            data: Liste de dictionnaires contenant les données
            start_date: Date de début
            end_date: Date de fin
            filename: Nom de fichier (optionnel)
        
        Returns:
            Chemin du fichier généré
        """
        # Vérifier et importer pandas
        try:
            import pandas as pd
        except ImportError:
            raise Exception(
                "❌ pandas n'est pas installé dans l'environnement virtuel actuel.\n"
                "📦 Pour installer:\n"
                "   1. Activez l'environnement virtuel: .\\venv\\Scripts\\activate.ps1\n"
                "   2. Installez les packages: pip install pandas openpyxl\n"
                "   3. Redémarrez le serveur Flask"
            )
        
        ReportService.ensure_reports_dir()
        
        # Créer un DataFrame à partir des données
        if not data:
            df = pd.DataFrame({'Message': ['Aucune donnée disponible pour cette période']})
        else:
            df = pd.DataFrame(data)
        
        # Générer le nom de fichier
        if not filename:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            filename = f"{report_type}_{start_date.strftime('%Y%m%d')}_{end_date.strftime('%Y%m%d')}_{timestamp}.xlsx"
        
        filepath = os.path.join(ReportService.REPORTS_DIR, filename)
        
        # Vérifier et importer openpyxl pour Excel
        try:
            import openpyxl
        except ImportError:
            raise Exception(
                "❌ openpyxl n'est pas installé dans l'environnement virtuel actuel.\n"
                "📦 Pour installer:\n"
                "   1. Activez l'environnement virtuel: .\\venv\\Scripts\\activate.ps1\n"
                "   2. Installez le package: pip install openpyxl\n"
                "   3. Redémarrez le serveur Flask"
            )
        
        # Créer un writer Excel avec formatage
        with pd.ExcelWriter(filepath, engine='openpyxl') as writer:
            df.to_excel(writer, sheet_name='Données', index=False)
            
            # Obtenir la feuille de travail pour le formatage
            worksheet = writer.sheets['Données']
            
            # Ajuster la largeur des colonnes
            for idx, col in enumerate(df.columns):
                try:
                    max_length = max(
                        df[col].astype(str).map(len).max(),
                        len(str(col))
                    )
                    # Convertir l'index en lettre de colonne Excel (A, B, C, ...)
                    if idx < 26:
                        col_letter = chr(65 + idx)  # A-Z
                    else:
                        col_letter = chr(64 + idx // 26) + chr(65 + idx % 26)  # AA, AB, ...
                    worksheet.column_dimensions[col_letter].width = min(max_length + 2, 50)
                except:
                    pass
        
        print(f"Rapport Excel généré: {filepath}")
        return filepath
    
    @staticmethod
    def generate_pdf_report(
        report_type: str,
        data: List[Dict],
        start_date: datetime,
        end_date: datetime,
        title: str,
        filename: Optional[str] = None
    ) -> str:
        """
        Générer un rapport PDF
        
        Args:
            report_type: Type de rapport
            data: Liste de dictionnaires contenant les données
            start_date: Date de début
            end_date: Date de fin
            title: Titre du rapport
            filename: Nom de fichier (optionnel)
        
        Returns:
            Chemin du fichier généré
        """
        # Vérifier et importer reportlab
        try:
            from reportlab.lib import colors
            from reportlab.lib.pagesizes import A4
            from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
            from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
            from reportlab.lib.units import inch
        except ImportError:
            raise Exception(
                "❌ reportlab n'est pas installé dans l'environnement virtuel actuel.\n"
                "📦 Pour installer:\n"
                "   1. Activez l'environnement virtuel: .\\venv\\Scripts\\activate.ps1\n"
                "   2. Installez le package: pip install reportlab\n"
                "   3. Redémarrez le serveur Flask"
            )
        
        ReportService.ensure_reports_dir()
        
        # Générer le nom de fichier
        if not filename:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            filename = f"{report_type}_{start_date.strftime('%Y%m%d')}_{end_date.strftime('%Y%m%d')}_{timestamp}.pdf"
        
        filepath = os.path.join(ReportService.REPORTS_DIR, filename)
        
        # Créer le document PDF
        doc = SimpleDocTemplate(filepath, pagesize=A4)
        elements = []
        
        # Styles
        styles = getSampleStyleSheet()
        title_style = ParagraphStyle(
            'CustomTitle',
            parent=styles['Heading1'],
            fontSize=18,
            textColor=colors.HexColor('#FFC800'),  # Couleur TéMove
            spaceAfter=30,
            alignment=1  # Centré
        )
        
        # Titre
        elements.append(Paragraph(title, title_style))
        elements.append(Spacer(1, 0.2*inch))
        
        # Informations de période
        period_text = f"Période: {start_date.strftime('%d/%m/%Y')} - {end_date.strftime('%d/%m/%Y')}"
        elements.append(Paragraph(period_text, styles['Normal']))
        elements.append(Spacer(1, 0.2*inch))
        
        # Générer la date de génération
        generated_text = f"Généré le: {datetime.now().strftime('%d/%m/%Y à %H:%M')}"
        elements.append(Paragraph(generated_text, styles['Normal']))
        elements.append(Spacer(1, 0.3*inch))
        
        # Tableau de données
        if data:
            # Préparer les données pour le tableau
            table_data = []
            
            # En-têtes
            if data:
                headers = list(data[0].keys())
                # Formater les en-têtes
                formatted_headers = [str(h).replace('_', ' ').title() for h in headers]
                table_data.append(formatted_headers)
                
                # Données
                for row in data:
                    formatted_row = []
                    for header in headers:
                        value = row.get(header, '')
                        # Formater les valeurs
                        if isinstance(value, (int, float)):
                            if 'price' in str(header).lower() or 'amount' in str(header).lower() or 'commission' in str(header).lower():
                                formatted_row.append(f"{value:,.0f} XOF")
                            else:
                                formatted_row.append(str(value))
                        elif isinstance(value, datetime):
                            formatted_row.append(value.strftime('%d/%m/%Y %H:%M'))
                        elif isinstance(value, dict):
                            formatted_row.append(json.dumps(value, ensure_ascii=False))
                        else:
                            formatted_row.append(str(value))
                    table_data.append(formatted_row)
            
            # Créer le tableau
            table = Table(table_data)
            
            # Style du tableau
            table.setStyle(TableStyle([
                # En-têtes
                ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#FFC800')),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (-1, 0), 10),
                ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                ('TOPPADDING', (0, 0), (-1, 0), 12),
                # Données
                ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
                ('TEXTCOLOR', (0, 1), (-1, -1), colors.black),
                ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
                ('FONTSIZE', (0, 1), (-1, -1), 8),
                ('GRID', (0, 0), (-1, -1), 1, colors.black),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ]))
            
            elements.append(table)
        else:
            elements.append(Paragraph("Aucune donnée disponible pour cette période", styles['Normal']))
        
        # Générer le PDF
        doc.build(elements)
        
        print(f"Rapport PDF généré: {filepath}")
        return filepath
    
    @staticmethod
    def prepare_revenue_data(revenue_data: List[Dict]) -> List[Dict]:
        """Préparer les données de revenus pour le rapport"""
        prepared_data = []
        for item in revenue_data:
            prepared_data.append({
                'Date': item.get('date', ''),
                'Revenus (XOF)': item.get('amount', 0),
                'Nombre de courses': item.get('ride_count', 0),
            })
        return prepared_data
    
    @staticmethod
    def prepare_rides_data(rides_data: List[Dict]) -> List[Dict]:
        """Préparer les données de courses pour le rapport"""
        prepared_data = []
        for ride in rides_data:
            prepared_data.append({
                'ID': ride.get('id', ''),
                'Client': ride.get('user', {}).get('full_name', '') if isinstance(ride.get('user'), dict) else '',
                'Chauffeur': ride.get('driver', {}).get('full_name', '') if isinstance(ride.get('driver'), dict) else '',
                'Départ': ride.get('pickup_address', ''),
                'Destination': ride.get('dropoff_address', ''),
                'Distance (km)': ride.get('distance_km', 0),
                'Prix (XOF)': ride.get('final_price', 0),
                'Statut': ride.get('status', ''),
                'Date': ride.get('requested_at', ''),
            })
        return prepared_data
    
    @staticmethod
    def prepare_drivers_data(drivers_data: List[Dict]) -> List[Dict]:
        """Préparer les données de conducteurs pour le rapport"""
        prepared_data = []
        for driver in drivers_data:
            prepared_data.append({
                'ID': driver.get('id', ''),
                'Nom': driver.get('full_name', ''),
                'Email': driver.get('email', ''),
                'Téléphone': driver.get('phone', ''),
                'Plaque': driver.get('license_plate', ''),
                'Véhicule': f"{driver.get('car_make', '')} {driver.get('car_model', '')}".strip(),
                'Note': driver.get('rating_average', 0),
                'Courses': driver.get('total_rides', 0),
                'Statut': driver.get('status', ''),
            })
        return prepared_data
    
    @staticmethod
    def prepare_users_data(users_data: List[Dict]) -> List[Dict]:
        """Préparer les données d'utilisateurs pour le rapport"""
        prepared_data = []
        for user in users_data:
            prepared_data.append({
                'ID': user.get('id', ''),
                'Nom': user.get('full_name', ''),
                'Email': user.get('email', ''),
                'Téléphone': user.get('phone', ''),
                'Courses': user.get('total_rides', 0),
                'Statut': 'Actif' if user.get('is_active', False) else 'Inactif',
                'Date d\'inscription': user.get('created_at', ''),
            })
        return prepared_data
    
    @staticmethod
    def prepare_commissions_data(commissions_data: List[Dict]) -> List[Dict]:
        """Préparer les données de commissions pour le rapport"""
        prepared_data = []
        for commission in commissions_data:
            prepared_data.append({
                'ID': commission.get('id', ''),
                'Chauffeur': commission.get('driver', {}).get('full_name', '') if isinstance(commission.get('driver'), dict) else '',
                'Course ID': commission.get('ride_id', ''),
                'Prix course (XOF)': commission.get('ride_price', 0),
                'Commission (XOF)': commission.get('platform_commission', 0),
                'Taux (%)': commission.get('commission_rate', 0),
                'Statut': commission.get('status', ''),
                'Date': commission.get('created_at', ''),
                'Payée le': commission.get('paid_at', ''),
            })
        return prepared_data
    
    @staticmethod
    def prepare_payments_data(payments_data: List[Dict]) -> List[Dict]:
        """Préparer les données de paiements pour le rapport"""
        prepared_data = []
        for payment in payments_data:
            prepared_data.append({
                'ID': payment.get('id', ''),
                'Course ID': payment.get('ride_id', ''),
                'Montant (XOF)': payment.get('amount', 0),
                'Méthode': payment.get('method', ''),
                'Statut': payment.get('status', ''),
                'Date': payment.get('created_at', ''),
            })
        return prepared_data

