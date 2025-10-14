import 'package:flutter/material.dart';

class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool showFps;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.showFps = false,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> with WidgetsBindingObserver {
  final List<double> _frameTimes = [];
  double _avgFrameTime = 0;
  double _fps = 0;
  bool _isMonitoring = false;

  @override
  void initState() {
    super.initState();
    if (widget.showFps) {
      _startMonitoring();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (widget.showFps && !_isMonitoring) {
        _startMonitoring();
      }
    } else if (state == AppLifecycleState.paused) {
      _stopMonitoring();
    }
  }

  @override
  void dispose() {
    _stopMonitoring();
    super.dispose();
  }

  void _startMonitoring() {
    if (!_isMonitoring) {
      WidgetsBinding.instance.addPersistentFrameCallback(_onFrame);
      _isMonitoring = true;
    }
  }

  void _stopMonitoring() {
    if (_isMonitoring) {
      _isMonitoring = false;
    }
  }

  void _onFrame(Duration duration) {
    final frameTime = duration.inMicroseconds / 1000.0; // Convert to milliseconds
    _frameTimes.add(frameTime);

    if (_frameTimes.length > 60) {
      _frameTimes.removeAt(0);
    }

    _avgFrameTime = _frameTimes.fold(0.0, (a, b) => a + b) / _frameTimes.length;
    _fps = 1000.0 / _avgFrameTime;

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.showFps
        ? Stack(
            children: [
              widget.child,
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_fps.toStringAsFixed(1)} FPS\n${_avgFrameTime.toStringAsFixed(1)}ms',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          )
        : widget.child;
  }
}