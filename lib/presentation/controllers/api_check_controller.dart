import 'package:flutter/foundation.dart';
import 'package:rolechat/application/apis/ports/api_checker.dart';

/// Shared request state; edited inputs invalidate results without starting duplicates.
class ApiCheckController extends ChangeNotifier {
  bool running = false;
  ModelCheckResult? result;
  int _revision = 0;
  bool _disposed = false;

  void invalidate() {
    _revision++;
    result = null;
    notifyListeners();
  }

  Future<void> run(Future<ModelCheckResult> Function() request) async {
    if (running || _disposed) return;
    final revision = ++_revision;
    running = true;
    result = null;
    notifyListeners();
    ModelCheckResult response;
    try {
      response = await request();
    } catch (_) {
      response = const ModelCheckResult(false, '检测失败：请求未能完成，请重试。');
    }
    if (_disposed) return;
    running = false;
    if (revision == _revision) result = response;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
