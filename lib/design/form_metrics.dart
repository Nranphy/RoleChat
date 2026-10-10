import 'package:flutter/material.dart';

abstract final class FormMetrics {
  static const textStyle = TextStyle(fontSize: 16, height: 1.5);
  static const fieldHeight = 48.0;
  static const compactFieldHeight = 40.0;
  static const sectionActionGap = 12.0;

  static InputDecoration decoration(String label, {bool compact = false}) =>
      InputDecoration(
        labelText: label,
        isDense: true,
        constraints: BoxConstraints.tightFor(
          height: compact ? compactFieldHeight : fieldHeight,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: compact ? 8 : 12,
        ),
      );
}
