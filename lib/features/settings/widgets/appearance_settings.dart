import 'package:flutter/material.dart';
import 'package:rolechat/shared/widgets/common.dart';
import 'package:rolechat/design/app_theme.dart';

class AppearanceSettings extends StatelessWidget {
  const AppearanceSettings({
    super.key,
    required this.mode,
    required this.seed,
    required this.onModeChanged,
    required this.onSeedChanged,
    required this.onCustomColor,
  });
  final ThemeMode mode;
  final Color seed;
  final ValueChanged<ThemeMode> onModeChanged;
  final ValueChanged<Color> onSeedChanged;
  final VoidCallback onCustomColor;
  @override
  Widget build(BuildContext context) => SettingsSection(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('明暗模式', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.light,
              label: Text('浅色'),
              icon: Icon(Icons.light_mode_outlined),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text('深色'),
              icon: Icon(Icons.dark_mode_outlined),
            ),
            ButtonSegment(
              value: ThemeMode.system,
              label: Text('跟随系统'),
              icon: Icon(Icons.auto_mode_outlined),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (values) => onModeChanged(values.single),
        ),
        const SizedBox(height: 26),
        const Text('主题配色', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 20,
          runSpacing: 16,
          children: List.generate(AppTheme.seeds.length, (i) {
            final color = AppTheme.seeds[i];
            final selected = seed.toARGB32() == color.toARGB32();
            return Semantics(
              label: '${AppTheme.seedNames[i]}配色',
              selected: selected,
              button: true,
              child: InkWell(
                onTap: () => onSeedChanged(color),
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.transparent,
                          width: 0,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppTheme.seedNames[i],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: onCustomColor,
          icon: const Icon(Icons.palette_outlined),
          label: const Text('自定义颜色'),
        ),
      ],
    ),
  );
}
