import 'dart:convert';
import 'package:rolechat/infrastructure/storage/workspace_storage.dart';
import 'package:rolechat/infrastructure/storage/workspace_codec.dart';
import 'package:rolechat/domain/models/workspace_data.dart';

WorkspaceData remapData(WorkspaceData source, Map<String, String> ids) {
  // Map only identifier-valued JSON fields; never rewrite user text or Markdown.
  dynamic rewrite(dynamic value, [String? key]) {
    if (value is List) return value.map((v) => rewrite(v, key)).toList();
    if (value is Map) {
      return value.map((k, v) => MapEntry(k, rewrite(v, k as String)));
    }
    if (value is String &&
        {
          'id',
          'roleId',
          'apiId',
          'messageId',
          'members',
          'mentions',
          'lockedSchedules',
        }.contains(key)) {
      return ids[value] ?? value;
    }
    return value;
  }

  final files = WorkspaceCodec.encode(source);
  final result = <String, dynamic>{};
  for (final e in files.entries) {
    final segments = e.key.split('/').map((p) => ids[p] ?? p).join('/');
    result[segments] = e.value;
  }
  final output = <String, dynamic>{};
  for (final entry in result.entries) {
    if (entry.key.endsWith('.jsonl')) {
      final rows = const LineSplitter()
          .convert(utf8.decode(entry.value))
          .where((s) => s.isNotEmpty);
      output[entry.key] = WorkspaceCodec.text(
        rows
            .map((s) => jsonEncode(rewrite(jsonDecode(s))))
            .map((s) => '$s\n')
            .join(),
      );
    } else if (entry.key.endsWith('.json')) {
      var value = rewrite(jsonDecode(utf8.decode(entry.value)));
      if (entry.key == 'auth.json') {
        value = (value as Map).map((k, v) => MapEntry(ids[k] ?? k, v));
      }
      if (entry.key == 'runtime.json') value = <String, dynamic>{};
      output[entry.key] = WorkspaceCodec.json(value);
    } else {
      output[entry.key] = entry.value;
    }
  }
  return WorkspaceCodec.decode(FileTree.from(output));
}
