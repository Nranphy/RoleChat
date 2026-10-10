import 'dart:convert';
import 'package:flutter/material.dart';
import '../design/app_theme.dart';

class RoleAvatar extends StatelessWidget {
  const RoleAvatar(
    this.name, {
    super.key,
    this.color,
    this.size = 48,
    this.imageData,
    this.icon = Icons.person_outline,
  });
  final String name;
  final String? imageData;
  final IconData icon;
  final Color? color;
  final double size;
  @override
  Widget build(BuildContext context) => Material(
    color:
        color ??
        (name.isEmpty
            ? Theme.of(context).colorScheme.secondaryContainer
            : AppTheme.nameColors(name.characters.first).primaryContainer),
    shape: RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(size / 2),
    ),
    clipBehavior: Clip.antiAlias,
    child: SizedBox.square(
      dimension: size,
      child: Center(
        child: imageData == null
            ? name.isNotEmpty &&
                      RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(name)
                  ? ExcludeSemantics(
                      child: Text(
                        name.characters.first.toUpperCase(),
                        style: TextStyle(
                          fontSize: size / 2.5,
                          fontWeight: FontWeight.bold,
                          color: color == null
                              ? Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer
                              : ThemeData.estimateBrightnessForColor(color!) ==
                                    Brightness.light
                              ? Colors.black87
                              : Colors.white,
                        ),
                      ),
                    )
                  : Icon(
                      icon,
                      size: size * .48,
                      color: color == null
                          ? (name.isEmpty
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer
                                : AppTheme.nameColors(
                                    name.characters.first,
                                  ).onPrimaryContainer)
                          : ThemeData.estimateBrightnessForColor(color!) ==
                                Brightness.light
                          ? Colors.black87
                          : Colors.white,
                    )
            : Image.memory(
                base64Decode(imageData!),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stack) => Icon(icon, size: size * .48),
              ),
      ),
    ),
  );
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.subtitle, {super.key, this.action});
  final String title, subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 20,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (subtitle.isNotEmpty) const SizedBox(height: 8),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        ?action,
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.action,
  });
  final String emoji, title, subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RoleAvatar('', size: 88, icon: Icons.inbox_outlined),
          const SizedBox(height: 24),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          ?action,
        ],
      ),
    ),
  );
}

class PreviewNotice extends StatelessWidget {
  const PreviewNotice({super.key, this.text = '界面预览 · 所有角色与对话均为展示数据，未连接模型'});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(
          Icons.science_outlined,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}

void toast(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String body,
  String action = '删除',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    leading: Icon(icon, size: 24),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    trailing: trailing ?? const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

Future<T?> managedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) async {
  final route = DialogRoute<T>(context: context, builder: builder);
  final result = await Navigator.of(context, rootNavigator: true).push(route);
  await route.completed;
  return result;
}

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(8),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}
