import 'dart:convert';
import 'package:flutter/foundation.dart';

export 'runtime_events.dart';

void consoleRuntimeLog(String event, Map<String, Object?> details) {
  debugPrint(
    '[RoleChat runtime] ${jsonEncode({'time': DateTime.now().toIso8601String(), 'event': event, ...details})}',
  );
}
