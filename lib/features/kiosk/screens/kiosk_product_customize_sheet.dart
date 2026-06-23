import 'package:flutter/material.dart';
import 'package:acafe_customer/common/models/cart_model.dart';
import 'package:acafe_customer/common/models/product_model.dart';
import 'package:acafe_customer/common/providers/product_provider.dart';
import 'package:acafe_customer/common/widgets/custom_image_widget.dart';
import 'package:acafe_customer/features/cart/providers/cart_provider.dart';
import 'package:acafe_customer/helper/custom_snackbar_helper.dart';
import 'package:acafe_customer/helper/price_converter_helper.dart';
import 'package:acafe_customer/helper/product_helper.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/features/splash/providers/splash_provider.dart';
import 'package:acafe_customer/utill/dimensions.dart';
import 'package:acafe_customer/utill/images.dart';
import 'package:acafe_customer/utill/styles.dart';
import 'package:provider/provider.dart';

/// Entry point: tap a product in the kiosk menu -> open the customization flow.
///
/// Reuses the existing [ProductProvider] customization state and the existing
/// [CartModel] / [CartProvider.addToCart] pipeline, so a kiosk order is
/// identical to a web order. Products with no variations and no add-ons are
/// added straight to the cart (e.g. merchandise).
void openKioskCustomize(BuildContext context, Product product, {CartModel? cart, int? cartIndex}) {
  final productProvider = Provider.of<ProductProvider>(context, listen: false);
  productProvider.initData(product, cart);
  productProvider.initProductVariationStatus(product.variations?.length ?? 0);

  final variations = product.variations ?? [];
  final addOns = product.addOns ?? [];

  if (cart == null && variations.isEmpty && addOns.isEmpty) {
    // No modifiers -> add directly.
    Provider.of<CartProvider>(context, listen: false)
        .addToCart(buildKioskCartModel(context, product), productProvider.cartIndex);
    showCustomSnackBarHelper(getTranslated('added_to_cart', context), isError: false);
    return;
  }

  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => KioskProductCustomizeSheet(product: product, cartIndex: cartIndex),
  );
}

/// Builds the cart line from the current [ProductProvider] selection state.
/// Mirrors the math in the web app's CartBottomSheetWidget so prices match.
CartModel buildKioskCartModel(BuildContext context, Product product) {
  final productProvider = Provider.of<ProductProvider>(context, listen: false);

  final branch = ProductHelper.getBranchProductVariationWithPrice(product);
  final List<Variation> variationList = branch.variatins ?? [];
  final double price = branch.price ?? 0;

  double variationPrice = 0;
  for (int index = 0; index < variationList.length; index++) {
    for (int i = 0; i < variationList[index].variationValues!.length; i++) {
      if (productProvider.selectedVariations[index][i] ?? false) {
        variationPrice += variationList[index].variationValues![i].optionPrice!;
      }
    }
  }

  final double? discount = product.discount;
  final String? discountType = product.discountType;
  final double priceWithDiscount =
      PriceConverterHelper.convertWithDiscount(price, discount, discountType)!;

  final List<AddOn> addOnIdList = [];
  for (int index = 0; index < (product.addOns?.length ?? 0); index++) {
    if (productProvider.addOnActiveList[index]) {
      addOnIdList.add(AddOn(id: product.addOns![index].id, quantity: productProvider.addOnQtyList[index]));
    }
  }

  final double priceWithVariation = price + variationPrice;
  final double discountAmount = priceWithVariation -
      PriceConverterHelper.convertWithDiscount(priceWithVariation, discount, discountType)!;

  return CartModel(
    priceWithVariation,
    priceWithDiscount,
    [],
    discountAmount,
    productProvider.quantity,
    (priceWithVariation - discountAmount) -
        PriceConverterHelper.convertWithDiscount(
            priceWithVariation - discountAmount, product.tax, product.taxType)!,
    addOnIdList,
    product,
    productProvider.selectedVariations,
  );
}

