import 'package:flutter/material.dart';
import 'package:acafe_customer/common/models/cart_model.dart';
import 'package:acafe_customer/common/widgets/custom_image_widget.dart';
import 'package:acafe_customer/features/cart/providers/cart_provider.dart';
import 'package:acafe_customer/features/kiosk/domain/kiosk_session.dart';
import 'package:acafe_customer/features/kiosk/screens/kiosk_product_customize_sheet.dart';
import 'package:acafe_customer/helper/price_converter_helper.dart';
import 'package:acafe_customer/helper/router_helper.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/features/splash/providers/splash_provider.dart';
import 'package:acafe_customer/utill/images.dart';
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
const Color _kCardBorder = Color(0xFFB9B5A6);
const Color _kPriceColor = Color(0xFF231F20);
const Color _kCheckoutText = Color(0xFFFAF9F5);
const Color _kPlusText = Color(0xFFF3F3DD);

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
                                  child: _CartLineCard(s: s, cart: cartList[i]!, index: i),
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
                child: InkWell(
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
              child: InkWell(
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

/// One cart line: product image, name, price, modifier lines and a qty stepper.
class _CartLineCard extends StatelessWidget {
  final double s;
  final CartModel cart;
  final int index;
  const _CartLineCard({required this.s, required this.cart, required this.index});

  @override
  Widget build(BuildContext context) {
    final splash = Provider.of<SplashProvider>(context, listen: false);
    final modifiers = _modifierLines(context);

    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(30 * s),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Tap a line to edit its options (the design has no explicit Edit button).
        onTap: () => openKioskCustomize(context, cart.product!, cart: cart, cartIndex: index),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30 * s),
            border: Border.all(color: _kCardBorder, width: (1.5 * s).clamp(1.0, 3.0)),
          ),
          padding: EdgeInsets.all(40 * s),
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product image.
          ClipRRect(
            borderRadius: BorderRadius.circular(33 * s),
            child: SizedBox(
              width: 473 * s,
              height: 660 * s,
              child: CustomImageWidget(
                placeholder: Images.placeholderImage,
                image: '${splash.baseUrls?.productImageUrl}/${cart.product?.image}',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 50 * s),
          // Name + price + modifiers.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cart.product?.name ?? '',
                  style: loewExtraBold.copyWith(fontSize: 72 * s, height: 1.05, color: Colors.black),
                ),
                SizedBox(height: 16 * s),
                Text(
                  PriceConverterHelper.convertPrice(kioskLineTotal(cart)),
                  style: swiss721Light.copyWith(fontSize: 90 * s, height: 1, color: _kPriceColor),
                ),
                SizedBox(height: 24 * s),
                for (final line in modifiers)
                  Padding(
                    padding: EdgeInsets.only(bottom: 14 * s),
                    child: Text(line, style: loewRegular.copyWith(fontSize: 64 * s, height: 1.1, color: Colors.black)),
                  ),
              ],
            ),
          ),
          SizedBox(width: 40 * s),
          // Quantity stepper.
          _QtyStepper(
            s: s,
            quantity: cart.quantity ?? 1,
            onDecrement: () {
              final cartProvider = Provider.of<CartProvider>(context, listen: false);
              if ((cart.quantity ?? 1) > 1) {
                cartProvider.onUpdateCartQuantity(index: index, product: cart.product!, isRemove: true);
              } else {
                cartProvider.removeFromCart(index);
              }
            },
            onIncrement: () => Provider.of<CartProvider>(context, listen: false)
                .onUpdateCartQuantity(index: index, product: cart.product!, isRemove: false),
          ),
        ],
          ),
        ),
      ),
    );
  }

  /// Each variation selection and add-on rendered as its own "+ …" line.
  List<String> _modifierLines(BuildContext context) {
    final List<String> lines = [];
    final variations = cart.product?.variations ?? [];
    final selected = cart.variations ?? [];
    for (int g = 0; g < variations.length && g < selected.length; g++) {
      final values = variations[g].variationValues ?? [];
      for (int i = 0; i < values.length && i < selected[g].length; i++) {
        if (selected[g][i] ?? false) {
          lines.add('+ ${values[i].level?.trim()}');
        }
      }
    }
    for (final addOn in cart.addOnIds ?? []) {
      final match = (cart.product?.addOns ?? []).where((a) => a.id == addOn.id);
      if (match.isNotEmpty) {
        final qty = addOn.quantity ?? 1;
        lines.add('+ ${qty > 1 ? '$qty x ' : ''}${match.first.name}');
      }
    }
    return lines;
  }
}

/// Outlined "−", quantity number, filled "+" — matches the design's stepper.
class _QtyStepper extends StatelessWidget {
  final double s;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  const _QtyStepper({
    required this.s,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepBox(s: s, label: '−', filled: false, onTap: onDecrement),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40 * s),
          child: Text('$quantity', style: loewExtraBold.copyWith(fontSize: 90 * s, color: Colors.black)),
        ),
        _StepBox(s: s, label: '+', filled: true, onTap: onIncrement),
      ],
    );
  }
}

class _StepBox extends StatelessWidget {
  final double s;
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _StepBox({required this.s, required this.label, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? Colors.black : Colors.transparent,
      borderRadius: BorderRadius.circular(15 * s),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 150 * s,
          height: 114 * s,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15 * s),
            border: Border.all(color: Colors.black, width: (2.25 * s).clamp(1.5, 4.0)),
          ),
          child: Text(
            label,
            style: loewExtraBold.copyWith(fontSize: 90 * s, height: 1, color: filled ? _kPlusText : Colors.black),
          ),
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
        child: InkWell(
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
