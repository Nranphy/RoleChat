import 'package:flutter/material.dart';
import 'package:rolechat/presentation/theme/form_metrics.dart';
import 'package:rolechat/presentation/shared/widgets/anchored_select.dart';
import 'package:timezone/timezone.dart' as tz;

class RoleRuntimeFields extends StatelessWidget {
  const RoleRuntimeFields({super.key, required this.fields});
  final Map<String, TextEditingController> fields;

  Widget field(String key, {String? label, String? suffix}) => TextField(
    controller: fields[key],
    keyboardType: TextInputType.number,
    style: FormMetrics.textStyle,
    decoration: FormMetrics.decoration(
      label ?? key,
    ).copyWith(suffixText: suffix),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 420;
      final timezone = ValueListenableBuilder<TextEditingValue>(
        valueListenable: fields['时区']!,
        builder: (context, value, _) => AnchoredSelect<String>(
          label: '时区',
          value: value.text,
          options: timezoneOptions(),
          onChanged: (zone) => fields['时区']!.text = zone,
        ),
      );
      final rounds = field('最大工具轮数');
      final probability = Tooltip(
        message: '未匹配行程时使用的基础激活概率，范围为 0～100%。',
        child: field('默认激活概率', suffix: '%'),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (narrow) ...[
            timezone,
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: rounds),
                const SizedBox(width: 16),
                Expanded(child: probability),
              ],
            ),
          ] else
            Row(
              children: [
                Expanded(flex: 3, child: timezone),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: rounds),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: probability),
              ],
            ),
          const SizedBox(height: 16),
          Text('检查间隔（随机）', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
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
        ],
      );
    },
  );
}

Map<String, String> timezoneOptions() {
  const common = {
    'UTC': 'UTC · 协调世界时',
    'Asia/Shanghai': '上海 · Asia/Shanghai',
    'Asia/Hong_Kong': '香港 · Asia/Hong_Kong',
    'Asia/Taipei': '台北 · Asia/Taipei',
    'Asia/Tokyo': '东京 · Asia/Tokyo',
    'Asia/Seoul': '首尔 · Asia/Seoul',
    'Asia/Singapore': '新加坡 · Asia/Singapore',
    'Asia/Kolkata': '加尔各答 · Asia/Kolkata',
    'Australia/Sydney': '悉尼 · Australia/Sydney',
    'Europe/London': '伦敦 · Europe/London',
    'Europe/Paris': '巴黎 · Europe/Paris',
    'America/New_York': '纽约 · America/New_York',
    'America/Los_Angeles': '洛杉矶 · America/Los_Angeles',
  };
  final zones = tz.timeZoneDatabase.locations.keys.toList()..sort();
  return {
    ...common,
    for (final zone in zones)
      if (!common.containsKey(zone)) zone: zone.replaceAll('_', ' '),
  };
}
