import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:web/web.dart' as web;
import 'workspace_storage.dart';

Future<WorkspaceStorage> openWorkspace() async {
  final root = await (await web.window.navigator.storage.getDirectory().toDart)
      .getDirectoryHandle(
        'rolechat',
        web.FileSystemGetDirectoryOptions(create: true),
      )
      .toDart;
  final ready = Completer<WorkspaceStorage>();
  final release = Completer<JSAny?>();
  unawaited(
    web.window.navigator.locks
        .request(
          'rolechat-runtime',
          web.LockOptions(ifAvailable: true),
          ((web.Lock? lock) {
            if (lock == null) {
              ready.completeError(StateError('RoleChat已在另一个标签页运行，请关闭该标签页后重试。'));
              return Future<JSAny?>.value(null).toJS;
            }
            ready.complete(OpfsWorkspaceStorage(root, release));
            return release.future.toJS;
          }).toJS,
        )
        .toDart
        .catchError((Object e) {
          if (!ready.isCompleted) ready.completeError(e);
          return null;
        }),
  );
  return ready.future;
}

class OpfsWorkspaceStorage implements WorkspaceStorage {
  OpfsWorkspaceStorage(this.root, this.release);
  final web.FileSystemDirectoryHandle root;
  final Completer<JSAny?> release;
  String? active;
  @override
  Future<bool> isInitialized() async {
    final bytes = await _read(root, 'initialized.json');
    if (bytes == null) return false;
    final marker = jsonDecode(utf8.decode(bytes));
    if (marker is! Map || marker['initialized'] != true) {
      throw const FormatException('初始化标记损坏，未改动现有数据');
    }
    return true;
  }

  @override
  Future<void> markInitialized() => _write(
    root,
    'initialized.json',
    Uint8List.fromList(utf8.encode('{"initialized":true}\n')),
  );
  @override
  void close() {
    if (!release.isCompleted) release.complete(null);
  }

  Future<Uint8List?> _read(
    web.FileSystemDirectoryHandle dir,
    String name,
  ) async {
    try {
      final file = await (await dir.getFileHandle(name).toDart)
          .getFile()
          .toDart;
      return (await file.arrayBuffer().toDart).toDart.asUint8List();
    } catch (e) {
      if (e.isA<web.DOMException>() &&
          (e as web.DOMException).name == 'NotFoundError') {
        return null;
      }
      rethrow;
    }
  }

  Future<void> _write(
    web.FileSystemDirectoryHandle dir,
    String path,
    Uint8List bytes,
  ) async {
    final parts = path.split('/');
    for (final part in parts.take(parts.length - 1)) {
      dir = await dir
          .getDirectoryHandle(
            part,
            web.FileSystemGetDirectoryOptions(create: true),
          )
          .toDart;
    }
    final file = await dir
        .getFileHandle(parts.last, web.FileSystemGetFileOptions(create: true))
        .toDart;
    final stream = await file.createWritable().toDart;
    try {
      await stream.write(bytes.toJS).toDart;
      await stream.close().toDart;
    } catch (_) {
      await stream.abort().toDart;
      rethrow;
    }
  }

  @override
  Future<FileTree> read() async {
    final manifest = await _read(root, 'active.json');
    if (manifest == null) return {};
    final data = jsonDecode(utf8.decode(manifest)) as Map<String, dynamic>;
    active = data['directory'] as String;
    if (!Uuid.isValidUUID(fromString: active!)) {
      throw const FormatException('文件提交记录损坏');
    }
    final dir = await root.getDirectoryHandle(active!).toDart;
    final files = <String, Uint8List>{};
    for (final name in List<String>.from(data['files'] as List)) {
      validateFilePath(name);
      final parts = name.split('/');
      var parent = dir;
      for (final part in parts.take(parts.length - 1)) {
        parent = await parent.getDirectoryHandle(part).toDart;
      }
      final bytes = await _read(parent, parts.last);
      if (bytes == null) throw FormatException('缺少文件：$name');
      files[name] = bytes;
    }
    return files;
  }

  @override
  Future<void> write(FileTree files) async {
    final next = const Uuid().v4();
    final dir = await root
        .getDirectoryHandle(
          next,
          web.FileSystemGetDirectoryOptions(create: true),
        )
        .toDart;
    try {
      for (final entry in files.entries) {
        validateFilePath(entry.key);
        await _write(dir, entry.key, entry.value);
      }
      final manifest = Uint8List.fromList(
        utf8.encode(
          jsonEncode({'directory': next, 'files': files.keys.toList()}),
        ),
      );
      await _write(root, 'active.json', manifest);
    } catch (_) {
      try {
        await root
            .removeEntry(next, web.FileSystemRemoveOptions(recursive: true))
            .toDart;
      } catch (_) {}
      rethrow;
    }
    final previous = active;
    active = next;
    if (previous != null) {
      try {
        await root
            .removeEntry(previous, web.FileSystemRemoveOptions(recursive: true))
            .toDart;
      } catch (_) {}
    }
  }
}
