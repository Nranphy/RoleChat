import 'dart:typed_data';

typedef FileTree = Map<String, Uint8List>;

abstract interface class WorkspaceStorage {
  Future<bool> isInitialized();
  Future<void> markInitialized();
  Future<FileTree> read();
  Future<void> write(FileTree files);
  void close();
}

class MemoryWorkspaceStorage implements WorkspaceStorage {
  FileTree files = {};
  bool initialized = false;
  @override
  Future<bool> isInitialized() async => initialized;
  @override
  Future<void> markInitialized() async {
    initialized = true;
  }

  @override
  Future<FileTree> read() async => {
    for (final e in files.entries) e.key: Uint8List.fromList(e.value),
  };
  @override
  Future<void> write(FileTree value) async {
    files = {for (final e in value.entries) e.key: Uint8List.fromList(e.value)};
  }

  @override
  void close() {}
}

void validateFilePath(String path) {
  if (!RegExp(r'^[a-zA-Z0-9_./-]+$').hasMatch(path) ||
      path.startsWith('/') ||
      path.split('/').any((p) => p.isEmpty || p == '.' || p == '..')) {
    throw const FormatException('非法文件路径');
  }
}
