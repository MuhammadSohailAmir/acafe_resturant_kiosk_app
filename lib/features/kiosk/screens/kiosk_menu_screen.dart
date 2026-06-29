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
import 'package:acafe_customer/utill/images.dart';
import 'package:acafe_customer/utill/styles.dart';
import 'package:provider/provider.dart';

// ===========================================================================
// KIOSK MENU — faithful, fully-responsive port of the Figma "Kiosk 55 inch"
// design (node 582:9515).
//
// RESPONSIVENESS MODEL: every size below is taken straight from the Figma
// artboard (which is _kDesignWidth px wide) and scaled by `s = screenWidth /
// _kDesignWidth`. So the layout reproduces the design pixel-for-pixel at the
// artboard width and scales uniformly for any other screen — phone, tablet, or
// the real 55" 4K kiosk. Use `px(figmaValue)` everywhere instead of constants.
// ===========================================================================
const double _kDesignWidth = 2572;

// Warm beige page background + static promo/badge colours from the design.
const Color _kPageBg = Color(0xFFF7F1DE);
const Color _kPopularGreen = Color(0xFF357937);
const Color _kSpecialRed = Color(0xFF59030E);

/// Figma artboard px → logical px for the current screen width.
double _scaleFor(double screenWidth) => screenWidth / _kDesignWidth;

/// Kiosk main menu: centered brand bar on top, a vertical category rail (white
/// image cards) on the left and a responsive 3-column product grid on the
/// right, with a fixed full-width cart bar pinned to the bottom.
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
      backgroundColor: _kPageBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double s = _scaleFor(constraints.maxWidth);
            final double sideMargin = 85 * s; // Figma left/right page margin.
            return Column(
              children: [
                _KioskTopBar(s: s, sideMargin: sideMargin),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: sideMargin),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Rail card column = 524px wide in the design.
                        _CategoryRail(s: s, onSelect: _onSelectCategory),
                        SizedBox(width: 104 * s), // gap rail → products.
                        Expanded(child: _ProductArea(s: s)),
                      ],
                    ),
                  ),
                ),
                _CartBar(s: s, sideMargin: sideMargin),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Top bar: centered "A/CAFÉ" brand title with circular search / filter /
/// language-flag actions on the right.
class _KioskTopBar extends StatelessWidget {
  final double s;
  final double sideMargin;
  const _KioskTopBar({required this.s, required this.sideMargin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(sideMargin, 40 * s, sideMargin, 30 * s),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered brand title (the A/CAFÉ brand, per the design).
          Text(
            'A/CAFÉ',
            style: loewExtraBold.copyWith(
              fontSize: 120 * s,
              height: 1,
              letterSpacing: 2 * s,
              color: Colors.black,
            ),
          ),
          // Right-aligned action icons.
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CircleIconButton(s: s, icon: Icons.search, onTap: () => RouterHelper.getSearchRoute()),
                SizedBox(width: 38 * s),
                _CircleIconButton(s: s, icon: Icons.tune, onTap: () {}),
                SizedBox(width: 38 * s),
                _LanguageFlagButton(s: s),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final double s;
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.s, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final double d = 120 * s; // circle diameter (Figma ~124px).
    return SizedBox(
      width: d,
      height: d,
      child: Material(
        color: Theme.of(context).cardColor,
        shape: const CircleBorder(),
        clipBehavior: Clip.hardEdge,
        elevation: 1,
        child: InkWell(
          onTap: onTap,
          child: Icon(icon, size: 60 * s, color: Colors.black),
        ),
      ),
    );
  }
}

class _LanguageFlagButton extends StatelessWidget {
  final double s;
  const _LanguageFlagButton({required this.s});

