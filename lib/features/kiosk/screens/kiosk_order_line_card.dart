import 'package:flutter/material.dart';
import 'package:acafe_customer/common/models/cart_model.dart';
import 'package:acafe_customer/common/widgets/custom_image_widget.dart';
import 'package:acafe_customer/features/cart/providers/cart_provider.dart';
import 'package:acafe_customer/features/kiosk/domain/kiosk_session.dart';
import 'package:acafe_customer/features/kiosk/screens/kiosk_product_customize_sheet.dart';
import 'package:acafe_customer/features/splash/providers/splash_provider.dart';
import 'package:acafe_customer/helper/price_converter_helper.dart';
import 'package:acafe_customer/utill/images.dart';
import 'package:acafe_customer/utill/styles.dart';
import 'package:provider/provider.dart';

// Shared order-line card used by the MY ORDER (cart) and order-summary screens.
// Sizes come from the 2572px-wide Figma artboard, scaled by the caller's `s`.
const Color kOrderCardBg = Color(0xFFFBF8EF);
const Color kOrderCardBorder = Color(0xFFB9B5A6);
const Color kOrderPriceColor = Color(0xFF231F20);
const Color kOrderPlusText = Color(0xFFF3F3DD);

/// One cart line: product image, name, price, modifier lines and a qty stepper.
/// Tapping the card opens the edit sheet; the stepper updates the cart live.
class KioskOrderLineCard extends StatelessWidget {
  final double s;
  final CartModel cart;
  final int index;
  const KioskOrderLineCard({super.key, required this.s, required this.cart, required this.index});

  @override
  Widget build(BuildContext context) {
    final splash = Provider.of<SplashProvider>(context, listen: false);
    final modifiers = _modifierLines();

    return Material(
      color: kOrderCardBg,
      borderRadius: BorderRadius.circular(30 * s),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openKioskCustomize(context, cart.product!, cart: cart, cartIndex: index),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30 * s),
            border: Border.all(color: kOrderCardBorder, width: (1.5 * s).clamp(1.0, 3.0)),
          ),
          padding: EdgeInsets.all(40 * s),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
                      style: swiss721Light.copyWith(fontSize: 90 * s, height: 1, color: kOrderPriceColor),
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
  List<String> _modifierLines() {
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
            style: loewExtraBold.copyWith(fontSize: 90 * s, height: 1, color: filled ? kOrderPlusText : Colors.black),
          ),
        ),
      ),
    );
  }
}
