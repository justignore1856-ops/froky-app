import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../bloc/device_sync_bloc/device_sync_bloc.dart';
import '../firebase_options.dart';
import '../router/app_routes.dart';
import '../screens/notification_page/bloc/notification_bloc.dart';
import '../screens/payment_confirmation/service/payment_event_bus.dart';
import '../screens/payment_options/model/payment_status.dart';
import '../screens/product_listing_page/model/product_listing_type.dart';
import '../screens/support_page/service/support_route_presence.dart';
import 'dependency_injection_container.dart';
import 'global.dart';
import 'global_keys.dart';
import 'helper.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('Background message received: ${message.messageId}');

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Let FCM handle the notification display using the custom channel we created.
  if (message.notification == null) {
    log('Silent/data-only notification received in background');
  } else {
    log('Standard notification will be shown by FCM using custom channel');
  }
}

class NotificationService {
  NotificationService();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> _createCustomNotificationChannel() async {
    const String channelId = 'custom_sound_channel';
    const String channelName = 'Custom Sound Notifications';
    const String channelDescription = 'Notifications with custom sound for orders and updates';

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    log('✅ Custom notification channel created: $channelId with sound: notification_sound');
  }

  Future<void> initFirebaseMessaging(BuildContext context) async {
    await _requestNotificationPermissions();

    // ← Important: Create channel BEFORE initializing local notifications
    await _createCustomNotificationChannel();

    // Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('notification');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        log('Notification tapped: ${response.payload}');
        if (response.payload != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            handleNotificationNavigation(data);
          } catch (e) {
            log('Error parsing notification payload: $e');
          }
        }
      },
    );

    // Background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('📱 Foreground notification received');
      _emitPaymentEvent(message);
      _showForegroundNotification(message);
    });

    // When app is opened from notification (background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('App opened from notification');
      handleNotificationNavigation(message.data);
    });

    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        handleNotificationNavigation(initialMessage.data);
      });
    }

    _firebaseMessaging.onTokenRefresh.listen((String newToken) {
      log('New FCM Token: $newToken');
      if (Global.userData != null && Global.userData!.token.isNotEmpty) {
        getIt<DeviceSyncBloc>().add(SyncDevice(
          deviceType: Platform.isAndroid ? 'android' : 'ios',
          previousToken: Global.userData?.fcm ?? '',
          roleType: 'customer',
        ));
      }
    });
  }

  Future<void> _requestNotificationPermissions() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<String?> getFcmToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Surfaces payment-status pushes to the confirming-payment screen.
  void _emitPaymentEvent(RemoteMessage message) {
    if (message.data['type']?.toString() != 'payment') return;
    final slug = message.data['order_slug']?.toString() ?? '';
    if (slug.isEmpty) return;
    PaymentEventBus.instance.emit(PaymentPushEvent(
      orderSlug: slug,
      paymentStatus:
          OrderPaymentStatus.fromString(message.data['payment_status']?.toString()),
    ));
  }

  /// Shows notification when app is in foreground
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (message.notification == null) return;
    if (message.data['type']?.toString() == 'support_message' &&
        SupportRoutePresence.isViewing(
          message.data['thread_uuid']?.toString(),
        )) {
      return;
    }

    final imageUrl =
        message.notification?.android?.imageUrl ??
            message.notification?.apple?.imageUrl ??
            message.data['image'];

    BigPictureStyleInformation? bigPictureStyle;
    final List<DarwinNotificationAttachment> iosAttachments = [];
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final fileName = 'notif_image${_imageExtensionFromUrl(imageUrl)}';
      final filePath = await downloadAndSaveImage(imageUrl, fileName);
      bigPictureStyle = BigPictureStyleInformation(
        FilePathAndroidBitmap(filePath),
        largeIcon: const DrawableResourceAndroidBitmap('@drawable/notification'),
        contentTitle: message.notification?.title,
        summaryText: message.notification?.body,
      );
      iosAttachments.add(DarwinNotificationAttachment(filePath));
    }
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'custom_sound_channel', // Must match the channel created above
      'Custom Sound Notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@drawable/notification',
      styleInformation: bigPictureStyle,
      largeIcon: const DrawableResourceAndroidBitmap('@drawable/notification'),
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      fullScreenIntent: true,
      enableVibration: true,
      enableLights: true,
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.caf',
      attachments: iosAttachments,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: convertIntFromType(message),
      title: message.notification?.title ?? 'No Title',
      body: message.notification?.body ?? 'No Body',
      notificationDetails: notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  /// Returns a leading-dot file extension (e.g.
  String _imageExtensionFromUrl(String url) {
    const allowed = {'.jpg', '.jpeg', '.png', '.gif'};
    final uri = Uri.tryParse(url);
    if (uri == null || uri.pathSegments.isEmpty) return '.jpg';
    final lastSegment = uri.pathSegments.last;
    final dotIndex = lastSegment.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == lastSegment.length - 1) return '.jpg';
    final candidate = '.${lastSegment.substring(dotIndex + 1).toLowerCase()}';
    return allowed.contains(candidate) ? candidate : '.jpg';
  }

  int convertIntFromType(RemoteMessage message) {
    final type = message.data['type']?.toString();
    if (type == 'new_order' || type == 'order_update' || type == 'return_order' || type == 'return_order_update') {
      return 1;
    } else if (type == 'wallet_transaction') {
      return 2;
    } else if (type == 'support_message') {
      return 3;
    }
    return 1;
  }

  static String notificationSlugTypeUpdate(String typeValue) {
    if (typeValue == 'order' ||
        typeValue == 'delivery' ||
        typeValue == 'new_order' ||
        typeValue == 'order_update' ||
        typeValue == 'Delivered' ||
        typeValue == 'return_order' ||
        typeValue == 'return_order_update') {
      return 'order_slug';
    } else if (typeValue == 'product' ||
        typeValue == 'featured_section' ||
        typeValue == 'brand' ||
        typeValue == 'category' ||
        typeValue == 'store') {
      return 'slug';
    }
    return 'slug';
  }

  static void handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    if (type == null) return;

    final navigatorContext = GlobalKeys.navigatorKey.currentContext;

    if (navigatorContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final retryContext = GlobalKeys.navigatorKey.currentContext;
        if (retryContext != null) handleNotificationNavigation(data);
      });
      return;
    }

    final notificationId = data['notification_id']?.toString();
    if (notificationId != null &&
        notificationId.isNotEmpty &&
        notificationId != 'null') {
      navigatorContext.read<NotificationBloc>().add(
            MarkAsReadSpecificNotification(notificationId: notificationId),
          );
    }

    if (type == 'support_message') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        GoRouter.of(navigatorContext).push(
          AppRoutes.supportPage,
          extra: {'ticket-slug': data['ticket_slug']?.toString()},
        );
      });
      return;
    }

    final slugType = notificationSlugTypeUpdate(type);
    final slugValue = data[slugType]?.toString() ?? '';
    final orderItemId = data['order_item_id']?.toString() ?? '';
    final title = data['title']?.toString() ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (slugType == 'order_slug') {
        if (type == 'order'
            || type == 'delivery'
            || type == 'new_order'
            || type == 'order_update'
            || type == 'Delivered'
            || type == 'return_order'
            || type == 'return_order_update') {
          if (slugValue.isNotEmpty) {
            GoRouter.of(navigatorContext).push(
              AppRoutes.orderItemDetail,
              extra: {
                'order-slug': slugValue,
                'order-item-id': orderItemId,
              },
            );
          }
        }
      } else if (slugType == 'slug') {
        switch (type) {
          case 'product':
            GoRouter.of(navigatorContext).push(
              AppRoutes.productDetailPage,
              extra: {'productSlug': slugValue},
            );
            break;
          case 'featured_section':
            GoRouter.of(navigatorContext).push(
              AppRoutes.productListing,
              extra: {
                'isTheirMoreCategory': false,
                'title': title,
                'logo': '',
                'totalProduct': 10,
                'type': ProductListingType.featuredSection,
                'identifier': slugValue,
              },
            );
            break;
          case 'category':
            GoRouter.of(navigatorContext).push(
              AppRoutes.productListing,
              extra: {
                'isTheirMoreCategory': false,
                'title': title,
                'logo': data['image']?.toString() ?? '',
                'totalProduct': 10,
                'type': ProductListingType.category,
                'identifier': slugValue,
              },
            );
            break;
          case 'brand':
            GoRouter.of(navigatorContext).push(
              AppRoutes.productListing,
              extra: {
                'isTheirMoreCategory': false,
                'title': title,
                'logo': data['image']?.toString() ?? '',
                'totalProduct': 10,
                'type': ProductListingType.brand,
                'identifier': slugValue,
              },
            );
            break;
          case 'store':
            GoRouter.of(navigatorContext).push(
              AppRoutes.nearbyStoreDetails,
              extra: {
                'store-slug': slugValue,
                'store-name': title,
              },
            );
            break;
          case 'wallet_transaction':
            GoRouter.of(navigatorContext).push(AppRoutes.transactions);
            break;
        }
      }
    });
  }
}

// Separate function for getting token (kept as is, but improved slightly)
Future<String?> getFCMToken() async {
  try {
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (Platform.isIOS) {
        await Future.delayed(const Duration(seconds: 2));
      }

      final fcmToken = await FirebaseMessaging.instance.getToken();
      log('FCM Token: $fcmToken');
      return fcmToken;
    } else {
      log('User declined notification permissions');
      return null;
    }
  } catch (e) {
    log('Error getting FCM token: $e');
    return null;
  }
}
