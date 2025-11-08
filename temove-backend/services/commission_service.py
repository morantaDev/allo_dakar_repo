"""
Service de calcul de commission pour TeMove
"""
from datetime import datetime
from typing import Dict, Optional


class CommissionService:
    """Service pour calculer les commissions sur les courses"""
    
    # Taux de commission par défaut selon le type de course
    COMMISSION_RATES = {
        'eco': 0.15,  # 15%
        'confort': 0.18,  # 18%
        'confortPlus': 0.20,  # 20%
        'partageTaxi': 0.15,  # 15%
        'famille': 0.20,  # 20%
        'premium': 0.25,  # 25%
        # Livraisons
        'tiakTiak': 0.20,  # 20%
        'voiture': 0.22,  # 22%
        'express': 0.25,  # 25%
    }
    
    # Taux de commission pour tarification dynamique (surge pricing)
    SURGE_COMMISSION_RATE = 0.40  # 40% de la surcharge
    
    # Frais de service fixes
    SERVICE_FEE = 300  # XOF par course
    
    def __init__(self):
        pass
    
    def calculate_commission(self, ride_price: int, ride_mode: str, 
                            surge_multiplier: float = 1.0,
                            is_premium_user: bool = False,
                            driver_subscription: str = 'basic') -> Dict[str, int]:
        """
        Calculer la commission sur une course
        
        Args:
            ride_price: Prix total de la course (XOF)
            ride_mode: Mode de transport (eco, confort, etc.)
            surge_multiplier: Multiplicateur de tarification dynamique
            is_premium_user: Si l'utilisateur a un abonnement premium
            driver_subscription: Type d'abonnement du conducteur (basic, premium, enterprise)
        
        Returns:
            Dict avec:
                - platform_commission: Commission de la plateforme (XOF)
                - driver_earnings: Revenus du conducteur (XOF)
                - service_fee: Frais de service (XOF)
                - commission_rate: Taux de commission (%)
        """
        # Obtenir le taux de commission de base
        base_commission_rate = self.COMMISSION_RATES.get(ride_mode, 0.18)
        
        # Ajuster selon l'abonnement du conducteur
        if driver_subscription == 'premium':
            base_commission_rate -= 0.03  # -3% pour premium
        elif driver_subscription == 'enterprise':
            base_commission_rate -= 0.05  # -5% pour enterprise
        
        # Calculer le prix de base (sans surge)
        base_price = ride_price / surge_multiplier if surge_multiplier > 1.0 else ride_price
        
        # Commission sur le prix de base
        base_commission = int(base_price * base_commission_rate)
        
        # Calculer la surcharge (si surge pricing)
        surge_amount = ride_price - base_price if surge_multiplier > 1.0 else 0
        
        # Commission sur la surcharge (40% pour la plateforme)
        surge_commission = int(surge_amount * self.SURGE_COMMISSION_RATE) if surge_amount > 0 else 0
        
        # Commission totale
        total_commission = base_commission + surge_commission
        
        # Frais de service (non inclus dans la commission)
        service_fee = self.SERVICE_FEE if not is_premium_user else 0
        
        # Revenus du conducteur
        driver_earnings = ride_price - total_commission - service_fee
        
        # Taux de commission effectif
        effective_commission_rate = (total_commission / ride_price) * 100 if ride_price > 0 else 0
        
        return {
            'platform_commission': total_commission,
            'driver_earnings': driver_earnings,
            'service_fee': service_fee,
            'commission_rate': round(effective_commission_rate, 2),
            'base_commission': base_commission,
            'surge_commission': surge_commission,
            'base_price': int(base_price),
            'surge_amount': int(surge_amount),
        }
    
    def calculate_referral_reward(self, ride_price: int, 
                                  referrer_type: str = 'user') -> int:
        """
        Calculer la récompense de parrainage
        
        Args:
            ride_price: Prix de la course
            referrer_type: Type de référent (user ou driver)
        
        Returns:
            Montant de la récompense (XOF)
        """
        if referrer_type == 'user':
            # Récompense utilisateur : 1000 XOF fixe ou 5% du prix
            return max(1000, int(ride_price * 0.05))
        else:  # driver
            # Récompense conducteur : 2000 XOF fixe ou 10% du prix
            return max(2000, int(ride_price * 0.10))
    
    def calculate_premium_subscription_revenue(self, 
                                              subscription_type: str,
                                              user_id: int) -> Dict[str, int]:
        """
        Calculer les revenus d'un abonnement premium
        
        Args:
            subscription_type: Type d'abonnement (premium, business, family)
            user_id: ID de l'utilisateur
        
        Returns:
            Dict avec les revenus et avantages
        """
        subscription_prices = {
            'premium': 3000,  # XOF/mois
            'business': 50000,  # XOF/mois
            'family': 3000,  # XOF/mois
        }
        
        subscription_discounts = {
            'premium': 0.08,  # 8% de réduction
            'business': 0.15,  # 15% de réduction
            'family': 0.08,  # 8% de réduction
        }
        
        monthly_price = subscription_prices.get(subscription_type, 0)
        discount_rate = subscription_discounts.get(subscription_type, 0)
        
        return {
            'monthly_price': monthly_price,
            'discount_rate': discount_rate,
            'annual_revenue': monthly_price * 12,
        }
    
    def calculate_driver_subscription_revenue(self,
                                             subscription_type: str,
                                             rides_count: int,
                                             total_earnings: int) -> Dict[str, int]:
        """
        Calculer les revenus d'un abonnement conducteur
        
        Args:
            subscription_type: Type d'abonnement (basic, premium, enterprise)
            rides_count: Nombre de courses effectuées
            total_earnings: Revenus totaux du conducteur
        
        Returns:
            Dict avec les revenus et économies
        """
        subscription_prices = {
            'basic': 3000,  # XOF/mois
            'premium': 8000,  # XOF/mois
            'enterprise': 15000,  # XOF/mois
        }
        
        commission_reductions = {
            'basic': 0.00,  # Pas de réduction
            'premium': 0.03,  # -3% de commission
            'enterprise': 0.05,  # -5% de commission
        }
        
        monthly_price = subscription_prices.get(subscription_type, 0)
        commission_reduction = commission_reductions.get(subscription_type, 0)
        
        # Calculer les économies (commission réduite sur les revenus)
        savings = int(total_earnings * commission_reduction) if commission_reduction > 0 else 0
        
        return {
            'monthly_price': monthly_price,
            'commission_reduction': commission_reduction,
            'estimated_savings': savings,
            'net_benefit': savings - monthly_price,  # Bénéfice net après abonnement
        }
    
    def calculate_delivery_commission(self, delivery_price: int,
                                     delivery_mode: str) -> Dict[str, int]:
        """
        Calculer la commission sur une livraison
        
        Args:
            delivery_price: Prix de la livraison (XOF)
            delivery_mode: Mode de livraison (tiakTiak, voiture, express)
        
        Returns:
            Dict avec commission et revenus
        """
        commission_rate = self.COMMISSION_RATES.get(delivery_mode, 0.20)
        commission = int(delivery_price * commission_rate)
        
        return {
            'platform_commission': commission,
            'driver_earnings': delivery_price - commission,
            'commission_rate': commission_rate * 100,
        }
    
    def get_monthly_revenue_projection(self, 
                                      rides_count: int,
                                      avg_ride_price: int,
                                      premium_users: int = 0,
                                      driver_subscriptions: Dict[str, int] = None) -> Dict[str, int]:
        """
        Projeter les revenus mensuels
        
        Args:
            rides_count: Nombre de courses/mois
            avg_ride_price: Prix moyen d'une course (XOF)
            premium_users: Nombre d'utilisateurs premium
            driver_subscriptions: Dict avec {type: count} des abonnements conducteurs
        
        Returns:
            Dict avec projection des revenus
        """
        if driver_subscriptions is None:
            driver_subscriptions = {'basic': 0, 'premium': 0, 'enterprise': 0}
        
        # Revenus des commissions (moyenne)
        total_ride_revenue = rides_count * avg_ride_price
        avg_commission_rate = 0.18  # 18% en moyenne
        commission_revenue = int(total_ride_revenue * avg_commission_rate)
        
        # Revenus des abonnements utilisateurs
        premium_revenue = premium_users * 3000  # 3000 XOF/abonnement
        
        # Revenus des abonnements conducteurs
        driver_sub_revenue = (
            driver_subscriptions.get('basic', 0) * 3000 +
            driver_subscriptions.get('premium', 0) * 8000 +
            driver_subscriptions.get('enterprise', 0) * 15000
        )
        
        # Frais de service
        service_fees = rides_count * self.SERVICE_FEE
        
        # Total
        total_revenue = commission_revenue + premium_revenue + driver_sub_revenue + service_fees
        
        return {
            'commission_revenue': commission_revenue,
            'premium_revenue': premium_revenue,
            'driver_subscription_revenue': driver_sub_revenue,
            'service_fees': service_fees,
            'total_revenue': total_revenue,
            'rides_count': rides_count,
            'avg_ride_price': avg_ride_price,
        }