class KioskProductCustomizeSheet extends StatefulWidget {
  final Product product;
  final int? cartIndex;
  const KioskProductCustomizeSheet({super.key, required this.product, this.cartIndex});

  @override
  State<KioskProductCustomizeSheet> createState() => _KioskProductCustomizeSheetState();
}

class _KioskProductCustomizeSheetState extends State<KioskProductCustomizeSheet> {
  int _step = 0;

  /// One step per variation group, plus a final "extras" step if add-ons exist.
  late final List<Variation> _variations = widget.product.variations ?? [];
  late final bool _hasAddons = (widget.product.addOns ?? []).isNotEmpty;
  int get _stepCount => _variations.length + (_hasAddons ? 1 : 0);
  bool get _isAddonStep => _hasAddons && _step == _variations.length;
  bool get _isLastStep => _step == _stepCount - 1;

  void _next() {
    if (_isLastStep) {
      _add();
    } else {
      setState(() => _step++);
    }
  }

  void _previous() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step--);
    }
  }

  void _add() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    // Validate required variations, same rules as the web app.
    for (int index = 0; index < _variations.length; index++) {
      final v = _variations[index];
      if (!v.isMultiSelect! && v.isRequired! &&
          !productProvider.selectedVariations[index].contains(true)) {
        showCustomSnackBarHelper(
          '${getTranslated('choose_a_variation_from', context)} ${v.name}',
          isError: true,
        );
        return;
      }
      if (v.isMultiSelect! &&
          (v.isRequired! || productProvider.selectedVariations[index].contains(true)) &&
          v.min! > productProvider.selectedVariationLength(productProvider.selectedVariations, index)) {
        showCustomSnackBarHelper(
          '${getTranslated('you_need_to_select_minimum', context)} ${v.min}',
          isError: true,
        );
        return;
      }
    }

    Provider.of<CartProvider>(context, listen: false)
        .addToCart(buildKioskCartModel(context, widget.product), widget.cartIndex ?? productProvider.cartIndex);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        return Dialog(
          backgroundColor: Theme.of(context).cardColor,
          insetPadding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: 720,
            height: size.height * 0.9,
            child: Stack(
              children: [
                Column(
                  children: [
                    _Header(product: widget.product),
                    Expanded(
                      child: _isAddonStep
                          ? _AddonStepView(product: widget.product)
                          : _VariationStepView(
                              product: widget.product,
                              variation: _variations[_step],
                              variationIndex: _step,
                            ),
                    ),
                    _BottomBar(
                      product: widget.product,
                      isFirstStep: _step == 0,
                      isLastStep: _isLastStep,
                      onPrevious: _previous,
                      onNext: _next,
                    ),
                  ],
                ),
                Positioned(
                  right: Dimensions.paddingSizeSmall,
                  top: Dimensions.paddingSizeSmall,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
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
        );
      },
    );
  }
}

/// Header: product image, name and the live selection summary chips.
class _Header extends StatelessWidget {
  final Product product;
  const _Header({required this.product});

