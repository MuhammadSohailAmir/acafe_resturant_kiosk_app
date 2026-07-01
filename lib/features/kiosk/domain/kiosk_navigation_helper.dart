import 'package:flutter/material.dart';
import 'package:acafe_customer/helper/router_helper.dart';
import 'package:go_router/go_router.dart';

/// Shared back navigation for kiosk screens (checkout, search, cart, …).
class KioskNavigationHelper {
  KioskNavigationHelper._();

  /// Pops the nearest route (overlay/modal first, then go_router page). Calls
  /// [fallback] when nothing is left to pop — avoids silent no-ops from bare
  /// `context.pop()` on deep links or single-route stacks.
  static void popOrNavigate(BuildContext context, {VoidCallback? fallback}) {
    FocusManager.instance.primaryFocus?.unfocus();

    // Navigator overlays (customize sheet, modal bottom sheets) sit above pages.
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }

    if (fallback != null) {
      fallback();
    } else {
      RouterHelper.getKioskMenuRoute();
    }
  }
}
