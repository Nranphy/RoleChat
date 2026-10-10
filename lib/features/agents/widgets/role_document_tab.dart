import 'package:flutter/material.dart';
import 'package:rolechat/shared/widgets/editor_section.dart';

class RoleDocumentTab extends StatelessWidget {
  const RoleDocumentTab({
    super.key,
    required this.controller,
    required this.title,
    required this.explanation,
  });
  final TextEditingController controller;
  final String title, explanation;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      EditorSectionNote(explanation),
      TextField(
        controller: controller,
        minLines: 10,
        maxLines: 20,
        decoration: InputDecoration(labelText: title, alignLabelWithHint: true),
      ),
    ],
  );
}