  @override
  Widget build(BuildContext context) {
    final String code = Provider.of<LocalizationProvider>(context).locale.languageCode;
    final language = AppConstants.languages.firstWhere(
      (l) => l.languageCode == code,
      orElse: () => AppConstants.languages.first,
    );
    final double d = 120 * s;

    return SizedBox(
      width: d,
      height: d,
      child: Material(
        color: Theme.of(context).cardColor,
        shape: const CircleBorder(),
        clipBehavior: Clip.hardEdge,
        elevation: 1,
        child: InkWell(
          onTap: () => RouterHelper.getLanguageRoute(true),
          child: Center(
            child: ClipOval(
              child: Image.asset(language.imageUrl!, width: 64 * s, height: 64 * s, fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }
}

/// Left rail of white category cards: category name on the left, photo on the
/// right; the selected card gets a black border (matches the design). 524px
/// wide in the Figma artboard, scaled by `s`.
class _CategoryRail extends StatelessWidget {
  final double s;
  final void Function(int id) onSelect;
  const _CategoryRail({required this.s, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final double railWidth = 524 * s;
    return Consumer<CategoryProvider>(
      builder: (context, category, _) {
        final categories = category.categoryList;
        if (categories == null) {
          return SizedBox(width: railWidth, child: const Center(child: CircularProgressIndicator()));
        }
        return SizedBox(
          width: railWidth,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(vertical: 20 * s),
            itemCount: categories.length,
            separatorBuilder: (_, __) => SizedBox(height: 58 * s),
            itemBuilder: (context, index) {
              final c = categories[index];
              final bool selected = '${c.id}' == category.selectedSubCategoryId;
              return _RailCard(
                s: s,
                name: c.name ?? '',
                image: c.image ?? '',
                selected: selected,
                onTap: () => onSelect(c.id!),
              );
            },
          ),
        );
      },
    );
  }
}

class _RailCard extends StatelessWidget {
  final double s;
  final String name;
  final String image;
  final bool selected;
  final VoidCallback onTap;
  const _RailCard({
    required this.s,
    required this.name,
    required this.image,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final splash = Provider.of<SplashProvider>(context, listen: false);
    final String imageUrl = image.isEmpty ? '' : '${splash.baseUrls?.categoryImageUrl}/$image';
    final double radius = 25 * s;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 281 * s, // Figma rail card height (landscape card).
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: selected ? Border.all(color: Colors.black, width: (6 * s).clamp(2.0, 8.0)) : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40 * s),
                  child: Text(
                    name.toUpperCase(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: loewBold.copyWith(
                      fontSize: 40 * s,
                      height: 1.1,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              if (imageUrl.isNotEmpty)
                SizedBox(
                  width: 230 * s,
                  height: double.infinity,
                  child: CustomImageWidget(
                    placeholder: Images.placeholderImage,
                    image: imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Right product area: category title, then a responsive 3-column product grid
/// with a static "SPECIAL EDITION" promo banner inserted after the first rows.
class _ProductArea extends StatelessWidget {
  final double s;
  const _ProductArea({required this.s});

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, category, _) {
        final products = category.categoryProductModel?.products;
        final selected = category.categoryList
            ?.where((c) => '${c.id}' == category.selectedSubCategoryId)
            .firstOrNull;
        final String title = selected?.name ?? '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(0, 10 * s, 0, 24 * s),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: loewExtraBold.copyWith(fontSize: 56 * s, color: Colors.black),
              ),
            ),
            Expanded(
              child: category.categoryProductModel == null
                  ? const Center(child: CircularProgressIndicator())
                  : products == null || products.isEmpty
                      ? Center(
                          child: Text(
                            getTranslated('no_items', context) ?? 'No items',
                            style: rubikRegular.copyWith(fontSize: 32 * s, color: Theme.of(context).hintColor),
                          ),
                        )
                      : _ProductGrid(s: s, products: products),
            ),
          ],
        );
      },
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final double s;
  final List<Product> products;
  const _ProductGrid({required this.s, required this.products});

  static const int _columns = 3; // matches the Figma kiosk layout.

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double colGap = 41 * s;
        final double rowGap = 55 * s;
        final double tileWidth = (constraints.maxWidth - colGap * (_columns - 1)) / _columns;
        // Product image is portrait (Figma 553×831 ≈ 0.665), plus name + price.
        final double imageHeight = tileWidth / 0.665;
        final double textBlockHeight = 150 * s;
        final double tileHeight = imageHeight + textBlockHeight;

        // Split so the full-width promo banner sits after the first two rows.
        final int firstCount =
            products.length >= _columns * 2 ? _columns * 2 : products.length;
        final List<Product> remaining = products.sublist(firstCount);

        final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _columns,
          crossAxisSpacing: colGap,
          mainAxisSpacing: rowGap,
          mainAxisExtent: tileHeight,
        );

        return CustomScrollView(
          slivers: [
            SliverGrid(
              gridDelegate: gridDelegate,
              delegate: SliverChildBuilderDelegate(
                (context, index) => _KioskProductCard(
                  s: s,
                  product: products[index],
                  badge: _badgeFor(index),
                ),
                childCount: firstCount,
              ),
            ),
            SliverToBoxAdapter(child: _PromoBanner(s: s)),
            if (remaining.isNotEmpty)
              SliverGrid(
                gridDelegate: gridDelegate,
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _KioskProductCard(s: s, product: remaining[index]),
                  childCount: remaining.length,
                ),
              ),
            SliverToBoxAdapter(child: SizedBox(height: 30 * s)),
          ],
        );
      },
    );
  }

  /// Static badges to match the design — first tile is "Popular", and the first
  /// tile of the second row is "Special".
  _Badge? _badgeFor(int index) {
    if (index == 0) return const _Badge('Popular', _kPopularGreen);
    if (index == _columns) return const _Badge('Special', _kSpecialRed);
    return null;
  }
}

class _Badge {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);
}

class _KioskProductCard extends StatelessWidget {
  final double s;
  final Product product;
  final _Badge? badge;
  const _KioskProductCard({required this.s, required this.product, this.badge});

  @override
  Widget build(BuildContext context) {
    final splash = Provider.of<SplashProvider>(context, listen: false);
    final String image = '${splash.baseUrls?.productImageUrl}/${product.image}';
    final double radius = 60 * s;

    return InkWell(
      onTap: () => openKioskCustomize(context, product),
      borderRadius: BorderRadius.circular(radius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: CustomImageWidget(
                      placeholder: Images.placeholderImage,
                      image: image,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (badge != null)
                  Positioned(
                    top: 50 * s,
                    left: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 28 * s, vertical: 10 * s),
                      decoration: BoxDecoration(
                        color: badge!.color,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(10 * s),
                          bottomRight: Radius.circular(10 * s),
                        ),
                      ),
                      child: Text(
                        badge!.label,
                        style: swiss721Light.copyWith(color: Colors.white, fontSize: 34 * s),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 16 * s),
          Text(
            product.name ?? '',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: loewExtraBold.copyWith(fontSize: 32 * s, height: 1.1, color: Colors.black),
          ),
          SizedBox(height: 8 * s),
          Text(
            PriceConverterHelper.convertPrice(
              product.price,
              discount: product.discount,
              discountType: product.discountType,
            ),
            textAlign: TextAlign.center,
            style: swiss721Light.copyWith(fontSize: 36 * s, color: Colors.black),
          ),
        ],
      ),
    );
  }
}

/// Static, decorative "SPECIAL EDITION" promo banner inserted mid-grid. Not
/// data-driven (the product API has no promo field).
class _PromoBanner extends StatelessWidget {
  final double s;
  const _PromoBanner({required this.s});

