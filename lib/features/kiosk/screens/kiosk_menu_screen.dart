import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:acafe_customer/common/models/product_model.dart';
import 'package:acafe_customer/common/widgets/custom_image_widget.dart';
import 'package:acafe_customer/features/category/providers/category_provider.dart';
import 'package:acafe_customer/features/language/providers/localization_provider.dart';
import 'package:acafe_customer/features/splash/providers/splash_provider.dart';
import 'package:acafe_customer/helper/price_converter_helper.dart';
import 'package:acafe_customer/helper/router_helper.dart';
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

/// Kiosk main menu: brand bar on top, vertical category rail on the left and a
/// responsive product grid on the right. Categories and products come from the
/// backend via [CategoryProvider].
class KioskMenuScreen extends StatefulWidget {
  const KioskMenuScreen({super.key});

  @override
  State<KioskMenuScreen> createState() => _KioskMenuScreenState();
}

class _KioskMenuScreenState extends State<KioskMenuScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    await categoryProvider.getCategoryList(false);

    // Auto-select the first category so the grid isn't empty on first paint.
    final categories = categoryProvider.categoryList;
    if (categories != null && categories.isNotEmpty) {
      categoryProvider.getCategoryProductList('${categories.first.id}', 1);
    }
  }

  void _onSelectCategory(int id) {
    Provider.of<CategoryProvider>(context, listen: false)
        .getCategoryProductList('$id', 1);
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CategoryRail(onSelect: _onSelectCategory),
                  const Expanded(child: _ProductArea()),
                ],
              ),
            ),
          ],
        ),
      ),
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
        return SizedBox(
          width: 168,
          child: categories == null
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final c = categories[index];
                    final bool selected = '${c.id}' == category.selectedSubCategoryId;
                    return InkWell(
                      onTap: () => onSelect(c.id!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeDefault,
                          vertical: Dimensions.paddingSizeLarge,
                        ),
                        color: selected ? Theme.of(context).cardColor : Colors.transparent,
                        child: Row(
                          children: [
                            if (selected)
                              Container(
                                width: 3,
                                height: 28,
                                margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                                color: Theme.of(context).primaryColor,
                              ),
                            Expanded(
                              child: Text(
                                (c.name ?? '').toUpperCase(),
                                style: (selected ? rubikSemiBold : rubikRegular).copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  letterSpacing: 0.5,
                                  color: selected
                                      ? Theme.of(context).textTheme.bodyLarge!.color
                                      : Theme.of(context).hintColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
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
                              'No items',
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

    return Column(
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
    );
  }
}
