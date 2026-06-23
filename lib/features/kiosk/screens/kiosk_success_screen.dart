import 'dart:async';
import 'package:flutter/material.dart';
import 'package:acafe_customer/features/kiosk/domain/kiosk_session.dart';
import 'package:acafe_customer/helper/router_helper.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/utill/dimensions.dart';
import 'package:acafe_customer/utill/styles.dart';
import 'package:go_router/go_router.dart';

/// Order placed — shows the order number, then auto-resets to the attract
/// screen for the next customer.
class KioskSuccessScreen extends StatefulWidget {
  const KioskSuccessScreen({super.key});

  @override
  State<KioskSuccessScreen> createState() => _KioskSuccessScreenState();
}

class _KioskSuccessScreenState extends State<KioskSuccessScreen> {
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    _resetTimer = Timer(const Duration(seconds: 8), _reset);
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _reset() {
    KioskSession.instance.reset();
    if (mounted) context.go(RouterHelper.kioskWelcomeScreen);
  }

  @override
  Widget build(BuildContext context) {
    final orderNumber = KioskSession.instance.lastOrderNumber;
    final name = KioskSession.instance.customerName;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Icon(Icons.check_rounded, size: 56, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                Text(
                  getTranslated('thanks_for_your_order', context) ?? 'Thanks for your order',
                  textAlign: TextAlign.center,
                  style: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Theme.of(context).textTheme.bodyLarge!.color),
                ),
                if (name.isNotEmpty) ...[
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Text(name, style: rubikRegular.copyWith(color: Theme.of(context).hintColor)),
                ],
                if (orderNumber != null) ...[
                  const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                  Text(getTranslated('order_number', context) ?? 'Order number', style: rubikRegular.copyWith(color: Theme.of(context).hintColor)),
                  const SizedBox(height: 4),
                  Text(orderNumber, style: rubikBold.copyWith(fontSize: 40, color: Theme.of(context).primaryColor)),
                ],
                const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                TextButton(onPressed: _reset, child: Text(getTranslated('done', context) ?? 'Done')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
