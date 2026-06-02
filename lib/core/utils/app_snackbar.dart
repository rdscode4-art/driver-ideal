import 'package:flutter/material.dart';
import '../../main.dart';

/// Safe global snackbar that uses the app-level [scaffoldMessengerKey].
/// This is crash-safe unlike [Get.snackbar] which throws
/// [LateInitializationError] on [SnackbarController._animation]
/// when called during navigation transitions or the first warm-up frame.
void showAppSnackBar(
  String title,
  String message, {
  Color backgroundColor = Colors.red,
  Duration duration = const Duration(seconds: 3),
  IconData? icon,
}) {
  scaffoldMessengerKey.currentState
    ?..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        margin: const EdgeInsets.all(16),
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
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
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
}

void showSuccessSnackBar(String message, {String title = 'Success'}) {
  showAppSnackBar(
    title,
    message,
    backgroundColor: Colors.green[600]!,
    icon: Icons.check_circle,
  );
}

void showErrorSnackBar(String message, {String title = 'Error'}) {
  showAppSnackBar(
    title,
    message,
    backgroundColor: Colors.red[600]!,
    icon: Icons.error,
  );
}

void showWarningSnackBar(String message, {String title = 'Warning'}) {
  showAppSnackBar(
    title,
    message,
    backgroundColor: Colors.orange[600]!,
    icon: Icons.warning,
  );
}

void showInfoSnackBar(String message, {String title = 'Info'}) {
  showAppSnackBar(
    title,
    message,
    backgroundColor: Colors.blue[600]!,
    icon: Icons.info,
  );
}
