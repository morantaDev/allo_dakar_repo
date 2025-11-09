import 'package:flutter/foundation.dart';

/// Service pour jouer des sons de notification (stub pour les plateformes non-web)
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _isEnabled = true;

  bool get isEnabled => _isEnabled;
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  Future<void> playNewRideSound() async {
    if (!_isEnabled) return;
    // Stub pour les plateformes non-web
    print('🔊 [SOUND] Son de nouvelle course (stub - non-web)');
  }

  Future<void> playSuccessSound() async {
    if (!_isEnabled) return;
    // Stub pour les plateformes non-web
    print('🔊 [SOUND] Son de succès (stub - non-web)');
  }
}

