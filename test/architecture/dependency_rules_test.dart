import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('imports preserve layer boundaries and canonical package paths', () {
    final failures = <String>[];
    final graph = <String, Set<String>>{};
    final directives = RegExp(
      r'''^(?:import|export)\s+[\s\S]*?;''',
      multiLine: true,
    );
    final uris = RegExp(r'''['"]([^'"\r\n]+)['"]''');
    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      final source = file.path.replaceAll('\\', '/');
      final layer = source.split('/')[1];
      graph[source] = {};
      for (final directive in directives.allMatches(file.readAsStringSync())) {
        for (final match in uris.allMatches(directive.group(0)!)) {
          final uri = match.group(1)!;
          if (!uri.startsWith('dart:') && !uri.startsWith('package:')) {
            failures.add('$source uses a relative URI: $uri');
          }
          if (['core', 'domain', 'application'].contains(layer) &&
              (uri.startsWith('package:flutter/') ||
                  uri.startsWith('package:dart_openai/') ||
                  uri.startsWith('package:http/') ||
                  uri.startsWith('package:web/') ||
                  {
                    'dart:io',
                    'dart:html',
                    'dart:js_interop',
                    'dart:ffi',
                  }.contains(uri))) {
            failures.add('$source imports a platform adapter: $uri');
          }
          if (layer == 'presentation' &&
              (uri.startsWith('package:dart_openai/') ||
                  uri.contains('/infrastructure/ai/'))) {
            failures.add('$source directly depends on an AI implementation');
          }
          if (!uri.startsWith('package:rolechat/')) continue;
          final target = uri.substring('package:rolechat/'.length);
          graph[source]!.add('lib/$target');
          if (!File('lib/$target').existsSync()) {
            failures.add('$source references missing $target');
          }
          final targetLayer = target.split('/').first;
          final allowed = switch (layer) {
            'core' => {'core'},
            'domain' => {'core', 'domain'},
            'application' => {'core', 'domain', 'application'},
            'infrastructure' => {
              'core',
              'domain',
              'application',
              'infrastructure',
            },
            _ => null,
          };
          if (allowed != null && !allowed.contains(targetLayer)) {
            failures.add('$source depends upward on $target');
          }
        }
      }
    }
    final reachable = <String>{};
    void visit(String file) {
      if (!reachable.add(file)) return;
      for (final target in graph[file] ?? <String>{}) {
        visit(target);
      }
    }

    visit('lib/main.dart');
    for (final orphan in graph.keys.where(
      (file) => !reachable.contains(file),
    )) {
      failures.add('Unreachable production source: $orphan');
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
