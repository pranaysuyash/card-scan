import 'package:flutter/material.dart';
import 'package:card_scan/services/error_handler.dart';
import 'package:card_scan/services/logger_service.dart';

/// Error boundary widget that catches errors in its child widget tree
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;
  final void Function(Object error, StackTrace? stackTrace)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;
  final LoggerService _logger = LoggerService();
  final ErrorHandler _errorHandler = ErrorHandler();

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      // Show error UI
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!, _stackTrace);
      }
      return _buildDefaultErrorWidget();
    }

    // Wrap child with error catching
    return ErrorWidget.builder = (FlutterErrorDetails details) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleError(details.exception, details.stack);
      });
      return _buildDefaultErrorWidget();
    };

    return widget.child;
  }

  void _handleError(Object error, StackTrace? stackTrace) {
    setState(() {
      _error = error;
      _stackTrace = stackTrace;
    });

    _logger.error('ErrorBoundary caught error', error: error, stackTrace: stackTrace);

    widget.onError?.call(error, stackTrace);

    _errorHandler.handleError(
      message: 'Widget error occurred',
      error: error,
      stackTrace: stackTrace,
      severity: ErrorSeverity.error,
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.shade900,
              Colors.red.shade700,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'We\'re sorry for the inconvenience. The error has been logged and we\'ll look into it.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _resetError,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red.shade900,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _resetError() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }
}

/// Async error boundary for handling Future/async errors
class AsyncErrorBoundary extends StatelessWidget {
  final Future<Widget> Function() builder;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;
  final Widget? loadingWidget;

  const AsyncErrorBoundary({
    super.key,
    required this.builder,
    this.errorBuilder,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: builder(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          if (errorBuilder != null) {
            return errorBuilder!(snapshot.error!, snapshot.stackTrace);
          }
          return _buildDefaultErrorWidget(context, snapshot.error!, snapshot.stackTrace);
        }

        if (snapshot.hasData) {
          return snapshot.data!;
        }

        return loadingWidget ?? const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildDefaultErrorWidget(BuildContext context, Object error, StackTrace? stackTrace) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade700,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load content',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
