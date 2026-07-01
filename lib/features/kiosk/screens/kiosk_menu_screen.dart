import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:acafe_customer/common/models/cart_model.dart';
import 'package:acafe_customer/common/models/product_model.dart';
import 'package:acafe_customer/common/widgets/custom_image_widget.dart';
import 'package:acafe_customer/features/cart/providers/cart_provider.dart';
import 'package:acafe_customer/features/category/providers/category_provider.dart';
import 'package:acafe_customer/features/kiosk/domain/kiosk_menu_image_helper.dart';
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

// The chrome (brand bar, rail cards, cart bar, typography) scales linearly with
// the screen but is clamped so it stays legible on phones and doesn't inflate
// into giant elements on ultra-wide monitors — beyond the artboard width the
// extra space is filled with MORE product columns instead of bigger cards.
const double _kMinScale = 0.24;
const double _kMaxScale = 1.0;

// Warm beige page background + static promo/badge colours from the design.
const Color _kPageBg = Color(0xFFF7F1DE);
const Color _kPopularGreen = Color(0xFF357937);
const Color _kSpecialRed = Color(0xFF59030E);

/// Figma artboard px → logical px for the current screen width (clamped).
double _scaleFor(double screenWidth) =>
    (screenWidth / _kDesignWidth).clamp(_kMinScale, _kMaxScale);

/// Responsive product-grid column count for the given product-area width.
///
/// Per the Figma design, the kiosk shows 3 products per row — so 3 columns is
/// the minimum on every device (phones included), and larger desktop / 4K
/// displays step up to 4–6 so cards never balloon.
int _kioskColumnsForWidth(double productAreaWidth) {
  if (productAreaWidth < 1080) return 3; // phone → kiosk → small/medium
  if (productAreaWidth < 1550) return 4;
  if (productAreaWidth < 2100) return 5;
  return 6;
}

