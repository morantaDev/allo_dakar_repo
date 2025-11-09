import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/screens/map_screen.dart';
import 'package:temove/services/api_service.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:async';

class RatingScreen extends StatefulWidget {
  final String driverName;
  final String driverCar;
  final String? driverAvatar;
  final int? rideId;
  final int? driverId;

  const RatingScreen({
    super.key,
    required this.driverName,
    required this.driverCar,
    this.driverAvatar,
    this.rideId,
    this.driverId,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> with SingleTickerProviderStateMixin {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  
  bool _isRecording = false;
  bool _hasRecording = false;
  String? _audioPath;
  Duration _recordingDuration = Duration.zero;
  bool _isButtonPressed = false; // Pour suivre l'état du bouton
  Timer? _durationTimer; // Timer pour mettre à jour la durée
  bool _isRecorderInitialized = false;
  
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;
  bool _isSubmitting = false;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _initializeRecorder();
    
    // Animation pour le pulse pendant l'enregistrement
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeRecorder() async {
    try {
      if (!kIsWeb) {
        // Demander la permission sur mobile
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          print('⚠️ [RECORD] Permission microphone refusée');
          return;
        }
      }
      
      await _audioRecorder.openRecorder();
      if (mounted) {
        setState(() {
          _isRecorderInitialized = true;
        });
      }
      print('✅ [RECORD] Enregistreur initialisé');
    } catch (e) {
      print('❌ [RECORD] Erreur initialisation: $e');
    }
  }

  Future<void> _checkFavoriteStatus() async {
    if (widget.driverId == null) return;
    
    setState(() => _isLoadingFavorite = true);
    try {
      final isFavorite = await ApiService.isFavoriteDriver(widget.driverId!);
      setState(() {
        _isFavorite = isFavorite;
        _isLoadingFavorite = false;
      });
    } catch (e) {
      setState(() => _isLoadingFavorite = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.driverId == null) return;
    
    setState(() => _isLoadingFavorite = true);
    try {
      Map<String, dynamic> result;
      if (_isFavorite) {
        result = await ApiService.removeFavoriteDriver(widget.driverId!);
      } else {
        result = await ApiService.addFavoriteDriver(widget.driverId!);
      }
      
      if (result['success'] == true) {
        setState(() {
          _isFavorite = !_isFavorite;
          _isLoadingFavorite = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite 
              ? 'Chauffeur ajouté aux favoris' 
              : 'Chauffeur retiré des favoris'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() => _isLoadingFavorite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoadingFavorite = false);
    }
  }

  Future<void> _startRecording() async {
    // Empêcher le démarrage multiple
    if (_isRecording) {
      print('⚠️ [RECORD] Enregistrement déjà en cours');
      return;
    }
    
    // Vérifier que l'enregistreur est initialisé
    if (!_isRecorderInitialized) {
      await _initializeRecorder();
      if (!_isRecorderInitialized) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur d\'initialisation de l\'enregistreur'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }
    
    print('🎤 [RECORD] Démarrage de l\'enregistrement...');
    try {
      if (!kIsWeb) {
        // Vérifier la permission sur mobile
        final status = await Permission.microphone.status;
        if (!status.isGranted) {
          final result = await Permission.microphone.request();
          if (!result.isGranted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Permission d\'enregistrement refusée'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }
      }

      String path;
      if (kIsWeb) {
        // Pour Flutter Web, flutter_sound gère automatiquement le stockage
        path = 'rating_${DateTime.now().millisecondsSinceEpoch}.m4a';
      } else {
        try {
          // Pour mobile, utiliser le répertoire de l'application
          final directory = await getApplicationDocumentsDirectory();
          path = '${directory.path}/rating_${DateTime.now().millisecondsSinceEpoch}.m4a';
        } catch (e) {
          // Fallback si path_provider échoue
          print('⚠️ [RECORD] Erreur path_provider, utilisation d\'un chemin temporaire: $e');
          path = '/tmp/rating_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }
      }
      
      // Démarrer l'enregistrement avec flutter_sound
      const codec = kIsWeb ? Codec.aacADTS : Codec.aacMP4;
      await _audioRecorder.startRecorder(
        toFile: path,
        codec: codec,
        bitRate: 128000,
        sampleRate: 44100,
      );
      
      print('✅ [RECORD] Enregistrement démarré avec succès: $path');
      
      if (mounted) {
        setState(() {
          _isRecording = true;
          _hasRecording = false;
          _audioPath = path;
          _recordingDuration = const Duration(milliseconds: 100);
          _isButtonPressed = true; // S'assurer que le flag est activé
        });
        
        // Démarrer l'animation de pulse (en boucle)
        _pulseController.repeat(reverse: true);
        
        // Démarrer le timer pour la durée
        _updateRecordingDuration();
      }
    } catch (e) {
      print('❌ [RECORD] Erreur démarrage enregistrement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'enregistrement: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _isRecording = false;
        });
      }
    }
  }

  void _updateRecordingDuration() {
    // Annuler le timer précédent s'il existe
    _durationTimer?.cancel();
    
    // Mettre à jour la durée toutes les 100ms pour un affichage fluide
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isRecording || !mounted) {
        timer.cancel();
        return;
      }
      
      // Vérification de sécurité : arrêter si le bouton n'est plus pressé
      // Mais seulement après au moins 500ms pour éviter les arrêts trop rapides
      if (!_isButtonPressed && _recordingDuration.inMilliseconds >= 500) {
        print('🎤 [RECORD] Sécurité : bouton relâché, arrêt automatique après ${_recordingDuration.inMilliseconds}ms');
        timer.cancel();
        _stopRecording();
        return;
      }
      
      if (mounted) {
        setState(() {
          _recordingDuration = Duration(milliseconds: _recordingDuration.inMilliseconds + 100);
        });
      }
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) {
      print('⚠️ [RECORD] Tentative d\'arrêt alors que l\'enregistrement n\'est pas actif');
      return;
    }
    
    print('🛑 [RECORD] Arrêt de l\'enregistrement... (durée actuelle: ${_recordingDuration.inMilliseconds}ms)');
    
    // Annuler le timer de durée avant d'arrêter
    _durationTimer?.cancel();
    
    try {
      // Sur Web, attendre un peu pour que l'enregistrement se finalise
      if (kIsWeb && _recordingDuration.inMilliseconds < 500) {
        print('⏳ [RECORD] Web: Attente de finalisation de l\'enregistrement...');
        await Future.delayed(const Duration(milliseconds: 300));
        // Mettre à jour la durée pendant l'attente
        if (mounted && _isRecording) {
          setState(() {
            _recordingDuration = Duration(milliseconds: _recordingDuration.inMilliseconds + 300);
          });
        }
      }
      
      final path = await _audioRecorder.stopRecorder();
      print('🛑 [RECORD] Enregistrement arrêté, chemin retourné: $path');
      
      // Sur Flutter Web, le package record peut retourner null ou un blob URL
      String? finalPath = path;
      
      if (finalPath == null || finalPath.isEmpty) {
        if (kIsWeb) {
          // Sur Web, si stop() retourne null, l'enregistrement n'a peut-être pas été finalisé
          // On attend un peu et on réessaye de récupérer le chemin
          print('🌐 [RECORD] Web: Chemin null, tentative de récupération...');
          
          // Attendre un peu plus pour que le blob soit créé
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Sur Web, le package record stocke parfois le blob dans un état interne
          // On ne peut pas le récupérer directement, donc on considère l'enregistrement comme invalide
          // sauf si la durée est suffisante
          if (_recordingDuration.inSeconds >= 1) {
            print('⚠️ [RECORD] Web: Enregistrement valide mais blob URL non récupéré');
            // On ne peut pas utiliser l'enregistrement sans blob URL sur Web
            finalPath = null;
          } else {
            print('⚠️ [RECORD] Web: Enregistrement trop court et blob URL non récupéré');
            finalPath = null;
          }
        } else {
          // Sur mobile, utiliser le chemin stocké si disponible
          if (_audioPath != null && _audioPath!.isNotEmpty) {
            print('📝 [RECORD] Mobile: Utilisation du chemin stocké: $_audioPath');
            finalPath = _audioPath;
          }
        }
      } else if (kIsWeb && finalPath.startsWith('blob:')) {
        // Sur Web, on reçoit un blob URL directement - parfait !
        print('✅ [RECORD] Web: Blob URL reçu: $finalPath');
      } else if (!kIsWeb) {
        // Sur mobile, on reçoit un chemin de fichier
        print('✅ [RECORD] Mobile: Chemin de fichier reçu: $finalPath');
      }
      
      if (mounted) {
        // Arrêter l'animation
        _pulseController.stop();
        _pulseController.reset();
        
        // Annuler le timer de durée
        _durationTimer?.cancel();
        
        // Sur Web, on a besoin d'un blob URL valide
        // Sur mobile, on a besoin d'un chemin de fichier valide
        // Si on a un blob URL valide sur Web, on accepte même si la durée est très courte
        // (car le timer peut ne pas avoir eu le temps de s'incrémenter)
        final hasValidRecording = finalPath != null && 
                                  finalPath.isNotEmpty && 
                                  (kIsWeb 
                                    ? (finalPath.startsWith('blob:') && _recordingDuration.inMilliseconds >= 100)
                                    : _recordingDuration.inMilliseconds >= 500);
        
        setState(() {
          _isRecording = false;
          _isButtonPressed = false; // Réinitialiser le flag
          _hasRecording = hasValidRecording;
          if (hasValidRecording) {
            _audioPath = finalPath;
            print('✅ [RECORD] Enregistrement terminé avec succès: $finalPath (durée: ${_recordingDuration.inSeconds}s)');
          } else {
            print('⚠️ [RECORD] Enregistrement invalide - chemin: $finalPath, durée: ${_recordingDuration.inSeconds}s');
            _audioPath = null;
            _hasRecording = false;
          }
        });
        
        // Afficher un message si l'enregistrement est invalide
        if (!hasValidRecording) {
          String message;
          if (kIsWeb && (finalPath == null || !finalPath.startsWith('blob:'))) {
            message = 'Erreur lors de l\'enregistrement. Veuillez réessayer.';
          } else if (!kIsWeb && _recordingDuration.inSeconds < 1) {
            message = 'Enregistrement trop court. Veuillez maintenir le bouton plus longtemps.';
          } else if (kIsWeb && finalPath != null && finalPath.startsWith('blob:') && _recordingDuration.inMilliseconds == 0) {
            // Cas spécial : blob URL valide mais durée à 0 (timer pas encore mis à jour)
            // On accepte quand même l'enregistrement
            print('✅ [RECORD] Blob URL valide accepté malgré durée à 0 (timer pas encore mis à jour)');
            setState(() {
              _hasRecording = true;
              _audioPath = finalPath;
            });
            return; // Sortir sans afficher d'erreur
          } else {
            message = 'Enregistrement invalide. Veuillez réessayer.';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [RECORD] Erreur arrêt enregistrement: $e');
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isButtonPressed = false; // Réinitialiser le flag même en cas d'erreur
          _hasRecording = false;
          _audioPath = null;
        });
        // Arrêter l'animation même en cas d'erreur
        _pulseController.stop();
        _pulseController.reset();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'arrêt: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _deleteRecording() async {
    if (_audioPath != null && !kIsWeb) {
      try {
        final file = File(_audioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('⚠️ Erreur suppression fichier: $e');
      }
    }
    if (mounted) {
      setState(() {
        _hasRecording = false;
        _audioPath = null;
        _recordingDuration = Duration.zero;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _submitRating() async {
    if (widget.rideId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID de course manquant. Impossible de soumettre l\'évaluation.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Uploader l'audio si présent
    String? audioUrl;
    if (_audioPath != null && _hasRecording) {
      try {
        final uploadResult = await ApiService.uploadAudio(_audioPath!);
        if (uploadResult['success'] == true) {
          audioUrl = uploadResult['audio_url'];
          print('✅ [RATING] Audio uploadé: $audioUrl');
        } else {
          // Afficher un avertissement mais continuer sans audio
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('L\'audio n\'a pas pu être uploadé: ${uploadResult['message']}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        print('❌ [RATING] Erreur upload audio: $e');
        // Continuer sans audio
      }
    }

    // Soumettre l'évaluation
    final result = await ApiService.submitRating(
      rideId: widget.rideId!,
      driverId: widget.driverId ?? 0, // Utiliser 0 si driverId n'est pas disponible
      rating: _rating,
      comment: _commentController.text.isNotEmpty ? _commentController.text : null,
      audioUrl: audioUrl,
    );

    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Merci pour votre évaluation !'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      
      // Retourner à l'écran principal
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const MapScreen(),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Erreur lors de la soumission'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _audioRecorder.closeRecorder();
    _commentController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Header
              Text(
                'Comment s\'est passée votre course ?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Driver Info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.secondaryColor.withOpacity(0.2)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade300,
                          ),
                          child: widget.driverAvatar != null
                              ? ClipOval(
                                  child: Image.network(
                                    widget.driverAvatar!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                        ),
                        // Badge favori
                        if (widget.driverId != null)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: _isLoadingFavorite ? null : _toggleFavorite,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _isFavorite 
                                      ? AppTheme.primaryColor 
                                      : Colors.grey.shade400,
                                  shape: BoxShape.circle,
                                ),
                                child: _isLoadingFavorite
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Icon(
                                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.driverName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.driverCar,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
                      ),
                    ),
                    if (widget.driverId != null) ...[
                      const SizedBox(height: 12),
                      // Option Chauffeur préféré
                      InkWell(
                        onTap: _isLoadingFavorite ? null : _toggleFavorite,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isFavorite 
                                ? AppTheme.primaryColor.withOpacity(0.1)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isFavorite 
                                  ? AppTheme.primaryColor 
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isFavorite ? Icons.favorite : Icons.favorite_border,
                                size: 18,
                                color: _isFavorite 
                                    ? AppTheme.primaryColor 
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Chauffeur préféré',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _isFavorite 
                                      ? AppTheme.primaryColor 
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Rating Stars
              Text(
                'Notez votre expérience',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        size: 48,
                        color: index < _rating
                            ? AppTheme.primaryColor
                            : Colors.grey.shade400,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                _getRatingText(_rating),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 40),
              // Comment Field
              Text(
                'Ajouter un commentaire (optionnel)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Dites-nous comment s\'est passée votre course...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppTheme.backgroundColor.withOpacity(0.3)
                      : Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              // Audio Recording Section
              Text(
                'Ou enregistrez un avis vocal (optionnel)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.backgroundColor.withOpacity(0.3)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (_isRecording) ...[
                      // Indicateur d'enregistrement en cours avec animation pulse
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.red,
                                  width: 3,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _formatDuration(_recordingDuration),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Enregistrement en cours...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.touch_app,
                              color: Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Relâchez pour arrêter',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (_hasRecording) ...[
                      // Afficher l'enregistrement existant
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mic,
                              color: AppTheme.primaryColor,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Avis vocal enregistré',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
                                ),
                              ),
                              Text(
                                'Durée: ${_formatDuration(_recordingDuration)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: _deleteRecording,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Supprimer'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _startRecording,
                            icon: const Icon(Icons.mic),
                            label: const Text('Réenregistrer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Bouton avec appui long (style WhatsApp)
                      Listener(
                        onPointerDown: (_) {
                          print('🎤 [RECORD] Pointer down - Démarrage enregistrement');
                          if (mounted) {
                            setState(() {
                              _isButtonPressed = true;
                            });
                          }
                          if (!_isRecording) {
                            _startRecording();
                          }
                        },
                        onPointerUp: (_) {
                          print('🎤 [RECORD] Pointer up - Arrêt enregistrement');
                          if (mounted) {
                            SchedulerBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _isButtonPressed = false;
                                });
                              }
                            });
                          }
                          if (_isRecording) {
                            _stopRecording();
                          }
                        },
                        onPointerCancel: (_) {
                          print('🎤 [RECORD] Pointer cancel - Arrêt enregistrement');
                          if (mounted) {
                            SchedulerBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _isButtonPressed = false;
                                });
                              }
                            });
                          }
                          if (_isRecording) {
                            _stopRecording();
                          }
                        },
                        child: GestureDetector(
                          onLongPressStart: (_) {
                            print('🎤 [RECORD] Long press start');
                            if (mounted) {
                              setState(() {
                                _isButtonPressed = true;
                              });
                            }
                            if (!_isRecording) {
                              _startRecording();
                            }
                          },
                          onLongPressEnd: (_) {
                            print('🎤 [RECORD] Long press end - Arrêt enregistrement');
                            if (mounted) {
                              SchedulerBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _isButtonPressed = false;
                                  });
                                }
                              });
                            }
                            if (_isRecording) {
                              _stopRecording();
                            }
                          },
                          onLongPressCancel: () {
                            print('🎤 [RECORD] Long press cancel - Arrêt enregistrement (durée: ${_recordingDuration.inMilliseconds}ms)');
                            // Ne pas arrêter immédiatement si l'enregistrement vient de démarrer
                            // Attendre au moins 200ms pour que le timer ait le temps de démarrer
                            if (_recordingDuration.inMilliseconds < 200) {
                              print('⏳ [RECORD] Enregistrement trop récent, attente avant arrêt...');
                              Future.delayed(const Duration(milliseconds: 200), () {
                                if (mounted) {
                                  SchedulerBinding.instance.addPostFrameCallback((_) {
                                    if (mounted) {
                                      setState(() {
                                        _isButtonPressed = false;
                                      });
                                    }
                                  });
                                }
                                if (_isRecording) {
                                  _stopRecording();
                                }
                              });
                            } else {
                              if (mounted) {
                                SchedulerBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    setState(() {
                                      _isButtonPressed = false;
                                    });
                                  }
                                });
                              }
                              if (_isRecording) {
                                _stopRecording();
                              }
                            }
                          },
                          onTapUp: (_) {
                            // Sécurité supplémentaire : arrêter si on relâche avec un tap
                            print('🎤 [RECORD] Tap up - Arrêt enregistrement (sécurité)');
                            if (mounted) {
                              SchedulerBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _isButtonPressed = false;
                                  });
                                }
                              });
                            }
                            if (_isRecording) {
                              _stopRecording();
                            }
                          },
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.mic,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Maintenez pour enregistrer',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Envoyer l\'évaluation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isSubmitting ? null : () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MapScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: Text(
                  'Passer',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 5:
        return 'Excellent !';
      case 4:
        return 'Très bien';
      case 3:
        return 'Bien';
      case 2:
        return 'Moyen';
      case 1:
        return 'Mauvais';
      default:
        return '';
    }
  }
}
