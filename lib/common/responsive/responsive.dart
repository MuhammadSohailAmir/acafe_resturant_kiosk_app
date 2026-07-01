import 'package:flutter/widgets.dart';

/// Breakpoint buckets for the kiosk. The app uses a *hybrid* responsive model:
///
///  - Below [DeviceSize.desktop] (< 1100px) every kiosk screen keeps its
///    original proportional Figma-pixel layout, untouched — small portrait
///    tablets and phones render exactly as before.
///  - At >= 1100px ([isWide]) screens switch to a fixed-pixel, redesigned
///    layout (two-column arrangements, fixed type scale, capped buttons) so
///    large landscape/full-screen kiosk displays look like a proper POS instead
///    of a stretched phone UI.
///
/// This is the single source of truth for that 1100px seam.
enum DeviceSize { phone, tablet, desktop, large }

class Responsive {
  Responsive._();

  static DeviceSize of(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 700) return DeviceSize.phone; // phones, small portrait kiosks
    if (w < 1100) return DeviceSize.tablet; // tablets, standard portrait kiosks
    if (w < 1500) return DeviceSize.desktop; // landscape kiosks
    return DeviceSize.large; // large / full-screen displays
  }

  /// True at/above the 1100px seam — screens use their redesigned wide layout.
  static bool isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  /// Pick a value per breakpoint, falling back to the next-smaller one.
  static T value<T>(
    BuildContext context, {
    required T phone,
    T? tablet,
    T? desktop,
    T? large,
  }) {
    switch (of(context)) {
      case DeviceSize.phone:
        return phone;
      case DeviceSize.tablet:
        return tablet ?? phone;
      case DeviceSize.desktop:
        return desktop ?? tablet ?? phone;
      case DeviceSize.large:
        return large ?? desktop ?? tablet ?? phone;
    }
  }
}
