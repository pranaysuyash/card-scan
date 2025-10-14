import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();

  factory AudioService() => _instance;

  AudioService._internal() {
    _initialize();
  }

  bool _isMuted = false;
  bool _isInitialized = false;

  Future<void> _initialize() async {
    try {
      await _loadSoundEffects();
      _isInitialized = true;
      print('AudioService initialized successfully');
    } catch (e) {
      print('AudioService initialization failed: $e');
    }
  }

  final Map<String, String> _soundEffects = {
    'tap': 'sounds/tap.mp3',
    'success': 'sounds/success.mp3',
    'error': 'sounds/error.mp3',
    'scan_start': 'sounds/scan_start.mp3',
    'scan_complete': 'sounds/scan_complete.mp3',
    'notification': 'sounds/notification.mp3',
  };

  final Map<String, AudioPlayer> _players = {};

  Future<void> _loadSoundEffects() async {
    final audioPlayer = AudioPlayer();
    for (final entry in _soundEffects.entries) {
      try {
        _players[entry.key] = audioPlayer;
      } catch (e) {
        print('Failed to load sound ${entry.key}: $e');
      }
    }
  }

  Future<void> playSound(String soundName, {double volume = 0.6}) async {
    if (!_isInitialized || _isMuted || !_soundEffects.containsKey(soundName)) return;

    try {
      await AudioPlayer().play(AssetSource(_soundEffects[soundName]!));
    } catch (e) {
      print('Failed to play sound $soundName: $e');
      // Silently fail if the sound file doesn't exist
    }
  }

  Future<void> playTap() => playSound('tap', volume: 0.3);
  Future<void> playSuccess() => playSound('success');
  Future<void> playError() => playSound('error', volume: 0.8);
  Future<void> playScanStart() => playSound('scan_start');
  Future<void> playScanComplete() => playSound('scan_complete');
  Future<void> playNotification() => playSound('notification', volume: 0.4);

  void setMuted(bool muted) {
    _isMuted = muted;
  }

  bool isMuted() => _isMuted;

  void dispose() {
    _players.forEach((key, player) {
      player.dispose();
    });
    _players.clear();
  }
}

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();

  factory SoundManager() => _instance;

  SoundManager._internal();

  final AudioService _audioService = AudioService();

  Future<void> playTap() => _audioService.playTap();
  Future<void> playSuccess() => _audioService.playSuccess();
  Future<void> playError() => _audioService.playError();
  Future<void> playScanStart() => _audioService.playScanStart();
  Future<void> playScanComplete() => _audioService.playScanComplete();
  Future<void> playNotification() => _audioService.playNotification();

  void setMuted(bool muted) => _audioService.setMuted(muted);
  bool isMuted() => _audioService.isMuted();
}

class SoundButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool enabled;

  const SoundButton({
    super.key,
    required this.child,
    this.onPressed,
    this.enabled = true,
  });

  @override
  State<SoundButton> createState() => _SoundButtonState();
}

class _SoundButtonState extends State<SoundButton> {
  final SoundManager _soundManager = SoundManager();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled
          ? () async {
              await _soundManager.playTap();
              widget.onPressed?.call();
            }
          : null,
      child: widget.child,
    );
  }
}

class SoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool enabled;
  final double size;
  final Color? color;

  const SoundIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.enabled = true,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SoundButton(
      enabled: enabled,
      onPressed: onPressed,
      child: Icon(
        icon,
        size: size,
        color: color ?? Theme.of(context).iconTheme.color,
      ),
    );
  }
}
