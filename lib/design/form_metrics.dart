import 'package:flutter/material.dart';

abstract final class FormMetrics {
  static const dialogActionStyle = ButtonStyle(
    fixedSize: WidgetStatePropertyAll(Size(104, 40)),
  );
  static const textStyle = TextStyle(fontSize: 16, height: 1.5);
  static const fieldHeight = 48.0;
  static const sectionActionGap = 6.0;

  static InputDecoration decoration(String label) => InputDecoration(
    labelText: label,
    isDense: true,
    constraints: BoxConstraints.tightFor(height: fieldHeight),
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}
