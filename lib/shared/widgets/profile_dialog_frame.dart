import 'package:flutter/material.dart';
import '../../design/form_metrics.dart';

/// A tab contributes presentation only; callers retain their editing drafts.
class ProfileDialogTab {
  const ProfileDialogTab(this.label, this.child);
  final String label;
  final Widget child;
}

/// Shared navigation, spacing and actions for role and group editors.
class ProfileDialogFrame extends StatefulWidget {
  const ProfileDialogFrame({
    super.key,
    required this.title,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
    this.formKey,
    required this.onSave,
    required this.saving,
    this.saveLabel = '保存',
    this.maxWidth = 720,
    this.maxHeight = 780,
  });
  final String title, saveLabel;
  final List<ProfileDialogTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final GlobalKey<FormState>? formKey;
  final VoidCallback onSave;
  final bool saving;
  final double maxWidth, maxHeight;
  @override
  State<ProfileDialogFrame> createState() => _ProfileDialogFrameState();
}

class _ProfileDialogFrameState extends State<ProfileDialogFrame>
    with SingleTickerProviderStateMixin {
  late TabController controller;
  @override
  void initState() {
    super.initState();
    controller = TabController(
      length: widget.tabs.length,
      initialIndex: widget.selectedIndex,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(covariant ProfileDialogFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabs.length != widget.tabs.length) {
      controller.dispose();
      controller = TabController(
        length: widget.tabs.length,
        initialIndex: widget.selectedIndex,
        vsync: this,
      );
    } else if (controller.index != widget.selectedIndex) {
      controller.animateTo(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: widget.maxWidth,
        maxHeight: widget.maxHeight,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: '关闭',
                  onPressed: widget.saving
                      ? null
                      : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          TabBar(
            controller: controller,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            onTap: widget.onTabChanged,
            tabs: widget.tabs.map((tab) => Tab(text: tab.label)).toList(),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: widget.formKey == null
                  ? widget.tabs[widget.selectedIndex].child
                  : Form(
                      key: widget.formKey,
                      child: widget.tabs[widget.selectedIndex].child,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: FormMetrics.dialogActionStyle,
                  onPressed: widget.saving
                      ? null
                      : () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FormMetrics.dialogActionStyle,
                  onPressed: widget.saving ? null : widget.onSave,
                  child: Text(widget.saving ? '保存中…' : widget.saveLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
