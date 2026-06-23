import 'package:flutter/material.dart';
import 'package:acafe_customer/features/cart/providers/cart_provider.dart';
import 'package:acafe_customer/features/kiosk/domain/kiosk_session.dart';
import 'package:acafe_customer/helper/price_converter_helper.dart';
import 'package:acafe_customer/helper/router_helper.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/utill/dimensions.dart';
import 'package:acafe_customer/utill/styles.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Checkout step 2 — confirm name + total, then Pay (hands off to terminal).
class KioskConfirmScreen extends StatelessWidget {
  const KioskConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final double total = kioskCartTotal(cartProvider.cartList);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    children: [
                      Text(getTranslated('checkout', context) ?? 'Checkout',
                          style: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeOverLarge, color: Theme.of(context).textTheme.bodyLarge!.color)),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text('2', style: rubikSemiBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall)),
                      ),
                      const SizedBox(height: 4),
                      Text(getTranslated('complete_your_order', context) ?? 'Complete your order',
                          style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
                    ],
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: InkWell(
                      onTap: () => context.go(RouterHelper.kioskMenuScreen),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).disabledColor.withValues(alpha: 0.15),
                        child: Icon(Icons.close, size: 20, color: Theme.of(context).textTheme.bodyLarge!.color),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                child: Column(
                  children: [
                    const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                    Text(getTranslated('name', context) ?? 'name', style: rubikRegular.copyWith(color: Theme.of(context).hintColor)),
                    const SizedBox(height: 4),
                    Text(KioskSession.instance.customerName, style: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                    const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                    Text(PriceConverterHelper.convertPrice(total),
                        style: rubikBold.copyWith(fontSize: 32, color: Theme.of(context).textTheme.bodyLarge!.color)),
                    const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                    SizedBox(
                      width: 320,
                      child: _PrimaryPill(label: getTranslated('pay', context) ?? 'Pay', onTap: () => RouterHelper.getKioskPaymentRoute()),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),
                    SizedBox(
                      width: 320,
                      child: _SecondaryPill(label: getTranslated('previous', context) ?? 'PREVIOUS', onTap: () => context.pop()),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).primaryColor,
      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Container(height: 56, alignment: Alignment.center, child: Text(label.toUpperCase(), style: rubikSemiBold.copyWith(color: Colors.white, letterSpacing: 1))),
      ),
    );
  }
}

class _SecondaryPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SecondaryPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).primaryColor.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Container(height: 52, alignment: Alignment.center, child: Text(label.toUpperCase(), style: rubikSemiBold.copyWith(color: Colors.white, letterSpacing: 1))),
      ),
    );
  }
}