  @override
  Widget build(BuildContext context) {
    final splash = Provider.of<SplashProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context);
    final summary = _selectionSummary(context, product, productProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge,
        Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall,
      ),
      child: Column(
        children: [
          Text(
            product.name ?? '',
            textAlign: TextAlign.center,
            style: rubikSemiBold.copyWith(
              fontSize: Dimensions.fontSizeOverLarge,
              color: Theme.of(context).textTheme.bodyLarge!.color,
            ),
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: summary
                  .map((t) => Text(
                        t,
                        style: rubikRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).hintColor,
                        ),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: Dimensions.paddingSizeDefault),
          SizedBox(
            height: 110,
            child: CustomImageWidget(
              placeholder: Images.placeholderImage,
              image: '${splash.baseUrls?.productImageUrl}/${product.image}',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _selectionSummary(BuildContext context, Product product, ProductProvider p) {
    final List<String> chips = [];
    final variations = product.variations ?? [];
    for (int index = 0; index < variations.length; index++) {
      final values = variations[index].variationValues ?? [];
      for (int i = 0; i < values.length; i++) {
        if ((p.selectedVariations.length > index) && (p.selectedVariations[index][i] ?? false)) {
          chips.add('1x ${values[i].level?.trim()}');
        }
      }
    }
    final addOns = product.addOns ?? [];
    for (int i = 0; i < addOns.length; i++) {
      if (p.addOnActiveList.length > i && p.addOnActiveList[i]) {
        chips.add('${p.addOnQtyList[i]}x ${addOns[i].name}');
      }
    }
    return chips;
  }
}

/// A single variation group rendered as tap-to-select tiles (e.g. milk choice).
class _VariationStepView extends StatelessWidget {
  final Product product;
  final Variation variation;
  final int variationIndex;
  const _VariationStepView({
    required this.product,
    required this.variation,
    required this.variationIndex,
  });

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final values = variation.variationValues ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
      child: Column(
        children: [
          Text(
            variation.name ?? getTranslated('choose_an_option', context) ?? '',
            textAlign: TextAlign.center,
            style: rubikSemiBold.copyWith(
              fontSize: Dimensions.fontSizeLarge,
              color: Theme.of(context).textTheme.bodyLarge!.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _ruleText(context),
            textAlign: TextAlign.center,
            style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: Dimensions.paddingSizeSmall,
            runSpacing: Dimensions.paddingSizeSmall,
            children: List.generate(values.length, (i) {
              final bool selected = productProvider.selectedVariations[variationIndex][i] ?? false;
              return _OptionTile(
                title: values[i].level?.trim() ?? '',
                priceDelta: values[i].optionPrice ?? 0,
                selected: selected,
                onTap: () {
                  productProvider.setCartVariationIndex(
                      variationIndex, i, product, variation.isMultiSelect!);
                  productProvider.checkIsRequiredSelected(
                    index: variationIndex,
                    isMultiSelect: variation.isMultiSelect!,
                    variations: productProvider.selectedVariations[variationIndex],
                    min: variation.min,
                    max: variation.max,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  String _ruleText(BuildContext context) {
    if (variation.isMultiSelect!) {
      return '${getTranslated('optional', context)} • ${getTranslated('choose_up_to', context) ?? 'Choose up to'} ${variation.max}';
    }
    if (variation.isRequired!) {
      return getTranslated('select_one', context) ?? 'Select one';
    }
    return getTranslated('optional', context) ?? 'Optional';
  }
}

/// Add-ons step: tap a tile to add it, then a -/+ stepper lets you set quantity.
class _AddonStepView extends StatelessWidget {
  final Product product;
  const _AddonStepView({required this.product});

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final addOns = product.addOns ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
      child: Column(
        children: [
          Text(
            getTranslated('would_you_like_to_add_extras', context) ?? 'Would you like to add extras?',
            textAlign: TextAlign.center,
            style: rubikSemiBold.copyWith(
              fontSize: Dimensions.fontSizeLarge,
              color: Theme.of(context).textTheme.bodyLarge!.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            getTranslated('optional', context) ?? 'Optional',
            style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: Dimensions.paddingSizeSmall,
            runSpacing: Dimensions.paddingSizeSmall,
            children: List.generate(addOns.length, (i) {
              final bool active = productProvider.addOnActiveList[i];
              return _OptionTile(
                title: addOns[i].name ?? '',
                priceDelta: addOns[i].price ?? 0,
                selected: active,
                stepper: active
                    ? _QtyStepper(
                        qty: productProvider.addOnQtyList[i] ?? 1,
                        onDecrement: () {
                          if ((productProvider.addOnQtyList[i] ?? 1) > 1) {
                            productProvider.setAddOnQuantity(false, i);
                          } else {
                            productProvider.addAddOn(false, i);
                          }
                        },
                        onIncrement: () => productProvider.setAddOnQuantity(true, i),
                      )
                    : null,
                onTap: () {
                  if (!active) productProvider.addAddOn(true, i);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Reusable option tile used for both variation values and add-ons.
class _OptionTile extends StatelessWidget {
  final String title;
  final double priceDelta;
  final bool selected;
  final VoidCallback onTap;
  final Widget? stepper;
  const _OptionTile({
    required this.title,
    required this.priceDelta,
    required this.selected,
    required this.onTap,
    this.stepper,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeDefault,
        ),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.06) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(
            color: selected ? primary : Theme.of(context).disabledColor.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: rubikMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).textTheme.bodyLarge!.color,
              ),
            ),
            if (priceDelta > 0) ...[
              const SizedBox(height: 2),
              Text(
                '+${PriceConverterHelper.convertPrice(priceDelta)}',
                style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor),
              ),
            ],
            if (stepper != null) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              stepper!,
            ],
          ],
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  const _QtyStepper({required this.qty, required this.onIncrement, required this.onDecrement});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Container(
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      ),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onDecrement,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
              child: Icon(qty <= 1 ? Icons.delete_outline : Icons.remove, size: 16, color: primary),
            ),
          ),
          Text('$qty', style: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall)),
          InkWell(
            onTap: onIncrement,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
              child: Icon(Icons.add, size: 16, color: primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom bar: PREVIOUS · live total · NEXT/ADD, with a quantity stepper.
class _BottomBar extends StatelessWidget {
  final Product product;
  final bool isFirstStep;
  final bool isLastStep;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  const _BottomBar({
    required this.product,
    required this.isFirstStep,
    required this.isLastStep,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartModel = buildKioskCartModel(context, product);
    final double total = (cartModel.discountedPrice ?? 0) * (productProvider.quantity ?? 1) +
        _addonsTotal(productProvider, product);

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Item quantity stepper (centered, like the photos).
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundIcon(
                icon: Icons.remove,
                onTap: () => (productProvider.quantity ?? 1) > 1 ? productProvider.setQuantity(false) : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                child: Text('${productProvider.quantity}', style: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
              ),
              _RoundIcon(icon: Icons.add, filled: true, onTap: () => productProvider.setQuantity(true)),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Row(
            children: [
              Expanded(
                child: _PillButton(
                  label: getTranslated(isFirstStep ? 'close' : 'previous', context) ?? (isFirstStep ? 'CLOSE' : 'PREVIOUS'),
                  onTap: onPrevious,
                  filled: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                child: Text(
                  PriceConverterHelper.convertPrice(total),
                  style: rubikSemiBold.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color),
                ),
              ),
              Expanded(
                child: _PillButton(
                  label: getTranslated(isLastStep ? 'add' : 'next', context) ?? (isLastStep ? 'ADD' : 'NEXT'),
                  onTap: onNext,
                  filled: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _addonsTotal(ProductProvider p, Product product) {
    double total = 0;
    final addOns = product.addOns ?? [];
    for (int i = 0; i < addOns.length; i++) {
      if (p.addOnActiveList.length > i && p.addOnActiveList[i]) {
        total += (addOns[i].price ?? 0) * (p.addOnQtyList[i] ?? 1);
      }
    }
    return total;
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
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? primary : primary.withValues(alpha: 0.1),
        ),
        child: Icon(icon, size: 20, color: filled ? Colors.white : primary),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _PillButton({required this.label, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Material(
      color: filled ? primary : Theme.of(context).disabledColor.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          child: Text(
            label.toUpperCase(),
            style: rubikSemiBold.copyWith(
              letterSpacing: 1,
              color: filled ? Colors.white : Theme.of(context).textTheme.bodyLarge!.color,
            ),
          ),
        ),
      ),
    );
  }
}
