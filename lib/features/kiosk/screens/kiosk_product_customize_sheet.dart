import 'package:flutter/material.dart';
import 'package:acafe_kiosk/common/models/cart_model.dart';
import 'package:acafe_kiosk/common/models/product_model.dart';
import 'package:acafe_kiosk/common/providers/product_provider.dart';
import 'package:acafe_kiosk/common/widgets/custom_image_widget.dart';
import 'package:acafe_kiosk/features/cart/providers/cart_provider.dart';
import 'package:acafe_kiosk/helper/custom_snackbar_helper.dart';
import 'package:acafe_kiosk/helper/price_converter_helper.dart';
import 'package:acafe_kiosk/helper/product_helper.dart';
import 'package:acafe_kiosk/localization/language_constrants.dart';
import 'package:acafe_kiosk/features/splash/providers/splash_provider.dart';
import 'package:acafe_kiosk/utill/images.dart';
import 'package:acafe_kiosk/utill/styles.dart';
import 'package:provider/provider.dart';

// ===========================================================================
// KIOSK PRODUCT CUSTOMIZE — single full-screen page matching the Figma design
// (node 559:7646). Every size is taken from the 2572px-wide artboard and scaled
// by `s = screenWidth / _kDesignWidth`, so it reproduces the design at any size.
// ===========================================================================
const double _kDesignWidth = 2572;
const Color _kPageBg = Color(0xFFF7F1DE);
const Color _kPanelBg = Color(0xFFFCFAF4);
const Color _kDarkButton = Color(0xFF1E1E1E);
const Color _kCreamText = Color(0xFFF3F3DD);

double _scaleFor(double w) => w / _kDesignWidth;

/// Variation groups whose name mentions "cup"/"can" get the big two-card
/// treatment and are only shown when the product actually has them.
final RegExp _kCupCanPattern = RegExp(r'cup|can', caseSensitive: false);

/// Entry point: tap a product in the kiosk menu -> open the customization screen.
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

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => KioskProductCustomizeScreen(product: product, cartIndex: cartIndex),
    ),
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

class KioskProductCustomizeScreen extends StatelessWidget {
  final Product product;
  final int? cartIndex;
  const KioskProductCustomizeScreen({super.key, required this.product, this.cartIndex});

  /// Same validation rules as the web app, run before adding to the cart.
  bool _validate(BuildContext context, ProductProvider productProvider) {
    final variations = product.variations ?? [];
    for (int index = 0; index < variations.length; index++) {
      final v = variations[index];
      if (!v.isMultiSelect! && v.isRequired! &&
          !productProvider.selectedVariations[index].contains(true)) {
        showCustomSnackBarHelper(
          '${getTranslated('choose_a_variation_from', context)} ${v.name}',
          isError: true,
        );
        return false;
      }
      if (v.isMultiSelect! &&
          (v.isRequired! || productProvider.selectedVariations[index].contains(true)) &&
          v.min! > productProvider.selectedVariationLength(productProvider.selectedVariations, index)) {
        showCustomSnackBarHelper(
          '${getTranslated('you_need_to_select_minimum', context)} ${v.min}',
          isError: true,
        );
        return false;
      }
    }
    return true;
  }

