import 'app_shell.dart';
import 'package:flutter/material.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/design/app_theme.dart';

class RoleNavigationRail extends StatefulWidget {
  const RoleNavigationRail({super.key, required this.store});
  final PreviewStore store;
  @override
  State<RoleNavigationRail> createState() => RoleNavigationRailState();
}

class RoleNavigationRailState extends State<RoleNavigationRail> {
  int? hoveredIndex;
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: AppTheme.railWidth,
      child: Column(
        children: [
          const SizedBox(height: 4),
          ...List.generate(AppShell.labels.length, (i) {
            final selected = store.destination == i;
            return SizedBox(
              height: 64,
              child: Stack(
                children: [
                  if (selected)
                    Positioned(
                      left: 0,
                      top: 8,
                      bottom: 8,
                      child: Container(
                        width: 8,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(90),
                          ),
                        ),
                      ),
                    ),
                  Center(
                    child: Tooltip(
                      message: AppShell.labels[i],
                      child: MouseRegion(
                        onEnter: (_) => setState(() => hoveredIndex = i),
                        onExit: (_) => setState(() {
                          if (hoveredIndex == i) hoveredIndex = null;
                        }),
                        child: Material(
                          key: ValueKey(i),
                          color: selected
                              ? colors.secondaryContainer
                              : hoveredIndex == i
                              ? colors.surfaceContainerHigh
                              : colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            AppTheme.cornerRadius,
                          ),
                          child: InkWell(
                            overlayColor: const WidgetStatePropertyAll(
                              Colors.transparent,
                            ),
                            splashFactory: NoSplash.splashFactory,
                            borderRadius: BorderRadius.circular(
                              AppTheme.cornerRadius,
                            ),
                            onTap: () => store.navigate(i),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: Icon(
                                AppShell.icons[i],
                                color: selected
                                    ? colors.onSecondaryContainer
                                    : colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const Spacer(),
          const Tooltip(
            message: '界面预览，未连接模型',
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.science_outlined, size: 20),
            ),
          ),
          IconButton(
            tooltip: '切换浅色 / 深色',
            onPressed: () => store.setMode(
              Theme.of(context).brightness == Brightness.dark
                  ? ThemeMode.light
                  : ThemeMode.dark,
            ),
            icon: const Icon(Icons.contrast),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
