import 'package:flutter/material.dart';
import '../../main.dart'; // important

void showAppSnackBar(
  String title,
  String message, {
  Color backgroundColor = Colors.red,
}) {
  final messenger = scaffoldMessengerKey.currentState;

  if (messenger == null) {
    debugPrint('❌ ScaffoldMessenger not ready');
    return;
  }

  messenger.clearSnackBars();

  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: backgroundColor,
      margin: const EdgeInsets.all(16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(message, style: const TextStyle(color: Colors.white)),
        ],
      ),
    ),
  );
}