/// Removes the overscroll glow/stretch so dragging the grid past its top edge
/// doesn't paint a grey "shadow" over the page (matches a clean kiosk look).
class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
}

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
    final locale =
        Provider.of<LocalizationProvider>(context, listen: false).locale.languageCode;
    await categoryProvider.prefetchKioskMenu(localeCode: locale, force: true);
    if (!mounted) return;
    KioskMenuImageHelper.precacheFromProvider(
      context,
      categoryProvider,
      Provider.of<SplashProvider>(context, listen: false),
    );
  }

  Future<void> _loadData() async {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final locale =
        Provider.of<LocalizationProvider>(context, listen: false).locale.languageCode;
    final splash = Provider.of<SplashProvider>(context, listen: false);

    // Prefetched on the welcome screen — render immediately, refresh in background.
    if (categoryProvider.isKioskMenuReadyFor(locale)) {
      KioskMenuImageHelper.precacheFromProvider(context, categoryProvider, splash);
      categoryProvider.prefetchKioskMenu(localeCode: locale, background: true);
      return;
    }

    // Edge case: deep-linked to /menu-kiosk without visiting welcome first.
    await categoryProvider.ensureKioskMenuReady(localeCode: locale);
    if (!mounted) return;
    KioskMenuImageHelper.precacheFromProvider(context, categoryProvider, splash);
  }

  Future<void> _onSelectCategory(int id) async {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    // Instant swap from the prefetched cache (silent background refresh if stale).
    await categoryProvider.selectKioskCategory('$id');
    if (!mounted) return;
    KioskMenuImageHelper.precacheProducts(
      context,
      Provider.of<SplashProvider>(context, listen: false),
      categoryProvider.categoryProductModel?.products ?? [],
    );
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
          // Border painted as a foreground decoration so it sits ON TOP of the
          // card content (the right-hand image). In `decoration` it renders
          // behind the image, so the image clipped the border on its side.
          foregroundDecoration: selected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(color: Colors.black, width: (6 * s).clamp(2.0, 8.0)),
                )
              : null,
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
                    useShimmer: true,
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
                  ? _ProductGridSkeleton(s: s)
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns = _kioskColumnsForWidth(constraints.maxWidth);
        final double colGap = 41 * s;
        final double rowGap = 55 * s;
        final double tileWidth =
            (constraints.maxWidth - colGap * (columns - 1)) / columns;
        // Each tile is a white card holding the (portrait) image plus the name
        // and price inside it — so the card height = image + text block. The
        // text block scales with the tile width (not the global scale) so the
        // name/price stay proportional whatever the column count.
        final double imageHeight = tileWidth / 0.72;
        final double textBlockHeight = tileWidth * 0.34;
        final double tileHeight = imageHeight + textBlockHeight;

        // Split so the full-width promo banner sits after the first two rows.
        final int firstCount = products.length >= columns * 2
            ? columns * 2
            : products.length;
        final List<Product> remaining = products.sublist(firstCount);

        final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: colGap,
          mainAxisSpacing: rowGap,
          mainAxisExtent: tileHeight,
        );

        return ScrollConfiguration(
          behavior: const _NoGlowScrollBehavior(),
          child: CustomScrollView(
            slivers: [
              SliverGrid(
                gridDelegate: gridDelegate,
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _KioskProductCard(
                    s: s,
                    tileWidth: tileWidth,
                    product: products[index],
                    badge: _badgeFor(index, columns),
                  ),
                  childCount: firstCount,
                ),
              ),
              SliverToBoxAdapter(child: _PromoBanner(s: s)),
              if (remaining.isNotEmpty)
                SliverGrid(
                  gridDelegate: gridDelegate,
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _KioskProductCard(
                        s: s, tileWidth: tileWidth, product: remaining[index]),
                    childCount: remaining.length,
                  ),
                ),
              SliverToBoxAdapter(child: SizedBox(height: 30 * s)),
            ],
          ),
        );
      },
    );
  }

  /// Static badges to match the design — first tile is "Popular", and the first
  /// tile of the second row is "Special".
  _Badge? _badgeFor(int index, int columns) {
    if (index == 0) return const _Badge('Popular', _kPopularGreen);
    if (index == columns) return const _Badge('Special', _kSpecialRed);
    return null;
  }
}

class _Badge {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);
}

/// Loading skeleton for the product grid: shimmering white cards laid out with
/// the exact same responsive geometry as [_ProductGrid], so the switch from
/// skeleton → real products is a seamless in-place swap (no size jump).
class _ProductGridSkeleton extends StatelessWidget {
  final double s;
  const _ProductGridSkeleton({required this.s});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns = _kioskColumnsForWidth(constraints.maxWidth);
        final double colGap = 41 * s;
        final double rowGap = 55 * s;
        final double tileWidth =
            (constraints.maxWidth - colGap * (columns - 1)) / columns;
        final double imageHeight = tileWidth / 0.72;
        final double textBlockHeight = tileWidth * 0.34;
        final double tileHeight = imageHeight + textBlockHeight;

        return IgnorePointer(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: columns * 2,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: colGap,
              mainAxisSpacing: rowGap,
              mainAxisExtent: tileHeight,
            ),
            itemBuilder: (context, index) => _SkeletonCard(tileWidth: tileWidth),
          ),
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double tileWidth;
  const _SkeletonCard({required this.tileWidth});

  @override
  Widget build(BuildContext context) {
    final double ts = tileWidth / 564.0;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(60 * ts),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(24 * ts),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40 * ts),
                child: CustomImageWidget.shimmerBox(),
              ),
            ),
            SizedBox(height: 24 * ts),
            CustomImageWidget.shimmerBox(width: double.infinity, height: 34 * ts),
            SizedBox(height: 14 * ts),
            Center(
              child: CustomImageWidget.shimmerBox(width: 140 * ts, height: 34 * ts),
            ),
          ],
        ),
      ),
    );
  }
}