  void _addToCart(BuildContext context, ProductProvider productProvider) {
    if (!_validate(context, productProvider)) return;
    Provider.of<CartProvider>(context, listen: false)
        .addToCart(buildKioskCartModel(context, product), cartIndex ?? productProvider.cartIndex);
    showCustomSnackBarHelper(getTranslated('added_to_cart', context), isError: false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final variations = product.variations ?? [];
    // Split out the cup/can group(s) so they render with the big two-card style.
    final List<MapEntry<int, Variation>> indexedVariations =
        List.generate(variations.length, (i) => MapEntry(i, variations[i]));
    final dietaryVariations =
        indexedVariations.where((e) => !_kCupCanPattern.hasMatch(e.value.name ?? '')).toList();
    final cupCanVariations =
        indexedVariations.where((e) => _kCupCanPattern.hasMatch(e.value.name ?? '')).toList();
    final addOns = product.addOns ?? [];

    return Scaffold(
      backgroundColor: _kPageBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double s = _scaleFor(constraints.maxWidth);
            return Consumer<ProductProvider>(
              builder: (context, productProvider, _) {
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(86 * s, 30 * s, 86 * s, 30 * s),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Header(s: s, product: product, productProvider: productProvider),
                            // Each non-cup/can variation -> a "dietary" style section.
                            for (final entry in dietaryVariations)
                              _VariationSection(
                                s: s,
                                variation: entry.value,
                                variationIndex: entry.key,
                                product: product,
                                productProvider: productProvider,
                              ),
                            if (addOns.isNotEmpty)
                              _AddOnsSection(s: s, product: product, productProvider: productProvider),
                            // Cup/can group(s): only present when the product has them.
                            for (final entry in cupCanVariations)
                              _CupCanSection(
                                s: s,
                                variation: entry.value,
                                variationIndex: entry.key,
                                product: product,
                                productProvider: productProvider,
                              ),
                          ],
                        ),
                      ),
                    ),
                    _AddToCartBar(s: s, onTap: () => _addToCart(context, productProvider)),
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

/// Header: back button, large product image, name, description and a quantity
/// stepper.
class _Header extends StatelessWidget {
  final double s;
  final Product product;
  final ProductProvider productProvider;
  const _Header({required this.s, required this.product, required this.productProvider});

  @override
  Widget build(BuildContext context) {
    final splash = Provider.of<SplashProvider>(context, listen: false);
    final String description = (product.description ?? '').replaceAll(RegExp(r'<[^>]*>'), '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Back button (top-left).
        Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            elevation: 1,
            child: InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                width: 120 * s,
                height: 120 * s,
                child: Icon(Icons.arrow_back_ios_new, size: 50 * s, color: Colors.black),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 720 * s,
          child: CustomImageWidget(
            placeholder: Images.placeholderImage,
            image: '${splash.baseUrls?.productImageUrl}/${product.image}',
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: 24 * s),
        Text(
          product.name ?? '',
          textAlign: TextAlign.center,
          style: loewExtraBold.copyWith(fontSize: 64 * s, color: Colors.black),
        ),
        if (description.isNotEmpty) ...[
          SizedBox(height: 12 * s),
          Text(
            description,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: scotchDisplayLight.copyWith(fontSize: 32 * s, height: 1.2, color: Colors.black87),
          ),
        ],
        SizedBox(height: 30 * s),
        _QuantityStepper(s: s, productProvider: productProvider),
        SizedBox(height: 20 * s),
      ],
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final double s;
  final ProductProvider productProvider;
  const _QuantityStepper({required this.s, required this.productProvider});

  @override
  Widget build(BuildContext context) {
    final int qty = productProvider.quantity ?? 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StepperButton(
          s: s,
          label: '−',
          filled: false,
          onTap: () => qty > 1 ? productProvider.setQuantity(false) : null,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 50 * s),
          child: Text('$qty', style: loewExtraBold.copyWith(fontSize: 80 * s, color: Colors.black)),
        ),
        _StepperButton(
          s: s,
          label: '+',
          filled: true,
          onTap: () => productProvider.setQuantity(true),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final double s;
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _StepperButton({required this.s, required this.label, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? _kDarkButton : Colors.white,
      borderRadius: BorderRadius.circular(36 * s),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 150 * s,
          height: 114 * s,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36 * s),
            border: filled ? null : Border.all(color: Colors.black, width: (4 * s).clamp(2.0, 6.0)),
          ),
          child: Text(
            label,
            style: loewExtraBold.copyWith(fontSize: 70 * s, color: filled ? _kCreamText : Colors.black),
          ),
        ),
      ),
    );
  }
}

/// A light rounded panel wrapping a titled section.
class _SectionPanel extends StatelessWidget {
  final double s;
  final String title;
  final Widget child;
  const _SectionPanel({required this.s, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 18 * s),
      padding: EdgeInsets.all(45 * s),
      decoration: BoxDecoration(
        color: _kPanelBg,
        borderRadius: BorderRadius.circular(70 * s),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: loewBold.copyWith(fontSize: 54 * s, color: Colors.black)),
          SizedBox(height: 30 * s),
          child,
        ],
      ),
    );
  }
}

