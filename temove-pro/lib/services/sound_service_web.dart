import 'package:flutter/foundation.dart';
import 'dart:html' as html;

/// Service pour jouer des sons de notification (implémentation web)
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
    
    try {
      _playWebBeep(600, 200);
      await Future.delayed(const Duration(milliseconds: 100));
      _playWebBeep(800, 200);
      print('🔊 [SOUND] Son de nouvelle course joué');
    } catch (e) {
      print('⚠️ [SOUND] Erreur: $e');
    }
  }

  Future<void> playSuccessSound() async {
    if (!_isEnabled) return;
    
    try {
      _playWebBeep(800, 150);
      await Future.delayed(const Duration(milliseconds: 50));
      _playWebBeep(1000, 150);
      print('🔊 [SOUND] Son de succès joué');
    } catch (e) {
      print('⚠️ [SOUND] Erreur: $e');
    }
  }

  /// Jouer un bip sur le web
  void _playWebBeep(int frequency, int duration) {
    try {
      // Créer un script element qui appelle la fonction JavaScript
      // ou crée le son directement avec Web Audio API
      final script = html.ScriptElement()
        ..type = 'text/javascript'
        ..text = '''
          (function() {
            try {
              // Essayer d'utiliser la fonction playBeepSound si elle existe
              if (typeof window.playBeepSound === 'function') {
                window.playBeepSound($frequency, $duration);
              } else {
                // Sinon, créer le son directement
                var AudioContext = window.AudioContext || window.webkitAudioContext;
                if (!AudioContext) {
                  console.warn('Web Audio API not supported');
                  return;
                }
                var ctx = new AudioContext();
                var oscillator = ctx.createOscillator();
                var gainNode = ctx.createGain();
                
                oscillator.connect(gainNode);
                gainNode.connect(ctx.destination);
                
                oscillator.frequency.value = $frequency;
                oscillator.type = 'sine';
                
                gainNode.gain.setValueAtTime(0.3, ctx.currentTime);
                gainNode.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + $duration / 1000);
                
                oscillator.start(ctx.currentTime);
                oscillator.stop(ctx.currentTime + $duration / 1000);
              }
            } catch(e) {
              console.error('Erreur AudioContext:', e);
            }
          })();
        ''';
      
      // Ajouter le script au head du document pour l'exécuter
      html.document.head?.append(script);
      
      // Retirer le script après exécution (nettoyage)
      Future.delayed(const Duration(milliseconds: 500), () {
        try {
          script.remove();
        } catch (e) {
          // Ignorer les erreurs de suppression
        }
      });
    } catch (e) {
      print('⚠️ [SOUND] Erreur lors de la lecture du son: $e');
    }
  }
}