class _KioskProductCard extends StatelessWidget {
  final double s;
  final double tileWidth;
  final Product product;
  final _Badge? badge;
  const _KioskProductCard({
    required this.s,
    required this.tileWidth,
    required this.product,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final splash = Provider.of<SplashProvider>(context, listen: false);
    final String image = '${splash.baseUrls?.productImageUrl}/${product.image}';
    // Metrics scale with the actual tile width (design tile ≈ 564px) so the card
    // keeps the same proportions no matter how many columns fit on screen.
    final double ts = tileWidth / 564.0;
    final double cardRadius = 60 * ts;
    final double imageRadius = 40 * ts;

    // White rounded card containing the image AND the name + price (matches the
    // Figma layout where text sits inside the card, not on the page below it).
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openKioskCustomize(context, product),
        child: Padding(
          padding: EdgeInsets.all(24 * ts),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(imageRadius),
                        child: CustomImageWidget(
                          placeholder: Images.placeholderImage,
                          image: image,
                          fit: BoxFit.cover,
                          useShimmer: true,
                        ),
                      ),
                    ),
                    if (badge != null)
                      Positioned(
                        top: 30 * ts,
                        left: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 28 * ts, vertical: 10 * ts),
                          decoration: BoxDecoration(
                            color: badge!.color,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(10 * ts),
                              bottomRight: Radius.circular(10 * ts),
                            ),
                          ),
                          child: Text(
                            badge!.label,
                            style: swiss721Light.copyWith(color: Colors.white, fontSize: 34 * ts),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 16 * ts),
              Text(
                product.name ?? '',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: loewExtraBold.copyWith(fontSize: 32 * ts, height: 1.1, color: Colors.black),
              ),
              SizedBox(height: 8 * ts),
              Text(
                PriceConverterHelper.convertPrice(
                  product.price,
                  discount: product.discount,
                  discountType: product.discountType,
                ),
                textAlign: TextAlign.center,
                style: swiss721Light.copyWith(fontSize: 36 * ts, color: Colors.black),
              ),
            ],
          ),
        ),
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

// Dark button fill + cream text used by the filled cart bar (from the design).
const Color _kDarkButton = Color(0xFF1E1E1E);
const Color _kCreamText = Color(0xFFF3F3DD);

/// Fixed cart bar pinned to the bottom of the menu. Two states (per Figma):
///  • empty  → a single "CART / € 0.00" bar.
///  • filled → a COMBO MEAL upsell card on the left and VIEW CART (with the
///    item count) over CHECK OUT (with the total) on the right.
class _CartBar extends StatelessWidget {
  final double s;
  final double sideMargin;
  const _CartBar({required this.s, required this.sideMargin});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final cartList = cartProvider.cartList;
        final double total = kioskCartTotal(cartList);
        final int count = kioskCartItemCount(cartList);

        return Padding(
          padding: EdgeInsets.fromLTRB(sideMargin, 20 * s, sideMargin, 30 * s),
          child: count == 0
              ? _EmptyCartBar(s: s, total: total)
              : _FilledCartBar(s: s, total: total, count: count, cartList: cartList),
        );
      },
    );
  }
}

class _EmptyCartBar extends StatelessWidget {
  final double s;
  final double total;
  const _EmptyCartBar({required this.s, required this.total});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(80 * s),
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: () => RouterHelper.getKioskCartRoute(),
        child: Container(
          height: 200 * s,
          padding: EdgeInsets.symmetric(horizontal: 100 * s),
          alignment: Alignment.centerLeft,
          child: Text(
            '${getTranslated('cart', context) ?? 'CART'} / ${PriceConverterHelper.convertPrice(total)}',
            style: loewExtraBold.copyWith(fontSize: 64 * s, color: Colors.black),
          ),
        ),
      ),
    );
  }
}

class _FilledCartBar extends StatelessWidget {
  final double s;
  final double total;
  final int count;
  final List<CartModel?> cartList;
  const _FilledCartBar({
    required this.s,
    required this.total,
    required this.count,
    required this.cartList,
  });

