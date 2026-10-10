import 'package:flutter/material.dart';

class CheckResultNote extends StatelessWidget {
  const CheckResultNote({
    super.key,
    required this.message,
    required this.success,
  });
  final String message;
  final bool success;
  @override
  Widget build(BuildContext context) => Text(
    message,
    style: TextStyle(
      fontSize: 12,
      color: success
          ? (Theme.of(context).brightness == Brightness.dark
                ? Colors.green.shade300
                : Colors.green.shade700)
          : Theme.of(context).colorScheme.error,
    ),
  );
}
