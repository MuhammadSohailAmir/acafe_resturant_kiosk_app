import 'package:flutter/material.dart';
import 'package:acafe_customer/common/models/cart_model.dart';
import 'package:acafe_customer/features/cart/providers/cart_provider.dart';
import 'package:acafe_customer/features/kiosk/domain/kiosk_place_order.dart';
import 'package:acafe_customer/features/kiosk/domain/kiosk_session.dart';
import 'package:acafe_customer/features/kiosk/screens/kiosk_checkout_widgets.dart';
import 'package:acafe_customer/features/kiosk/screens/kiosk_order_line_card.dart';
import 'package:acafe_customer/helper/custom_snackbar_helper.dart';
import 'package:acafe_customer/helper/price_converter_helper.dart';
import 'package:acafe_customer/helper/router_helper.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/utill/styles.dart';
import 'package:provider/provider.dart';

/// How long the "ORDER CONFIRMED!" tick stays up before moving to the QR screen.
const Duration _kConfirmedDisplay = Duration(seconds: 3);

/// Checkout step 3 — PAYMENT: order summary with the live totals breakdown.
/// "COMPLETE ORDER & PAY" places the order, shows a confirmation tick for 3s,
/// then advances to the QR/success screen (Figma nodes 655:3030, 655:3237).
class KioskConfirmScreen extends StatefulWidget {
  const KioskConfirmScreen({super.key});

  @override
  State<KioskConfirmScreen> createState() => _KioskConfirmScreenState();
}

class _KioskConfirmScreenState extends State<KioskConfirmScreen> {
  bool _placing = false;

  Future<void> _complete(double amount) async {
    if (_placing) return;
    setState(() => _placing = true);

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final shownAt = DateTime.now();
    final result = await placeKioskOrder(context, amount: amount);
    if (!mounted) return;

    if (!result.success) {
      setState(() => _placing = false);
      showCustomSnackBarHelper(
        result.message ?? (getTranslated('order_failed', context) ?? 'Order could not be placed'),
        isError: true,
      );
      return;
    }

    KioskSession.instance.lastOrderNumber = '#${result.orderId}';
    KioskSession.instance.lastOrderId = result.orderId;

    // Keep the tick visible for the full display duration before advancing.
    final remaining = _kConfirmedDisplay - DateTime.now().difference(shownAt);
    if (remaining > Duration.zero) await Future.delayed(remaining);
    if (!mounted) return;

    cartProvider.clearCartList();
    RouterHelper.getKioskSuccessRoute(action: RouteAction.pushReplacement);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCheckoutPageBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double s = checkoutScale(constraints.maxWidth);
            return Consumer<CartProvider>(
              builder: (context, cartProvider, _) {
                final cartList = cartProvider.cartList;
                final double total = kioskGrandTotal(cartList);
                return Stack(
                  children: [
                    Column(
                      children: [
                        KioskCheckoutHeader(s: s, activeStep: 2),
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(77 * s, 40 * s, 115 * s, 40 * s),
                            children: [
                              Text(
                                getTranslated('order_summary', context) ?? 'Order summary',
                                textAlign: TextAlign.center,
                                style: loewExtraBold.copyWith(fontSize: 128 * s, height: 1, color: Colors.black),
                              ),
                              SizedBox(height: 50 * s),
                              for (int i = 0; i < cartList.length; i++)
                                if (cartList[i] != null)
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 50 * s),
                                    child: KioskOrderLineCard(s: s, cart: cartList[i]!, index: i),
                                  ),
                            ],
                          ),
                        ),
                        _SummaryFooter(s: s, cartList: cartList, onComplete: () => _complete(total)),
                      ],
                    ),
                    if (_placing) Positioned.fill(child: _ConfirmedOverlay(s: s)),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Dimmed "ORDER CONFIRMED!" tick shown over the summary after placing the order.
class _ConfirmedOverlay extends StatelessWidget {
  final double s;
  const _ConfirmedOverlay({required this.s});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // absorb taps while confirming.
      onTap: () {},
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 1487 * s,
              height: 1487 * s,
              decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(Icons.check_rounded, size: 820 * s, color: Colors.white),
            ),
            SizedBox(height: 120 * s),
            Text(
              getTranslated('order_confirmed', context)?.toUpperCase() ?? 'ORDER CONFIRMED!',
              textAlign: TextAlign.center,
              style: loewExtraBold.copyWith(fontSize: 182 * s, height: 1, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// Totals breakdown (ITEMS TOTAL / DISCOUNT / TAX / TOTAL) + complete button.
class _SummaryFooter extends StatelessWidget {
  final double s;
  final List<CartModel?> cartList;
  final VoidCallback onComplete;
  const _SummaryFooter({required this.s, required this.cartList, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final double items = kioskItemsTotal(cartList);
    final double discount = kioskDiscountTotal(cartList);
    final double tax = kioskTaxTotal(cartList);
    final double total = kioskGrandTotal(cartList);
    final bool enabled = cartList.any((c) => c != null);

    return Container(
      decoration: BoxDecoration(
        color: kCheckoutFieldBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30 * s)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 40 * s, offset: Offset(0, -10 * s)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(107 * s, 69 * s, 57 * s, 60 * s),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BreakdownRow(
            s: s,
            label: getTranslated('items_total', context) ?? 'ITEMS TOTAL',
            value: PriceConverterHelper.convertPrice(items),
          ),
          if (discount > 0) ...[
            SizedBox(height: 18 * s),
            _BreakdownRow(
              s: s,
              label: getTranslated('discount', context) ?? 'DISCOUNT',
              value: '- ${PriceConverterHelper.convertPrice(discount)}',
            ),
          ],
          SizedBox(height: 18 * s),
          _BreakdownRow(
            s: s,
            label: getTranslated('tax', context) ?? 'TAX',
            value: PriceConverterHelper.convertPrice(tax),
          ),
          SizedBox(height: 50 * s),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: Text('TOTAL', style: loewExtraBold.copyWith(fontSize: 200 * s, height: 1, color: Colors.black))),
              Text(
                PriceConverterHelper.convertPrice(total),
                style: loewRegular.copyWith(fontSize: 180 * s, height: 1, color: Colors.black),
              ),
            ],
          ),
          SizedBox(height: 50 * s),
          KioskCheckoutButton(
            s: s,
            label: getTranslated('complete_order_and_pay', context)?.toUpperCase() ?? 'COMPLETE ORDER & PAY',
            filled: true,
            onTap: enabled ? onComplete : null,
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final double s;
  final String label;
  final String value;
  const _BreakdownRow({required this.s, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: loewExtraBold.copyWith(fontSize: 64 * s, color: Colors.black)),
        Text(value, textAlign: TextAlign.right, style: loewRegular.copyWith(fontSize: 100 * s, height: 1, color: Colors.black)),
      ],
    );
  }
}
