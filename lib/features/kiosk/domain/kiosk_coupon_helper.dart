import 'package:flutter/material.dart';
import 'package:acafe_customer/features/auth/providers/auth_provider.dart';
import 'package:acafe_customer/features/kiosk/widgets/kiosk_bottom_sheet.dart';
import 'package:acafe_customer/features/kiosk/widgets/kiosk_coupon_sheet.dart';
import 'package:provider/provider.dart';

/// Ensures a guest account exists so coupon API calls can attach guest_id.
Future<void> ensureKioskGuestForCoupon(BuildContext context) async {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  if (auth.getGuestId() == null) {
    await auth.addGuest();
  }
}

/// Opens the kiosk-styled coupon sheet (responsive narrow + wide layouts).
Future<void> openKioskCouponSheet(
  BuildContext context, {
  required double orderAmount,
}) async {
  await ensureKioskGuestForCoupon(context);
  if (!context.mounted) return;

  return showKioskBottomSheet<void>(
    context,
    maxWidth: KioskCouponSheet.maxSheetWidth,
    heightFactor: 0.55,
    expandToHeightFactor: false,
    child: KioskCouponSheet(orderAmount: orderAmount),
  );
}