/// A single variation group rendered as selectable "dietary" cards with a radio.
class _VariationSection extends StatelessWidget {
  final double s;
  final Variation variation;
  final int variationIndex;
  final Product product;
  final ProductProvider productProvider;
  const _VariationSection({
    required this.s,
    required this.variation,
    required this.variationIndex,
    required this.product,
    required this.productProvider,
  });

  @override
  Widget build(BuildContext context) {
    final splash = Provider.of<SplashProvider>(context, listen: false);
    final values = variation.variationValues ?? [];
    final title = variation.name?.isNotEmpty == true
        ? variation.name!
        : (getTranslated('choose_an_option', context) ?? 'Choose an option');

    return _SectionPanel(
      s: s,
      title: title,
      child: Wrap(
        spacing: 24 * s,
        runSpacing: 24 * s,
        children: List.generate(values.length, (i) {
          final bool selected = productProvider.selectedVariations[variationIndex][i] ?? false;
          return _DietaryCard(
            s: s,
            name: values[i].level?.trim() ?? '',
            priceDelta: values[i].optionPrice ?? 0,
            image: '${splash.baseUrls?.productImageUrl}/${product.image}',
            selected: selected,
            onTap: () {
              productProvider.setCartVariationIndex(variationIndex, i, product, variation.isMultiSelect!);
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
    );
  }
}

class _DietaryCard extends StatelessWidget {
  final double s;
  final String name;
  final double priceDelta;
  final String image;
  final bool selected;
  final VoidCallback onTap;
  const _DietaryCard({
    required this.s,
    required this.name,
    required this.priceDelta,
    required this.image,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(40 * s),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 400 * s,
          padding: EdgeInsets.all(28 * s),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40 * s),
            border: Border.all(
              color: selected ? Colors.black : Colors.black12,
              width: selected ? (6 * s).clamp(2.0, 8.0) : (2 * s).clamp(1.0, 3.0),
            ),
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: _RadioDot(s: s, selected: selected),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(24 * s),
                child: SizedBox(
                  width: 240 * s,
                  height: 240 * s,
                  child: CustomImageWidget(placeholder: Images.placeholderImage, image: image, fit: BoxFit.cover),
                ),
              ),
              SizedBox(height: 20 * s),
              Text(
                name.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: loewBold.copyWith(fontSize: 34 * s, height: 1.1, color: Colors.black),
              ),
              if (priceDelta > 0) ...[
                SizedBox(height: 6 * s),
                Text(
                  '+${PriceConverterHelper.convertPrice(priceDelta)}',
                  style: swiss721Light.copyWith(fontSize: 28 * s, color: Colors.black54),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final double s;
  final bool selected;
  const _RadioDot({required this.s, required this.selected});

  @override
  Widget build(BuildContext context) {
    final double d = 40 * s;
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? Colors.black : Colors.transparent,
        border: Border.all(color: Colors.black, width: (3 * s).clamp(1.5, 4.0)),
      ),
      child: selected
          ? Icon(Icons.check, size: 26 * s, color: Colors.white)
          : null,
    );
  }
}

/// Add-ons: tap a card to toggle it on/off (qty defaults to 1).
class _AddOnsSection extends StatelessWidget {
  final double s;
  final Product product;
  final ProductProvider productProvider;
  const _AddOnsSection({required this.s, required this.product, required this.productProvider});

  @override
  Widget build(BuildContext context) {
    final splash = Provider.of<SplashProvider>(context, listen: false);
    final addOns = product.addOns ?? [];

    return _SectionPanel(
      s: s,
      title: getTranslated('add_add_ons', context) ?? 'Add add-ons',
      child: Wrap(
        spacing: 24 * s,
        runSpacing: 24 * s,
        children: List.generate(addOns.length, (i) {
          final bool active = i < productProvider.addOnActiveList.length && productProvider.addOnActiveList[i];
          return _AddOnCard(
            s: s,
            name: addOns[i].name ?? '',
            priceDelta: addOns[i].price ?? 0,
            image: '${splash.baseUrls?.productImageUrl}/${product.image}',
            selected: active,
            onTap: () => productProvider.addAddOn(!active, i),
          );
        }),
      ),
    );
  }
}

class _AddOnCard extends StatelessWidget {
  final double s;
  final String name;
  final double priceDelta;
  final String image;
  final bool selected;
  final VoidCallback onTap;
  const _AddOnCard({
    required this.s,
    required this.name,
    required this.priceDelta,
    required this.image,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(40 * s),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 520 * s,
          padding: EdgeInsets.all(28 * s),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40 * s),
            border: Border.all(
              color: selected ? Colors.black : Colors.black12,
              width: selected ? (6 * s).clamp(2.0, 8.0) : (2 * s).clamp(1.0, 3.0),
            ),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24 * s),
                child: SizedBox(
                  width: double.infinity,
                  height: 240 * s,
                  child: CustomImageWidget(placeholder: Images.placeholderImage, image: image, fit: BoxFit.cover),
                ),
              ),
              SizedBox(height: 20 * s),
              Text(
                name.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: loewBold.copyWith(fontSize: 32 * s, height: 1.1, color: Colors.black),
              ),
              SizedBox(height: 6 * s),
              Text(
                '+${PriceConverterHelper.convertPrice(priceDelta)}',
                style: swiss721Light.copyWith(fontSize: 28 * s, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cup / can group: two big selectable cards. Only shown when the product has a
/// cup/can variation.
class _CupCanSection extends StatelessWidget {
  final double s;
  final Variation variation;
  final int variationIndex;
  final Product product;
  final ProductProvider productProvider;
  const _CupCanSection({
    required this.s,
    required this.variation,
    required this.variationIndex,
    required this.product,
    required this.productProvider,
  });

  @override
  Widget build(BuildContext context) {
    final splash = Provider.of<SplashProvider>(context, listen: false);
    final values = variation.variationValues ?? [];
    final title = variation.name?.isNotEmpty == true ? variation.name! : (getTranslated('can_or_cup', context) ?? 'Can or cup?');

    return _SectionPanel(
      s: s,
      title: title,
      child: Row(
        children: List.generate(values.length, (i) {
          final bool selected = productProvider.selectedVariations[variationIndex][i] ?? false;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < values.length - 1 ? 30 * s : 0),
              child: _CupCanCard(
                s: s,
                name: values[i].level?.trim() ?? '',
                priceDelta: values[i].optionPrice ?? 0,
                image: '${splash.baseUrls?.productImageUrl}/${product.image}',
                selected: selected,
                onTap: () {
                  productProvider.setCartVariationIndex(variationIndex, i, product, variation.isMultiSelect!);
                  productProvider.checkIsRequiredSelected(
                    index: variationIndex,
                    isMultiSelect: variation.isMultiSelect!,
                    variations: productProvider.selectedVariations[variationIndex],
                    min: variation.min,
                    max: variation.max,
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CupCanCard extends StatelessWidget {
  final double s;
  final String name;
  final double priceDelta;
  final String image;
  final bool selected;
  final VoidCallback onTap;
  const _CupCanCard({
    required this.s,
    required this.name,
    required this.priceDelta,
    required this.image,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(40 * s),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 640 * s,
          padding: EdgeInsets.all(40 * s),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40 * s),
            border: Border.all(
              color: selected ? Colors.black : Colors.black12,
              width: selected ? (6 * s).clamp(2.0, 8.0) : (2 * s).clamp(1.0, 3.0),
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: CustomImageWidget(
                  placeholder: Images.placeholderImage,
                  image: image,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 16 * s),
              Text(
                name.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: loewBold.copyWith(fontSize: 36 * s, letterSpacing: 1, color: Colors.black),
              ),
              if (priceDelta > 0) ...[
                SizedBox(height: 6 * s),
                Text(
                  '+${PriceConverterHelper.convertPrice(priceDelta)}',
                  style: swiss721Light.copyWith(fontSize: 28 * s, color: Colors.black54),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Pinned full-width "ADD TO CART" button.
class _AddToCartBar extends StatelessWidget {
  final double s;
  final VoidCallback onTap;
  const _AddToCartBar({required this.s, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(86 * s, 16 * s, 86 * s, 24 * s),
      child: Material(
        color: _kDarkButton,
        borderRadius: BorderRadius.circular(80 * s),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 180 * s,
            alignment: Alignment.center,
            child: Text(
              getTranslated('add_to_cart', context)?.toUpperCase() ?? 'ADD TO CART',
              style: loewExtraBold.copyWith(fontSize: 54 * s, letterSpacing: 2, color: _kCreamText),
            ),
          ),
        ),
      ),
    );
  }
}
