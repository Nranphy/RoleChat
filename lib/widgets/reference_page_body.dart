import 'package:flutter/material.dart';

class ReferencePageBody extends StatelessWidget {
  const ReferencePageBody({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final wide = bounds.maxWidth > 570;
      return SingleChildScrollView(
        padding: EdgeInsets.all(wide ? 32 : 12),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 570),
            child: Material(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(wide ? 18 : 0),
                side: wide
                    ? BorderSide(color: Theme.of(context).dividerColor)
                    : BorderSide.none,
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: wide ? 16 : 0,
                ),
                child: child,
              ),
            ),
          ),
        ),
      );
    },
  );
}
