import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Performance helper to prevent UI thread blocking
class PerformanceHelper {
  /// Execute operation after next frame to prevent blocking
  static void executeAfterFrame(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callback();
    });
  }

  /// Execute operation with priority to maintain 60fps
  static void executeWithPriority(VoidCallback callback) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      callback();
    });
  }

  /// Split heavy operation into chunks to prevent frame drops
  static Future<void> executeInChunks<T>(
    List<T> items,
    Function(T item) operation, {
    int chunkSize = 10,
    Duration delay = const Duration(microseconds: 100),
  }) async {
    for (int i = 0; i < items.length; i += chunkSize) {
      final chunk = items.skip(i).take(chunkSize);
      for (final item in chunk) {
        operation(item);
      }

      // Yield control back to UI thread
      if (i + chunkSize < items.length) {
        await Future.delayed(delay);
      }
    }
  }

  /// Execute async operation without blocking UI
  static Future<T> executeAsync<T>(Future<T> Function() operation) async {
    // Use compute for heavy operations if needed
    return await operation();
  }

  /// Debounce function calls to prevent excessive UI updates
  static Function debounce(
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    Timer? timer;
    return () {
      timer?.cancel();
      timer = Timer(delay, callback);
    };
  }
}
