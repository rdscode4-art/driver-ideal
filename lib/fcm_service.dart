import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import 'core/sound_manager.dart';
import 'routes/app_pages.dart';
import 'core/token_manager.dart';

// Top-level function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📬 Background Message Received!');
  print('📬 Title: ${message.notification?.title}');
  print('📬 Body: ${message.notification?.body}');
  print('📬 Data: ${message.data}');
  print(
    '📬 Channel ID from message: ${message.notification?.android?.channelId}',
  );

  // For data-only messages or to force custom behavior in background
  final title = message.notification?.title?.toLowerCase() ?? '';
  final body = message.notification?.body?.toLowerCase() ?? '';
  final dataType = message.data['type']?.toString().toLowerCase() ?? '';

  if (dataType == 'ride_cancelled') {
    print('🚫 Background Ride Cancelled! Stopping sound and clearing notifications...');
    await FCMService.stopRequestSound();
    return;
  }

  if (dataType.contains('ride') ||
      dataType.contains('booking') ||
      dataType.contains('cancel') ||
      (title.contains('ride') && title.contains('request')) ||
      (title.contains('booking') && title.contains('request')) ||
      title.contains('cancelled') ||
      message.data.containsKey('requestId')) {
    print('✅ Ride criteria matched. Triggering custom notification...');
    await FCMService.showStaticLocalNotification(message);
  } else {
    print(
      '⚠️ Message received but did not match ride criteria. Skipping custom alert.',
    );
  }
}

class FCMService with WidgetsBindingObserver {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // 📢 Stream to notify UI about new ride requests
  static final StreamController<RemoteMessage> rideNotificationStream =
      StreamController<RemoteMessage>.broadcast();

