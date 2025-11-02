/// Support multi-langues pour Allo Dakar
enum AppLanguage { french, wolof, pular, diola }

extension AppLanguageExtension on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.french:
        return 'fr';
      case AppLanguage.wolof:
        return 'wo';
      case AppLanguage.pular:
        return 'fuc';
      case AppLanguage.diola:
        return 'dyo';
    }
  }

  String get displayName {
    switch (this) {
      case AppLanguage.french:
        return 'Français';
      case AppLanguage.wolof:
        return 'Wolof';
      case AppLanguage.pular:
        return 'Pular';
      case AppLanguage.diola:
        return 'Diola';
    }
  }

  String get nativeName {
    switch (this) {
      case AppLanguage.french:
        return 'Français';
      case AppLanguage.wolof:
        return 'Wolof';
      case AppLanguage.pular:
        return 'Pular';
      case AppLanguage.diola:
        return 'Joola';
    }
  }
}

/// Traductions simples pour les principales phrases
class Translations {
  static Map<String, Map<AppLanguage, String>> get translations => {
    'app_name': {
      AppLanguage.french: 'Allo Dakar',
      AppLanguage.wolof: 'Allo Dakar',
      AppLanguage.pular: 'Allo Dakar',
      AppLanguage.diola: 'Allo Dakar',
    },
    'book_ride': {
      AppLanguage.french: 'Réserver un trajet',
      AppLanguage.wolof: 'Bookal jënd',
      AppLanguage.pular: 'Seeda gila',
      AppLanguage.diola: 'Kuremba ne',
    },
    'where_going': {
      AppLanguage.french: 'Où allez-vous ?',
      AppLanguage.wolof: 'Fan nga dem ?',
      AppLanguage.pular: 'Honte on waali ?',
      AppLanguage.diola: 'Aan jët ?',
    },
    'confirm_ride': {
      AppLanguage.french: 'Confirmer la course',
      AppLanguage.wolof: 'Jëkkal jënd bi',
      AppLanguage.pular: 'Fedde gila',
      AppLanguage.diola: 'Kuremba ne',
    },
    'payment_method': {
      AppLanguage.french: 'Méthode de paiement',
      AppLanguage.wolof: 'Jëfandikukug jëfandikukug',
      AppLanguage.pular: 'Njeegol jokkondiral',
      AppLanguage.diola: 'Kuuy njaal',
    },
  };

  static String translate(String key, AppLanguage language) {
    return translations[key]?[language] ?? key;
  }
}

