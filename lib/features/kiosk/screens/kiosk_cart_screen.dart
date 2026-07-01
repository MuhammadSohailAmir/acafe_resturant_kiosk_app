import 'package:flutter/material.dart';
import 'package:acafe_customer/features/cart/providers/cart_provider.dart';
import 'package:acafe_customer/features/kiosk/domain/kiosk_session.dart';
import 'package:acafe_customer/features/kiosk/widgets/kiosk_tap.dart';
import 'package:acafe_customer/features/kiosk/screens/kiosk_order_line_card.dart';
import 'package:acafe_customer/helper/price_converter_helper.dart';
import 'package:acafe_customer/helper/router_helper.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/utill/styles.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// ===========================================================================
// MY ORDER (cart) — faithful, fully-responsive port of the Figma design
// (node 582:9426). All sizes come straight from the 2572px-wide artboard and
// are scaled by `s = screenWidth / _kDesignWidth`.
// ===========================================================================
const double _kDesignWidth = 2572;
const Color _kPageBg = Color(0xFFF7F1DE);
const Color _kCardBg = Color(0xFFFBF8EF);
const Color _kCheckoutText = Color(0xFFFAF9F5);

double _scaleFor(double w) => w / _kDesignWidth;

/// "MY ORDER" — review the cart, edit/remove lines, then go to checkout.
class KioskCartScreen extends StatelessWidget {
  const KioskCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPageBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double s = _scaleFor(constraints.maxWidth);
            return Consumer<CartProvider>(
              builder: (context, cartProvider, _) {
                final cartList = cartProvider.cartList;
                final double total = kioskCartTotal(cartList);
                final int itemCount = kioskCartItemCount(cartList);

                return Column(
                  children: [
                    _TopBar(s: s),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(132 * s, 40 * s, 60 * s, 40 * s),
                        children: [
                          Text('MY ORDER', style: loewExtraBold.copyWith(fontSize: 128 * s, height: 1, color: Colors.black)),
                          SizedBox(height: 12 * s),
                          Text(
                            '${getTranslated('dine_in', context) ?? 'Dine in'} / $itemCount ${getTranslated('items', context) ?? 'items'}',
                            style: scotchDisplayLight.copyWith(fontSize: 88 * s, height: 1, color: Colors.black),
                          ),
                          SizedBox(height: 40 * s),
                          if (cartList.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 200 * s),
                              child: Center(
                                child: Text(
                                  getTranslated('empty_cart', context) ?? 'Empty cart',
                                  style: loewRegular.copyWith(fontSize: 64 * s, color: Colors.black54),
                                ),
                              ),
                            )
                          else
                            for (int i = 0; i < cartList.length; i++)
                              if (cartList[i] != null)
                                Padding(
                                  padding: EdgeInsets.only(bottom: 42 * s),
                                  child: KioskOrderLineCard(s: s, cart: cartList[i]!, index: i),
                                ),
                        ],
                      ),
                    ),
                    _Footer(s: s, total: total, enabled: cartList.isNotEmpty),
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

/// Top bar: back button (left), centered A/CAFÉ brand, language toggle (right).
class _TopBar extends StatelessWidget {
  final double s;
  const _TopBar({required this.s});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(132 * s, 40 * s, 132 * s, 10 * s),
      child: SizedBox(
        height: 141 * s,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text('A/CAFÉ', style: loewExtraBold.copyWith(fontSize: 90 * s, letterSpacing: 2 * s, color: Colors.black)),
            Align(
              alignment: Alignment.centerLeft,
              child: Material(
                color: Colors.transparent,
                shape: CircleBorder(side: BorderSide(color: Colors.black, width: (4 * s).clamp(2.0, 6.0))),
                clipBehavior: Clip.antiAlias,
                child: KioskTap(
                  onTap: () => context.pop(),
                  child: SizedBox(
                    width: 141 * s,
                    height: 141 * s,
                    child: Icon(Icons.arrow_back_ios_new, size: 56 * s, color: Colors.black),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: KioskTap(
                onTap: () => RouterHelper.getLanguageRoute(true),
                child: Padding(
                  padding: EdgeInsets.all(10 * s),
                  child: Text('A 文', style: loewExtraBold.copyWith(fontSize: 56 * s, color: Colors.black)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Footer: TOTAL + price, then ADD COUPON (outlined) and CHECK OUT (filled).
class _Footer extends StatelessWidget {
  final double s;
  final double total;
  final bool enabled;
  const _Footer({required this.s, required this.total, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40 * s)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 45 * s, offset: Offset(0, -15 * s)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(132 * s, 50 * s, 60 * s, 40 * s),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text('TOTAL', style: loewExtraBold.copyWith(fontSize: 150 * s, height: 1, color: Colors.black)),
              ),
              Text(
                PriceConverterHelper.convertPrice(total),
                style: loewRegular.copyWith(fontSize: 130 * s, height: 1, color: Colors.black),
              ),
            ],
          ),
          SizedBox(height: 40 * s),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _FooterButton(
                    s: s,
                    label: getTranslated('add_coupon', context) ?? 'ADD COUPON',
                    filled: false,
                    onTap: () {/* TODO: hook up coupon entry */},
                  ),
                ),
                SizedBox(width: 40 * s),
                Expanded(
                  child: _FooterButton(
                    s: s,
                    label: getTranslated('check_out', context) ?? 'CHECK OUT',
                    filled: true,
                    onTap: enabled ? () => RouterHelper.getKioskCheckoutRoute() : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final double s;
  final String label;
  final bool filled;
  final VoidCallback? onTap;
  const _FooterButton({required this.s, required this.label, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: filled ? Colors.black : Colors.transparent,
        borderRadius: BorderRadius.circular(30 * s),
        clipBehavior: Clip.antiAlias,
        child: KioskTap(
          onTap: onTap,
          child: Container(
            height: 252 * s,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30 * s),
              border: filled ? null : Border.all(color: Colors.black, width: (8 * s).clamp(2.0, 10.0)),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: (filled ? loewExtraBold : loewBold).copyWith(
                fontSize: 72 * s,
                letterSpacing: 1,
                color: filled ? _kCheckoutText : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