  Future<void> initialize() async {
    try {
      // Add lifecycle observer to stop sounds on app resume
      WidgetsBinding.instance.addObserver(this);
      
      // Also stop sound immediately on fresh app launch just in case it was ringing in background
      FCMService.stopRequestSound();

      // Request permission for iOS
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('📱 Notification Permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('⚠️ User granted provisional permission');
      } else {
        print('❌ User declined notification permission');
        return;
      }

      // Initialize local notifications for Android
      await _initializeLocalNotifications();

      // Get FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        print('🔥🔥🔥 FCM TOKEN 🔥🔥🔥');
        print('📱 $token');
        print('🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥');
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        print('🔄 FCM Token Refreshed: $newToken');
        // TODO: Send updated token to your backend
      });

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check if app was opened from a terminated state via notification
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    } catch (e) {
      print('❌ FCM Initialization Error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('📱 App Resumed: Stopping any background FCM sounds just in case...');
      FCMService.stopRequestSound();
    }
  }

  // Initialize Android notification channel
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        print('🔔 Notification tapped: ${details.payload}');

        // 🎵 Stop all sounds immediately
        FCMService.stopRequestSound();

        // Navigate to appropriate home/dashboard based on user role
        final tokenManager = TokenManager.instance;
        final targetRoute = tokenManager.isNonVehicleDriver
            ? Routes.NONVEHICHLEDASHBOARD
            : Routes.HOME;

        print('🚀 Navigating to $targetRoute from local notification tap...');
        Get.offAllNamed(targetRoute);
      },
    );

    // Create Android notification channel for rides with custom sound (BACKGROUND)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'ride_alerts_v2', // new id to force refresh
      'Ride Requests', // name
      description: 'This channel is used for ride request notifications.',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('sound'),
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // 🆕 Create Android notification channel for rides WITHOUT sound (FOREGROUND)
    const AndroidNotificationChannel silentChannel = AndroidNotificationChannel(
      'ride_alerts_silent', // id
      'Ride Requests (Silent)', // name
      description: 'This channel is used for silent ride request notifications in foreground.',
      importance: Importance.max,
      playSound: false,
      enableVibration: false,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(silentChannel);

    // 🆕 Create a DEFAULT channel for normal notifications (No custom sound)
    const AndroidNotificationChannel defaultChannel =
        AndroidNotificationChannel(
          'default_channel', // id
          'General Notifications', // name
          description: 'This channel is used for general app notifications.',
          importance: Importance.defaultImportance,
          playSound: true,
          // No custom sound here, will use system default
        );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(defaultChannel);
  }

  // Handle messages when app is in FOREGROUND
  void _handleForegroundMessage(RemoteMessage message) {
    print('📬 Foreground Message Received!');
    print('📬 Title: ${message.notification?.title}');
    final title = message.notification?.title?.toLowerCase() ?? '';
    final dataType = message.data['type']?.toString().toLowerCase() ?? '';

    bool isRideRelated =
        dataType.contains('ride') ||
        dataType.contains('booking') ||
        dataType.contains('cancel') ||
        (title.contains('ride') && title.contains('request')) ||
        (title.contains('booking') && title.contains('request')) ||
        title.contains('cancelled') ||
        message.data.containsKey('requestId');

    if (dataType == 'ride_cancelled') {
      print('🚫 Foreground Ride Cancelled! Stopping sound and clearing notifications...');
      FCMService.stopRequestSound();
      // Still add to stream so UI can dismiss dialog
      rideNotificationStream.add(message);
      return; // Do not show local notification for cancellation
    }

    if (isRideRelated) {
      rideNotificationStream.add(message);
    }

    // Show notification even when app is in foreground
    _showLocalNotification(message, isRideRelated);

    // Notification is already shown via _showLocalNotification
    // and processed via rideNotificationStream if it's ride-related.
  }

  // Show local notification for foreground messages
  // Show local notification for foreground messages
  Future<void> _showLocalNotification(
    RemoteMessage message,
    bool isRideRelated,
  ) async {
    // 🆕 If the app is in the foreground and it's a ride request, we DO NOT show the local
    // notification banner at all. The home screen popup will handle it.
    if (isRideRelated) {
      print('🚫 Skipping local notification banner and sound for ride request since app is in foreground.');
      // 🆕 App will rely purely on SoundManager inside homescreennonvehichle.dart to play sound
      return;
    }

    final AndroidNotificationDetails androidDetails = const AndroidNotificationDetails(
      'default_channel',
      'General Notifications',
      channelDescription:
          'This channel is used for general app notifications.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      // No custom sound here, system default will play
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: null,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? 'You have a new message',
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  // Handle when user taps notification (app in background)
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('🔔 Notification Opened!');

    // 🎵 Stop all sounds immediately
    FCMService.stopRequestSound();

    print('📬 Title: ${message.notification?.title}');
    print('📬 Data: ${message.data}');

    final tokenManager = TokenManager.instance;
    final targetRoute = tokenManager.isNonVehicleDriver
        ? Routes.NONVEHICHLEDASHBOARD
        : Routes.HOME;

    // Navigate to ride requests for ANY ride-related notification
    final String type = message.data['type']?.toString().toLowerCase() ?? '';
    final bool hasRequestId =
        message.data.containsKey('requestId') ||
        message.data.containsKey('rideId');

    if (type.contains('ride') || type.contains('new') || hasRequestId) {
      print('🚀 Navigating to $targetRoute (where requests list is)...');
      
      // Push to stream so active controllers instantly refresh without relying on full page reload
      rideNotificationStream.add(message);
      
      if (Get.currentRoute != targetRoute) {
        Get.offAllNamed(targetRoute); // Use offAll to ensure we land on Home
      }
    } else {
      // Default fallback
      if (Get.currentRoute != targetRoute) {
        Get.offAllNamed(targetRoute);
      }
    }
  }

  // Get current FCM token
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  // Delete FCM token (for logout)
  Future<void> deleteToken() async {
    await _messaging.deleteToken();
    print('🗑️ FCM Token deleted');
  }

  // 🎵 Play the custom ride request sound manually (for foreground polling)
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> playRequestSound() async {
    try {
      print('🎵 Playing ride request sound...');
      await _audioPlayer.play(AssetSource('sound.mp3'));
    } catch (e) {
      print('❌ Error playing sound: $e');
    }
  }

  static Future<void> stopRequestSound() async {
    try {
      print('🎵 Stopping ride request sound and clearing notifications...');
      await _audioPlayer.stop();

      // 🆕 Also stop UI SoundManager
      try {
        SoundManager().stopRequestSound();
      } catch (e) {
        print('⚠️ Could not stop SoundManager from FCM: $e');
      }

      // Also clear the notification from tray
      final FlutterLocalNotificationsPlugin localNotifications =
          FlutterLocalNotificationsPlugin();
      await localNotifications.cancelAll();
    } catch (e) {
      print('❌ Error stopping sound/clearing: $e');
    }
  }

  // 🔔 Static method to show notification from background isolate
  static Future<void> showStaticLocalNotification(RemoteMessage message) async {
    final FlutterLocalNotificationsPlugin localNotifications =
        FlutterLocalNotificationsPlugin();

    // 🆕 Initialize for background isolate
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await localNotifications.initialize(
      const InitializationSettings(android: androidSettings),
    );

    // 🆕 Re-create channel in background isolate to be sure
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'ride_alerts_v2',
      'Ride Requests',
      description: 'This channel is used for ride request notifications.',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('sound'),
      enableVibration: true,
      showBadge: true,
    );

    await localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'ride_alerts_v2',
          'Ride Requests',
          channelDescription:
              'This channel is used for ride request notifications.',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('sound'),
          enableVibration: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          ticker: 'New Ride Request',
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'sound.mp3',
        interruptionLevel: InterruptionLevel.critical,
      ),
    );

    await localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Ride Request',
      message.notification?.body ?? 'You have a new ride request available',
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  }
}
