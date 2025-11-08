/// Points de repère et destinations populaires à Dakar
class LocalLandmark {
  final String id;
  final String name;
  final String nameWolof;
  final String description;
  final double latitude;
  final double longitude;
  final LandmarkType type;
  final String? icon;

  LocalLandmark({
    required this.id,
    required this.name,
    required this.nameWolof,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.icon,
  });

  static final List<LocalLandmark> dakarLandmarks = [
    LocalLandmark(
      id: 'place_independence',
      name: 'Place de l\'Indépendance',
      nameWolof: 'Plaas ci Indépendance',
      description: 'Place centrale de Dakar',
      latitude: 14.6928,
      longitude: -17.4467,
      type: LandmarkType.place,
      icon: '🏛️',
    ),
    LocalLandmark(
      id: 'monument_renaissance',
      name: 'Monument de la Renaissance Africaine',
      nameWolof: 'Monument ci Renaissance',
      description: 'Monument emblématique',
      latitude: 14.7247,
      longitude: -17.5139,
      type: LandmarkType.monument,
      icon: '🗿',
    ),
    LocalLandmark(
      id: 'marche_sandaga',
      name: 'Marché Sandaga',
      nameWolof: 'Souukar Sandaga',
      description: 'Grand marché traditionnel',
      latitude: 14.6936,
      longitude: -17.4475,
      type: LandmarkType.market,
      icon: '🛒',
    ),
    LocalLandmark(
      id: 'plage_yoff',
      name: 'Plage de Yoff',
      nameWolof: 'Këyit ci Yoff',
      description: 'Plage populaire',
      latitude: 14.7592,
      longitude: -17.4603,
      type: LandmarkType.beach,
      icon: '🏖️',
    ),
    LocalLandmark(
      id: 'aeroport',
      name: 'Aéroport Blaise Diagne',
      nameWolof: 'Aéroport Blaise Diagne',
      description: 'Aéroport international',
      latitude: 14.6696,
      longitude: -17.0738,
      type: LandmarkType.airport,
      icon: '✈️',
    ),
    LocalLandmark(
      id: 'goree',
      name: 'Île de Gorée',
      nameWolof: 'Dunu Gorée',
      description: 'Île historique',
      latitude: 14.6698,
      longitude: -17.3983,
      type: LandmarkType.historical,
      icon: '🏝️',
    ),
    LocalLandmark(
      id: 'parcelles',
      name: 'Parcelles Assainies',
      nameWolof: 'Parcelles Assainies',
      description: 'Quartier populaire',
      latitude: 14.7531,
      longitude: -17.4569,
      type: LandmarkType.neighborhood,
      icon: '🏘️',
    ),
    LocalLandmark(
      id: 'grand_yoff',
      name: 'Grand Yoff',
      nameWolof: 'Grand Yoff',
      description: 'Quartier résidentiel',
      latitude: 14.7592,
      longitude: -17.4603,
      type: LandmarkType.neighborhood,
      icon: '🏠',
    ),
  ];

  static List<LocalLandmark> getByType(LandmarkType type) {
    return dakarLandmarks.where((l) => l.type == type).toList();
  }

  static List<LocalLandmark> search(String query) {
    final lowerQuery = query.toLowerCase();
    return dakarLandmarks.where((landmark) {
      return landmark.name.toLowerCase().contains(lowerQuery) ||
          landmark.nameWolof.toLowerCase().contains(lowerQuery) ||
          landmark.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}

enum LandmarkType {
  place,
  monument,
  market,
  beach,
  airport,
  historical,
  neighborhood,
  mosque,
  hospital,
  school,
}