  @override
  Widget build(BuildContext context) {
    final double medallion = 360 * s;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24 * s),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(60 * s),
        child: Container(
          height: 760 * s,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF6B4A2F), Color(0xFFB98E5E)],
            ),
          ),
          padding: EdgeInsets.all(60 * s),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'SPECIAL EDITION',
                    softWrap: true,
                    style: loewExtraBold.copyWith(
                      color: Colors.white,
                      fontSize: 64 * s,
                      height: 1.1,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              // "OOH, YUMMY!" cream medallion.
              Container(
                width: medallion,
                height: medallion,
                alignment: Alignment.center,
                padding: EdgeInsets.all(30 * s),
                decoration: const BoxDecoration(color: Color(0xFFF3F1DD), shape: BoxShape.circle),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'OOH, YUMMY!',
                      textAlign: TextAlign.center,
                      style: loewExtraBold.copyWith(fontSize: 44 * s, color: Colors.black),
                    ),
                    SizedBox(height: 10 * s),
                    Text(
                      'Raspberry Matcha Latte',
                      textAlign: TextAlign.center,
                      style: scotchDisplayLight.copyWith(fontSize: 30 * s, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fixed full-width cart bar pinned to the bottom of the menu. Always visible
/// (shows the live total, € 0.00 when empty) and opens MY ORDER on tap.
class _CartBar extends StatelessWidget {
  final double s;
  final double sideMargin;
  const _CartBar({required this.s, required this.sideMargin});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final double total = kioskCartTotal(cartProvider.cartList);

        return Padding(
          padding: EdgeInsets.fromLTRB(sideMargin, 20 * s, sideMargin, 30 * s),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(80 * s),
            clipBehavior: Clip.antiAlias,
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            child: InkWell(
              onTap: () => RouterHelper.getKioskCartRoute(),
              child: Container(
                height: 200 * s, // Figma cart bar height (278px @ 2572 scaled down a touch).
                padding: EdgeInsets.symmetric(horizontal: 100 * s),
                alignment: Alignment.centerLeft,
                child: Text(
                  '${getTranslated('cart', context) ?? 'CART'} / ${PriceConverterHelper.convertPrice(total)}',
                  style: loewExtraBold.copyWith(fontSize: 64 * s, color: Colors.black),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
