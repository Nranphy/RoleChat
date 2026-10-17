import 'package:flutter/material.dart';

/// Shared page frame for content panels without a separate title bar.
class ContentPage extends StatelessWidget {
  const ContentPage({super.key, required this.child, this.action});
  final Widget child;
  final Widget? action;
  static const panelWidth = 570.0;
  static const panelPadding = 12.0;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, bounds) {
        final wide = bounds.maxWidth > panelWidth;
        return SingleChildScrollView(
          padding: EdgeInsets.all(wide ? 32 : 12),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: panelWidth),
              child: Material(
                key: const ValueKey('content-page-panel'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(wide ? 18 : 0),
                  side: wide
                      ? BorderSide(color: Theme.of(context).dividerColor)
                      : BorderSide.none,
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(panelPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (action != null) ...[
                        Align(alignment: Alignment.centerRight, child: action),
                        const SizedBox(height: 8),
                      ],
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
