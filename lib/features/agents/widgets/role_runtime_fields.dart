import 'package:flutter/material.dart';
import 'package:rolechat/design/form_metrics.dart';

class RoleRuntimeFields extends StatelessWidget {
  const RoleRuntimeFields({
    super.key,
    required this.fields,
    required this.lockSoul,
    required this.lockMemory,
    required this.onSoulLock,
    required this.onMemoryLock,
    required this.scheduleNames,
    required this.lockedSchedules,
    required this.onScheduleLock,
  });
  final Map<String, TextEditingController> fields;
  final bool lockSoul, lockMemory;
  final ValueChanged<bool> onSoulLock, onMemoryLock;
  final Map<String, String> scheduleNames;
  final Set<String> lockedSchedules;
  final void Function(String, bool) onScheduleLock;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final e in fields.entries)
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: TextField(
            controller: e.value,
            keyboardType: e.key == '时区'
                ? TextInputType.text
                : TextInputType.number,
            style: FormMetrics.textStyle,
            decoration: FormMetrics.decoration(e.key),
          ),
        ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('锁定灵魂自动更新'),
        value: lockSoul,
        onChanged: (v) => onSoulLock(v!),
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('锁定记忆自动更新'),
        value: lockMemory,
        onChanged: (v) => onMemoryLock(v!),
      ),
      for (final e in scheduleNames.entries)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('锁定行程：${e.value}'),
          value: lockedSchedules.contains(e.key),
          onChanged: (v) => onScheduleLock(e.key, v!),
        ),
    ],
  );
}
