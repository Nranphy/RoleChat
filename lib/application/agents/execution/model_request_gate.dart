/// Shared model capacity and temporary cooldown, independent of agent lifecycle.
class ModelRequestGate {
  final _active = <String, int>{};
  final _retryAfter = <String, DateTime>{};
  DateTime? retryAfter(String key) => _retryAfter[key];
  void coolDown(String key, DateTime until) => _retryAfter[key] = until;
  bool atCapacity(String key, int maximum) => (_active[key] ?? 0) >= maximum;

  Future<ModelRequestLease?> acquire(
    String key,
    int maximum,
    bool Function() valid,
  ) async {
    while (atCapacity(key, maximum)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!valid()) return null;
    }
    if (!valid()) return null;
    _active[key] = (_active[key] ?? 0) + 1;
    return ModelRequestLease(() {
      final remaining = (_active[key] ?? 1) - 1;
      if (remaining == 0) {
        _active.remove(key);
      } else {
        _active[key] = remaining;
      }
    });
  }
}

class ModelRequestLease {
  ModelRequestLease(this._release);
  final void Function() _release;
  bool _released = false;
  void release() {
    if (_released) return;
    _released = true;
    _release();
  }
}
