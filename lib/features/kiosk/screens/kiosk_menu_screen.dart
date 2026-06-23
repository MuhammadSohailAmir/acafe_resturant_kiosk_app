import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:acafe_customer/common/models/product_model.dart';
import 'package:acafe_customer/common/widgets/custom_image_widget.dart';
import 'package:acafe_customer/features/cart/providers/cart_provider.dart';
import 'package:acafe_customer/features/category/providers/category_provider.dart';
import 'package:acafe_customer/features/kiosk/domain/kiosk_session.dart';
import 'package:acafe_customer/features/kiosk/screens/kiosk_product_customize_sheet.dart';
import 'package:acafe_customer/features/language/providers/localization_provider.dart';
import 'package:acafe_customer/features/splash/providers/splash_provider.dart';
import 'package:acafe_customer/helper/price_converter_helper.dart';
import 'package:acafe_customer/helper/router_helper.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/utill/app_constants.dart';
import 'package:acafe_customer/utill/dimensions.dart';
import 'package:acafe_customer/utill/images.dart';
import 'package:acafe_customer/utill/styles.dart';
import 'package:provider/provider.dart';

// ===========================================================================
// MENU GRID TUNING — change these numbers to adjust the product grid.
//   _kTileMaxWidth : max width of one product cell. SMALLER => MORE columns.
//                    The grid auto-fits as many columns as fit the screen, so
//                    wide screens get more items per row (responsive).
//   _kTileHeight   : total height of one product cell (image + name + price).
//   _kProductImageH: height the product image is drawn at (BoxFit.contain).
// ===========================================================================
const double _kTileMaxWidth = 300;
const double _kTileHeight = 290;
const double _kProductImageH = 180;

// Left category rail.
const double _kRailWidth = 172;
const double _kRailItemVerticalPadding = 14;

// Floating bottom-center "Total" pill.
const double _kCartPillWidth = 160;
const double _kCartPillRadius = 20;
const double _kCartPillBottomGap = 24;
const double _kCartBadgeSize = 32;

/// Kiosk main menu: brand bar on top, vertical category rail on the left and a
/// responsive product grid on the right. Categories and products come from the
/// backend via [CategoryProvider].
class KioskMenuScreen extends StatefulWidget {
  const KioskMenuScreen({super.key});

  @override
  State<KioskMenuScreen> createState() => _KioskMenuScreenState();
}

class _KioskMenuScreenState extends State<KioskMenuScreen> {
  LocalizationProvider? _localization;
  String? _lastLocale;

