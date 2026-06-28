import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:acafe_customer/features/address/providers/location_provider.dart';
import 'package:provider/provider.dart';

/// Native browser/OS permission dialogs on kiosk login — no banners, no delays.
class KioskLoginPermissionsHelper {
  KioskLoginPermissionsHelper._();

  static bool _nativePermissionsRequested = false;

  /// Call from [main] on web as soon as Firebase is ready — before [runApp].
  /// Shows notification + location dialogs while the HTML login shell is visible.
  static Future<void> requestNativePermissions() async {
    if (_nativePermissionsRequested) return;
    _nativePermissionsRequested = true;

    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('KioskLoginPermissionsHelper notification: $e');
    }

    try {
      await Geolocator.requestPermission();
    } catch (e) {
      debugPrint('KioskLoginPermissionsHelper location: $e');
    }
  }

  /// After login UI mounts, cache GPS in the background if permission was granted.
  static Future<void> completeOnLoginScreen(BuildContext context) async {
    if (!context.mounted) return;

    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    if (locationProvider.getCachedCurrentLocation() != null) return;

    final permission = await Geolocator.checkPermission();
    if (!context.mounted) return;
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return;
    }

    unawaited(locationProvider.onSelectCurrentLocation(context));
  }
}
