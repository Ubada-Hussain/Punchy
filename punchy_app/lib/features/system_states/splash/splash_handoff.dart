/// Both signals run independently. Neither can trigger navigation on its own.
class SplashHandoff {
  SplashHandoff(Future<void> initialization, this.onBothReady) {
    initialization.then((_) {
      if (_disposed) return;
      initialized = true;
      _check();
    });
  }

  final void Function() onBothReady;
  bool initialized = false;
  bool _animated = false;
  bool _sent = false;
  bool _disposed = false;

  void animationFinished() {
    _animated = true;
    _check();
  }

  void _check() {
    if (!_disposed && !_sent && initialized && _animated) {
      _sent = true;
      onBothReady();
    }
  }

  void dispose() => _disposed = true;
}
