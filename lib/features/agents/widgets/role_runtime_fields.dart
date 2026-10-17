import 'package:flutter/material.dart';
import 'package:rolechat/design/form_metrics.dart';

class RoleRuntimeFields extends StatelessWidget {
  const RoleRuntimeFields({super.key, required this.fields});
  final Map<String, TextEditingController> fields;

  Widget field(String key, {String? label, String? suffix}) => TextField(
    controller: fields[key],
    keyboardType: key == '时区' ? TextInputType.text : TextInputType.number,
    style: FormMetrics.textStyle,
    decoration: FormMetrics.decoration(
      label ?? key,
    ).copyWith(suffixText: suffix),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 420;
      final timezone = field('时区');
      final rounds = field('最大工具轮数');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (narrow) ...[
            timezone,
            const SizedBox(height: 16),
            rounds,
          ] else
            Row(
              children: [
                Expanded(flex: 3, child: timezone),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: rounds),
              ],
            ),
          const SizedBox(height: 20),
          Text('检查间隔', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: field('检查最小间隔（秒）', label: '最短', suffix: '秒'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '—',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: field('检查最大间隔（秒）', label: '最长', suffix: '秒'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '在此范围内随机检查消息。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    },
  );
}