  @override
  void initState() {
    super.initState();
    _localization = Provider.of<LocalizationProvider>(context, listen: false);
    _lastLocale = _localization!.locale.languageCode;
    // Refetch menu data when the language changes while this screen is open, so
    // the product grid updates instantly (not only after navigating away/back).
    _localization!.addListener(_onLocaleChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _localization?.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    final code = _localization?.locale.languageCode;
    if (code != null && code != _lastLocale) {
      _lastLocale = code;
      _reloadForLocale();
    }
  }

  /// Re-pull the category list and the currently-selected category's products
  /// in the new locale (the X-localization header is already updated by then).
  Future<void> _reloadForLocale() async {
    if (!mounted) return;
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    await categoryProvider.getCategoryList(true);
    final selectedId = categoryProvider.selectedSubCategoryId;
    if (selectedId != null) {
      await categoryProvider.getCategoryProductList(selectedId, 1);
      _precacheProducts(categoryProvider);
    }
  }

  Future<void> _loadData() async {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    // Reload so category/product names reflect the language picked on the intro
    // screen (the list may have been pre-loaded at startup in the default
    // locale; the active X-localization header is now applied to the refetch).
    await categoryProvider.getCategoryList(true);

    // Auto-select the first category so the grid isn't empty on first paint.
    final categories = categoryProvider.categoryList;
    if (categories != null && categories.isNotEmpty) {
      await categoryProvider.getCategoryProductList('${categories.first.id}', 1);
      _precacheProducts(categoryProvider);
      // Warm every category's images in the background so switching categories
      // is instant (primes the browser HTTP cache on web + disk cache on
      // mobile). Read-only: uses the repo directly, doesn't touch the grid.
      _prefetchAllCategories(categoryProvider);
    }
  }

  Future<void> _prefetchAllCategories(CategoryProvider categoryProvider) async {
    final repo = categoryProvider.categoryRepo;
    final categories = categoryProvider.categoryList;
    if (repo == null || categories == null || !mounted) return;
    final splash = Provider.of<SplashProvider>(context, listen: false);

    for (final category in categories) {
      if (!mounted) return;
      try {
        final response = await repo.getCategoryProductList(
          categoryID: '${category.id}', offset: 1, type: 'all', limit: 50,
        );
        if (!mounted || response.response?.statusCode != 200) continue;
        for (final product in ProductModel.fromJson(response.response?.data).products ?? []) {
          if (!mounted) return;
          final url = CustomImageWidget.resolveWebImageUrl('${splash.baseUrls?.productImageUrl}/${product.image}');
          if (url.isNotEmpty) {
            precacheImage(CachedNetworkImageProvider(url), context).catchError((_) {});
          }
        }
      } catch (_) {/* best-effort prefetch */}
    }
  }

  /// Warm the disk/memory image cache for the loaded products so revisiting a
  /// category shows them instantly (no placeholder flash).
  void _precacheProducts(CategoryProvider categoryProvider) {
    if (!mounted) return;
    final splash = Provider.of<SplashProvider>(context, listen: false);
    final products = categoryProvider.categoryProductModel?.products ?? [];
    for (final product in products) {
      final url = CustomImageWidget.resolveWebImageUrl('${splash.baseUrls?.productImageUrl}/${product.image}');
      if (url.isNotEmpty) {
        precacheImage(CachedNetworkImageProvider(url), context).catchError((_) {});
      }
    }
  }

  Future<void> _onSelectCategory(int id) async {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    await categoryProvider.getCategoryProductList('$id', 1);
    _precacheProducts(categoryProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const _KioskTopBar(),
            Expanded(
              child: Stack(
                children: [
                  // Full-height rail (stretch) + product grid.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CategoryRail(onSelect: _onSelectCategory),
                      const Expanded(child: _ProductArea()),
                    ],
                  ),
                  // Floating Total pill, bottom-center over the grid.
                  const Align(alignment: Alignment.bottomCenter, child: _CartPill()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating "Total" pill at the bottom-center of the menu — a rounded light
/// card showing the live total with a circular item-count badge. Opens MY
/// ORDER on tap. Hidden when the cart is empty (matches the reference).
class _CartPill extends StatelessWidget {
  const _CartPill();

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final cartList = cartProvider.cartList;
        if (cartList.isEmpty) return const SizedBox.shrink();
        final int count = kioskCartItemCount(cartList);
        final double total = kioskCartTotal(cartList);

        return Padding(
          padding: const EdgeInsets.only(bottom: _kCartPillBottomGap),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => RouterHelper.getKioskCartRoute(),
              borderRadius: BorderRadius.circular(_kCartPillRadius),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  // The rounded total card.
                  Container(
                    width: _kCartPillWidth,
                    margin: const EdgeInsets.only(top: _kCartBadgeSize / 2),
                    padding: const EdgeInsets.fromLTRB(
                      Dimensions.paddingSizeLarge, Dimensions.paddingSizeDefault,
                      Dimensions.paddingSizeLarge, Dimensions.paddingSizeDefault,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(_kCartPillRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          getTranslated('total', context) ?? 'Total',
                          style: rubikRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          PriceConverterHelper.convertPrice(total),
                          style: rubikSemiBold.copyWith(
                            fontSize: Dimensions.fontSizeExtraLarge,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Circular item-count badge, overlapping the top edge.
                  Container(
                    width: _kCartBadgeSize,
                    height: _kCartBadgeSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '$count',
                      style: rubikSemiBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _KioskTopBar extends StatelessWidget {
  const _KioskTopBar();

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<SplashProvider>(context, listen: false).configModel;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeLarge,
        vertical: Dimensions.paddingSizeDefault,
      ),
      child: Row(
        children: [
          // Brand logo (top-left).
          Text(
            config?.restaurantName?.isNotEmpty == true
                ? config!.restaurantName!
                : 'A/CAFÉ',
            style: rubikSemiBold.copyWith(
              fontSize: Dimensions.fontSizeExtraLarge,
              letterSpacing: 1,
              color: Theme.of(context).textTheme.bodyLarge!.color,
            ),
          ),
          const Spacer(),

          // Search.
          _CircleIconButton(
            icon: Icons.search,
            onTap: () => RouterHelper.getSearchRoute(),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          // Language flag -> language selector.
          const _LanguageFlagButton(),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          // Filter (placeholder for now).
          _CircleIconButton(
            icon: Icons.tune,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      shape: const CircleBorder(),
      clipBehavior: Clip.hardEdge,
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Icon(icon, size: 22, color: Theme.of(context).textTheme.bodyLarge!.color),
        ),
      ),
    );
  }
}

class _LanguageFlagButton extends StatelessWidget {
  const _LanguageFlagButton();

  @override
  Widget build(BuildContext context) {
    final String code =
        Provider.of<LocalizationProvider>(context).locale.languageCode;
    final language = AppConstants.languages.firstWhere(
      (l) => l.languageCode == code,
      orElse: () => AppConstants.languages.first,
    );

    return Material(
      color: Theme.of(context).cardColor,
      shape: const CircleBorder(),
      clipBehavior: Clip.hardEdge,
      elevation: 1,
      child: InkWell(
        onTap: () => RouterHelper.getLanguageRoute(true),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: ClipOval(
            child: Image.asset(language.imageUrl!, width: 22, height: 22, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

class _CategoryRail extends StatelessWidget {
  final void Function(int id) onSelect;
  const _CategoryRail({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, category, _) {
        final categories = category.categoryList;
        if (categories == null) {
          return const SizedBox(width: _kRailWidth, child: Center(child: CircularProgressIndicator()));
        }
        // Full-height column with the categories evenly distributed top→bottom.
        return SizedBox(
          width: _kRailWidth,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(categories.length, (index) {
                final c = categories[index];
                final bool selected = '${c.id}' == category.selectedSubCategoryId;
                return _RailItem(
                  name: c.name ?? '',
                  selected: selected,
                  onTap: () => onSelect(c.id!),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

class _RailItem extends StatelessWidget {
  final String name;
  final bool selected;
  final VoidCallback onTap;
  const _RailItem({required this.name, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Subtle active state only: bold + dark text and a thin accent bar — no
    // white background box, so the rail surface stays uniform.
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: _kRailItemVerticalPadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 3,
              height: 30,
              child: selected ? ColoredBox(color: Theme.of(context).primaryColor) : null,
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Text(
                name.toUpperCase(),
                softWrap: true,
                // Always regular weight (no bold). The selected item is shown
                // only by a darker text colour + the accent bar.
                style: rubikRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  letterSpacing: 1.0,
                  height: 1.35,
                  color: selected
                      ? Theme.of(context).textTheme.bodyLarge!.color
                      : Theme.of(context).hintColor.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductArea extends StatelessWidget {
  const _ProductArea();

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, category, _) {
        final products = category.categoryProductModel?.products;
        final selected = category.categoryList
            ?.where((c) => '${c.id}' == category.selectedSubCategoryId)
            .firstOrNull;
        final String title = selected?.name ?? '';

        return Container(
          // White background so transparent product PNGs blend in cleanly.
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Dimensions.paddingSizeLarge,
                  Dimensions.paddingSizeLarge,
                  Dimensions.paddingSizeLarge,
                  Dimensions.paddingSizeSmall,
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: rubikSemiBold.copyWith(
                    fontSize: Dimensions.fontSizeOverLarge,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                ),
              ),
              Expanded(
                child: category.categoryProductModel == null
                    ? const Center(child: CircularProgressIndicator())
                    : products == null || products.isEmpty
                        ? Center(
                            child: Text(
                              getTranslated('no_items', context) ?? 'No items',
                              style: rubikRegular.copyWith(color: Theme.of(context).hintColor),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeDefault,
                              vertical: Dimensions.paddingSizeSmall,
                            ),
                            // Responsive: columns auto-fit to the screen width
                            // based on _kTileMaxWidth (more columns when wider).
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: _kTileMaxWidth,
                              crossAxisSpacing: Dimensions.paddingSizeSmall,
                              mainAxisSpacing: Dimensions.paddingSizeExtraLarge,
                              mainAxisExtent: _kTileHeight,
                            ),
                            itemCount: products.length,
                            itemBuilder: (context, index) => _KioskProductCard(product: products[index]),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KioskProductCard extends StatelessWidget {
  final Product product;
  const _KioskProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final splash = Provider.of<SplashProvider>(context, listen: false);
    final String image = '${splash.baseUrls?.productImageUrl}/${product.image}';

    return InkWell(
      onTap: () => openKioskCustomize(context, product),
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Transparent product image — no background, border radius or shadow.
        SizedBox(
          height: _kProductImageH,
          width: double.infinity,
          child: CustomImageWidget(
            placeholder: Images.placeholderImage,
            image: image,
            height: _kProductImageH,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Text(
          product.name ?? '',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: rubikSemiBold.copyWith(
            fontSize: Dimensions.fontSizeLarge,
            color: Theme.of(context).textTheme.bodyLarge!.color,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(
          PriceConverterHelper.convertPrice(
            product.price,
            discount: product.discount,
            discountType: product.discountType,
          ),
          style: rubikRegular.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
      ),
    );
  }
}