  @override
  Widget build(BuildContext context) {
    // The most recently added item is shown on the left.
    final CartModel? latest = cartList.isNotEmpty ? cartList.last : null;
    return SizedBox(
      height: 290 * s,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: the latest item added to the cart.
          Expanded(flex: 47, child: _LatestItemCard(s: s, cart: latest, index: cartList.length - 1)),
          SizedBox(width: 30 * s),
          // Right: VIEW CART over CHECK OUT.
          Expanded(
            flex: 44,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _ViewCartButton(s: s, count: count)),
                SizedBox(height: 20 * s),
                Expanded(child: _CheckoutButton(s: s, total: total)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewCartButton extends StatelessWidget {
  final double s;
  final int count;
  const _ViewCartButton({required this.s, required this.count});

  @override
  Widget build(BuildContext context) {
    final double radius = 50 * s;
    final double badge = 56 * s;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => RouterHelper.getKioskCartRoute(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.black, width: (4 * s).clamp(2.0, 6.0)),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                getTranslated('view_cart', context) ?? 'VIEW CART',
                style: loewExtraBold.copyWith(fontSize: 46 * s, color: Colors.black),
              ),
              SizedBox(width: 24 * s),
              Container(
                width: badge,
                height: badge,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: _kDarkButton, shape: BoxShape.circle),
                child: Text(
                  '$count',
                  style: loewExtraBold.copyWith(fontSize: 30 * s, color: _kCreamText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutButton extends StatelessWidget {
  final double s;
  final double total;
  const _CheckoutButton({required this.s, required this.total});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kDarkButton,
      borderRadius: BorderRadius.circular(50 * s),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => RouterHelper.getKioskCheckoutRoute(),
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 30 * s),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  getTranslated('check_out', context) ?? 'CHECK OUT',
                  style: loewExtraBold.copyWith(fontSize: 46 * s, color: _kCreamText),
                ),
                SizedBox(width: 28 * s),
                Text(
                  PriceConverterHelper.convertPrice(total),
                  style: loewExtraBold.copyWith(fontSize: 46 * s, color: _kCreamText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The most recently added cart item shown on the left of the filled cart bar:
/// its image, name and price, with a "+" to add another of the same item.
class _LatestItemCard extends StatelessWidget {
  final double s;
  final CartModel? cart;
  final int index;
  const _LatestItemCard({required this.s, required this.cart, required this.index});

  @override
  Widget build(BuildContext context) {
    final splash = Provider.of<SplashProvider>(context, listen: false);
    final product = cart?.product;
    final String image = '${splash.baseUrls?.productImageUrl}/${product?.image}';
    final double unitPrice = cart?.discountedPrice ?? cart?.price ?? (product?.price ?? 0);
    final double plus = 64 * s;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(80 * s),
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: () => RouterHelper.getKioskCartRoute(),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(40 * s, 24 * s, 40 * s, 24 * s),
              child: Row(
                children: [
                  // Latest product image (square).
                  AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40 * s),
                      child: CustomImageWidget(
                        placeholder: Images.placeholderImage,
                        image: image,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 30 * s),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product?.name ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: loewExtraBold.copyWith(fontSize: 38 * s, height: 1.1, color: Colors.black),
                        ),
                        SizedBox(height: 8 * s),
                        Text(
                          PriceConverterHelper.convertPrice(unitPrice),
                          style: swiss721Light.copyWith(fontSize: 32 * s, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: plus + 16 * s), // room for the "+" button.
                ],
              ),
            ),
            // "+" — add another of this item.
            Positioned(
              right: 24 * s,
              bottom: 24 * s,
              child: Material(
                color: _kDarkButton,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: product == null
                      ? null
                      : () => Provider.of<CartProvider>(context, listen: false)
                          .onUpdateCartQuantity(index: index, product: product, isRemove: false),
                  child: SizedBox(
                    width: plus,
                    height: plus,
                    child: Icon(Icons.add, color: _kCreamText, size: 40 * s),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
