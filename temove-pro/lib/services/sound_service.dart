// Import conditionnel: utiliser sound_service_web.dart pour le web,
// sound_service_stub.dart pour les autres plateformes
export 'sound_service_stub.dart' if (dart.library.html) 'sound_service_web.dart';
