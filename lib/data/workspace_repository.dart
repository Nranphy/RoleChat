import 'dart:async';
import 'workspace_codec.dart';
import '../models/workspace_data.dart';
import 'workspace_storage.dart';

class WorkspaceRepository {
  WorkspaceRepository(this.storage);
  final WorkspaceStorage storage;
  Future<void> _queue = Future.value();
  String? error;
  Future<WorkspaceData?> load() async {
    final files = await storage.read();
    return files.isEmpty ? null : WorkspaceCodec.decode(files);
  }

  Future<bool> save(WorkspaceData data) async {
    // Capture before queueing; callers can continue editing independent objects.
    final files = WorkspaceCodec.encode(data);
    final pending = _queue.then((_) => storage.write(files));
    _queue = pending.catchError((Object _) {});
    try {
      await pending;
      error = null;
      return true;
    } catch (_) {
      error = '本地文件保存失败，请检查浏览器存储空间';
      return false;
    }
  }

  Future<void> flush() => _queue;
  Future<void> saveOrThrow(WorkspaceData data) async {
    if (!await save(data)) throw StateError(error!);
  }

  void close() => unawaited(_queue.whenComplete(storage.close));
}
