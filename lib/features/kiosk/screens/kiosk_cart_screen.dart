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
import 'package:acafe_customer/utill/dimensions.dart';
import 'package:acafe_customer/utill/images.dart';
import 'package:acafe_customer/utill/styles.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// "MY ORDER" — review the cart, edit/remove lines, then go to checkout.
class KioskCartScreen extends StatelessWidget {
  const KioskCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<CartProvider>(
          builder: (context, cartProvider, _) {
            final cartList = cartProvider.cartList;
            final double total = kioskCartTotal(cartList);
            final int itemCount = kioskCartItemCount(cartList);

            return Column(
              children: [
                // Header.
                Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        getTranslated('my_order', context) ?? 'MY ORDER',
                        style: rubikSemiBold.copyWith(
                          fontSize: Dimensions.fontSizeOverLarge,
                          color: Theme.of(context).textTheme.bodyLarge!.color,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () => context.pop(),
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

                // Lines.
                Expanded(
                  child: cartList.isEmpty
                      ? Center(
                          child: Text(
                            getTranslated('empty_cart', context) ?? 'Empty cart',
                            style: rubikRegular.copyWith(color: Theme.of(context).hintColor),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                          itemCount: cartList.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
                          itemBuilder: (context, index) => _CartLine(cart: cartList[index]!, index: index),
                        ),
                ),

                // Footer.
                _Footer(itemCount: itemCount, total: total, enabled: cartList.isNotEmpty),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  final CartModel cart;
  final int index;
  const _CartLine({required this.cart, required this.index});

  @override
  Widget build(BuildContext context) {
    final splash = Provider.of<SplashProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CustomImageWidget(
              placeholder: Images.placeholderImage,
              image: '${splash.baseUrls?.productImageUrl}/${cart.product?.image}',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),

          // Name + modifier chips.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cart.product?.name ?? '', style: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                const SizedBox(height: 2),
                Text(
                  PriceConverterHelper.convertPrice(kioskLineTotal(cart)),
                  style: rubikRegular.copyWith(color: Theme.of(context).hintColor),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _modifierChips(context).map((t) => _Chip(text: t)).toList(),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                InkWell(
                  onTap: () => openKioskCustomize(context, cart.product!, cart: cart, cartIndex: index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                      border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(getTranslated('edit', context) ?? 'Edit', style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
                  ),
                ),
              ],
            ),
          ),

          // Trash + qty stepper.
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              InkWell(
                onTap: () => cartProvider.removeFromCart(index),
                child: Icon(Icons.delete_outline, color: Theme.of(context).hintColor),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Row(
                children: [
                  _RoundIcon(
                    icon: Icons.remove,
                    onTap: () => cartProvider.onUpdateCartQuantity(index: index, product: cart.product!, isRemove: true),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                    child: Text('${cart.quantity}', style: rubikSemiBold),
                  ),
                  _RoundIcon(
                    icon: Icons.add,
                    filled: true,
                    onTap: () => cartProvider.onUpdateCartQuantity(index: index, product: cart.product!, isRemove: false),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _modifierChips(BuildContext context) {
    final List<String> chips = [];
    // Variation selections.
    final variations = cart.product?.variations ?? [];
    final selected = cart.variations ?? [];
    for (int g = 0; g < variations.length && g < selected.length; g++) {
      final values = variations[g].variationValues ?? [];
      for (int i = 0; i < values.length && i < selected[g].length; i++) {
        if (selected[g][i] ?? false) {
          final price = values[i].optionPrice ?? 0;
          chips.add('${values[i].level?.trim()}${price > 0 ? ' +${PriceConverterHelper.convertPrice(price)}' : ''}');
        }
      }
    }
    // Add-ons with quantity.
    for (final addOn in cart.addOnIds ?? []) {
      final match = (cart.product?.addOns ?? []).where((a) => a.id == addOn.id);
      if (match.isNotEmpty) {
        final qty = addOn.quantity ?? 1;
        final linePrice = (match.first.price ?? 0) * qty;
        chips.add('${qty > 1 ? '$qty x ' : ''}${match.first.name} +${PriceConverterHelper.convertPrice(linePrice)}');
      }
    }
    return chips;
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      ),
      child: Text(text, style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).textTheme.bodyLarge!.color)),
    );
  }
}

class _Footer extends StatelessWidget {
  final int itemCount;
  final double total;
  final bool enabled;
  const _Footer({required this.itemCount, required this.total, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _Pill(
                  label: getTranslated('order_more', context) ?? 'Order more…',
                  icon: Icons.arrow_back,
                  filled: false,
                  onTap: () => context.pop(),
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(
                child: _Pill(
                  label: getTranslated('go_to_checkout', context) ?? 'Go to checkout',
                  icon: Icons.arrow_forward,
                  iconTrailing: true,
                  filled: true,
                  onTap: enabled ? () => RouterHelper.getKioskCheckoutRoute() : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$itemCount ${getTranslated('items', context) ?? 'items'}',
                  style: rubikSemiBold.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color)),
              Text(PriceConverterHelper.convertPrice(total),
                  style: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool iconTrailing;
  final bool filled;
  final VoidCallback? onTap;
  const _Pill({required this.label, this.icon, this.iconTrailing = false, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final disabled = onTap == null;
    return Material(
      color: disabled
          ? Theme.of(context).disabledColor.withValues(alpha: 0.1)
          : filled
              ? primary
              : Theme.of(context).disabledColor.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null && !iconTrailing) ...[Icon(icon, size: 18, color: filled ? Colors.white : Theme.of(context).textTheme.bodyLarge!.color), const SizedBox(width: 6)],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: rubikSemiBold.copyWith(color: filled ? Colors.white : Theme.of(context).textTheme.bodyLarge!.color),
                ),
              ),
              if (icon != null && iconTrailing) ...[const SizedBox(width: 6), Icon(icon, size: 18, color: filled ? Colors.white : Theme.of(context).textTheme.bodyLarge!.color)],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  const _RoundIcon({required this.icon, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(shape: BoxShape.circle, color: filled ? primary : primary.withValues(alpha: 0.1)),
        child: Icon(icon, size: 18, color: filled ? Colors.white : primary),
      ),
    );
  }
}
