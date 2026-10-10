import 'package:flutter/material.dart';
import 'package:rolechat/design/app_theme.dart';

class RoleNavigationRail extends StatefulWidget {
  const RoleNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.labels,
    required this.icons,
    required this.onSelected,
    required this.onToggleTheme,
  });
  final int selectedIndex;
  final List<String> labels;
  final List<IconData> icons;
  final ValueChanged<int> onSelected;
  final VoidCallback onToggleTheme;
  @override
  State<RoleNavigationRail> createState() => _RoleNavigationRailState();
}

class _RoleNavigationRailState extends State<RoleNavigationRail> {
  int? hoveredIndex;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: AppTheme.railWidth,
      child: Column(
        children: [
          const SizedBox(height: 4),
          ...List.generate(widget.labels.length, (i) {
            final selected = widget.selectedIndex == i;
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
                      message: widget.labels[i],
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
                            onTap: () => widget.onSelected(i),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: Icon(
                                widget.icons[i],
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
          IconButton(
            tooltip: '切换浅色 / 深色',
            onPressed: widget.onToggleTheme,
            icon: const Icon(Icons.contrast),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
