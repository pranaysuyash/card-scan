import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/contact.dart';
import '../../features/voice_notes/services/voice_note_service.dart';
import '../../core/repositories/contact_repository.dart';
import '../../services/haptic_service.dart';
import '../quantum_theme.dart';
import '../widgets/glass_container.dart';

/// Voice note recording and playback screen
class VoiceNoteScreen extends ConsumerStatefulWidget {
  final Contact contact;

  const VoiceNoteScreen({
    super.key,
    required this.contact,
  });

  @override
  ConsumerState<VoiceNoteScreen> createState() => _VoiceNoteScreenState();
}

class _VoiceNoteScreenState extends ConsumerState<VoiceNoteScreen>
    with SingleTickerProviderStateMixin {
  final VoiceNoteService _voiceNoteService = VoiceNoteService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _transcriptionController =
      TextEditingController();

  bool _isRecording = false;
  bool _isPlaying = false;
  bool _hasRecording = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Duration _playbackDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;

  Timer? _recordingTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeVoiceService();
    _initializeAnimations();
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _pulseController.dispose();
    _audioPlayer.dispose();
    _voiceNoteService.dispose();
    _transcriptionController.dispose();
    super.dispose();
  }

  Future<void> _initializeVoiceService() async {
    final result = await _voiceNoteService.initialize();
    result.fold(
      (failure) => _showError('Failed to initialize: ${failure.message}'),
      (_) {},
    );
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseController.repeat(reverse: true);
  }

  void _setupAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _playbackDuration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _playbackPosition = position;
      });
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _playbackPosition = Duration.zero;
      });
    });
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final result = await _voiceNoteService.startRecording();

    result.fold(
      (failure) => _showError('Failed to start recording: ${failure.message}'),
      (path) {
        setState(() {
          _isRecording = true;
          _recordingPath = path;
          _recordingDuration = Duration.zero;
        });

        HapticService().mediumImpact();

        _recordingTimer = Timer.periodic(
          const Duration(seconds: 1),
          (timer) {
            setState(() {
              _recordingDuration = Duration(seconds: timer.tick);
            });
          },
        );
      },
    );
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();

    final result = await _voiceNoteService.stopRecording();

    result.fold(
      (failure) => _showError('Failed to stop recording: ${failure.message}'),
      (path) {
        setState(() {
          _isRecording = false;
          _hasRecording = true;
          _recordingPath = path;
        });

        HapticService().successImpact();
      },
    );
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      if (_recordingPath != null) {
        await _audioPlayer.play(DeviceFileSource(_recordingPath!));
        setState(() {
          _isPlaying = true;
        });
        HapticService().lightImpact();
      }
    }
  }

  Future<void> _deleteRecording() async {
    if (_recordingPath != null) {
      try {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignore deletion errors
      }
    }

    setState(() {
      _hasRecording = false;
      _recordingPath = null;
      _recordingDuration = Duration.zero;
      _playbackDuration = Duration.zero;
      _playbackPosition = Duration.zero;
      _transcriptionController.clear();
    });

    HapticService().lightImpact();
  }

  Future<void> _saveVoiceNote() async {
    if (_recordingPath == null) {
      _showError('No recording to save');
      return;
    }

    final transcription = _transcriptionController.text.trim();

    final result = await _voiceNoteService.addVoiceNoteToContact(
      contact: widget.contact,
      audioPath: _recordingPath!,
      transcription: transcription.isNotEmpty ? transcription : null,
    );

    result.fold(
      (failure) => _showError('Failed to save note: ${failure.message}'),
      (updatedContact) async {
        // Save to repository
        final repository = ref.read(contactRepositoryProvider);
        final saveResult = await repository.save(updatedContact);

        saveResult.fold(
          (failure) =>
              _showError('Failed to save contact: ${failure.message}'),
          (_) {
            HapticService().successImpact();
            _showSuccess('Voice note saved successfully');
            if (mounted) {
              context.pop();
            }
          },
        );
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: QuantumTheme.errorRed,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: QuantumTheme.successGreen,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              QuantumTheme.deepSpace,
              QuantumTheme.darkPurple,
              QuantumTheme.deepSpace,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Contact info
                      _buildContactInfo(),

                      const SizedBox(height: 32),

                      // Recording controls
                      _buildRecordingControls(),

                      const SizedBox(height: 32),

                      // Waveform visualization
                      if (_isRecording) _buildWaveform(),

                      // Playback controls
                      if (_hasRecording && !_isRecording)
                        _buildPlaybackControls(),

                      const SizedBox(height: 32),

                      // Transcription
                      if (_hasRecording) _buildTranscriptionSection(),
                    ],
                  ),
                ),
              ),

              // Action buttons
              if (_hasRecording && !_isRecording) _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          const Text(
            'Voice Note',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          if (_hasRecording && !_isRecording)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white70),
              onPressed: _deleteRecording,
            ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: QuantumTheme.primaryBlue,
              child: Text(
                widget.contact.fullName.isNotEmpty
                    ? widget.contact.fullName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contact.fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.contact.company != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.contact.company!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingControls() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // Duration
            Text(
              _formatDuration(_recordingDuration),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),

            const SizedBox(height: 32),

            // Record button
            GestureDetector(
              onTap: _toggleRecording,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isRecording ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _isRecording
                              ? [
                                  QuantumTheme.errorRed,
                                  QuantumTheme.errorRed.withOpacity(0.7),
                                ]
                              : [
                                  QuantumTheme.primaryBlue,
                                  QuantumTheme.accentPurple,
                                ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording
                                    ? QuantumTheme.errorRed
                                    : QuantumTheme.primaryBlue)
                                .withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Status text
            Text(
              _isRecording ? 'Recording...' : 'Tap to record',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveform() {
    return GlassContainer(
      child: SizedBox(
        height: 120,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(
            20,
            (index) {
              final height = 20.0 +
                  (60.0 *
                      (0.5 +
                          0.5 *
                              (DateTime.now().millisecondsSinceEpoch / 100.0 +
                                      index)
                                  .sin()));
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 4,
                height: height,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      QuantumTheme.primaryBlue,
                      QuantumTheme.accentPurple,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Playback progress
            Row(
              children: [
                Text(
                  _formatDuration(_playbackPosition),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _playbackPosition.inMilliseconds.toDouble(),
                    max: _playbackDuration.inMilliseconds.toDouble() > 0
                        ? _playbackDuration.inMilliseconds.toDouble()
                        : 1.0,
                    onChanged: (value) async {
                      await _audioPlayer.seek(
                        Duration(milliseconds: value.toInt()),
                      );
                    },
                    activeColor: QuantumTheme.primaryBlue,
                    inactiveColor: Colors.white.withOpacity(0.2),
                  ),
                ),
                Text(
                  _formatDuration(_playbackDuration),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Play/pause button
            GestureDetector(
              onTap: _togglePlayback,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      QuantumTheme.primaryBlue,
                      QuantumTheme.accentPurple,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: QuantumTheme.primaryBlue.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptionSection() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.text_fields,
                  color: QuantumTheme.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Transcription / Notes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _transcriptionController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText:
                    'Add notes or transcription here...\n\n(Automatic transcription coming soon)',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuantumTheme.deepSpace.withOpacity(0.9),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.close),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _saveVoiceNote,
              icon: const Icon(Icons.save),
              label: const Text('Save Voice Note'),
              style: ElevatedButton.styleFrom(
                backgroundColor: QuantumTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Provider for contact repository
final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  throw UnimplementedError('ContactRepository provider not initialized');
});
