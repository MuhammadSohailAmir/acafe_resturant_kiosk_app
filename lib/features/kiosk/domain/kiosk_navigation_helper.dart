import 'package:flutter/material.dart';
import 'package:acafe_customer/helper/router_helper.dart';
import 'package:go_router/go_router.dart';

/// Shared back navigation for kiosk screens (checkout, search, cart, …).
class KioskNavigationHelper {
  KioskNavigationHelper._();

  /// Pops the nearest route (modal sheet first, then page). Calls [fallback]
  /// when nothing is left to pop — avoids silent no-ops on deep links.
  static void popOrNavigate(BuildContext context, {VoidCallback? fallback}) {
    FocusManager.instance.primaryFocus?.unfocus();

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
