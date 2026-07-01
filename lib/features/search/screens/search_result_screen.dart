// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:acafe_customer/common/providers/product_provider.dart'; // Veg/Non-Veg filter (commented below)
import 'package:acafe_customer/common/widgets/custom_asset_image_widget.dart';
import 'package:acafe_customer/common/widgets/custom_text_field_widget.dart';
import 'package:acafe_customer/common/widgets/footer_widget.dart';
import 'package:acafe_customer/common/widgets/no_data_widget.dart';
import 'package:acafe_customer/common/widgets/paginated_list_widget.dart';
import 'package:acafe_customer/common/widgets/product_shimmer_widget.dart';
import 'package:acafe_customer/common/widgets/web_app_bar_widget.dart';
import 'package:acafe_customer/features/category/providers/category_provider.dart';
import 'package:acafe_customer/features/home/enums/product_group_enum.dart';
import 'package:acafe_customer/features/home/enums/quantity_position_enum.dart';
import 'package:acafe_customer/features/home/widgets/product_card_widget.dart';
import 'package:acafe_customer/common/models/product_model.dart';
import 'package:acafe_customer/common/widgets/custom_image_widget.dart';
import 'package:acafe_customer/features/kiosk/screens/kiosk_product_customize_sheet.dart';
import 'package:acafe_customer/features/kiosk/widgets/kiosk_tap.dart';
import 'package:acafe_customer/features/search/providers/search_provider.dart';
import 'package:acafe_customer/features/search/widget/filter_widget.dart';
import 'package:acafe_customer/features/search/widget/food_filter_button_widget.dart'; // Veg/Non-Veg filter (commented below)
import 'package:acafe_customer/features/search/widget/kiosk_search_theme.dart';
import 'package:acafe_customer/features/splash/providers/splash_provider.dart';
import 'package:acafe_customer/helper/price_converter_helper.dart';
import 'package:acafe_customer/helper/responsive_helper.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/main.dart';
import 'package:acafe_customer/utill/dimensions.dart';
import 'package:acafe_customer/utill/images.dart';
import 'package:acafe_customer/utill/styles.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SearchResultScreen extends StatefulWidget {
  final String? searchString;
  const SearchResultScreen({super.key, required this.searchString});

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  String _type = 'all';

  @override
  void initState() {
    super.initState();

    final CategoryProvider categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final SearchProvider searchProvider = Provider.of<SearchProvider>(context, listen: false);

    searchProvider.resetFilterData(isUpdate: false);

    int atamp = 0;
    if (atamp == 0) {
      _searchController.text = widget.searchString!.replaceAll('-', ' ');
      atamp = 1;
    }

    if(categoryProvider.categoryList == null) {
      categoryProvider.getCategoryList(true);
    }
    searchProvider.saveSearchAddress(_searchController.text);
    searchProvider.searchProduct(offset: 1, name: _searchController.text, context: context, isUpdate: false);
  }

  @override
  void dispose() {
    super.dispose();

    Provider.of<SearchProvider>(Get.context!, listen: false).resetFilterData(isUpdate: false);


  }

  @override
  Widget build(BuildContext context) {
    // final productProvider = Provider.of<ProductProvider>(context, listen: false); // Veg/Non-Veg filter (commented below)
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    double topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: isDesktop ? null : KioskSearchTheme.pageBg,
      appBar: PreferredSize(preferredSize: const Size.fromHeight(100), child: isDesktop ?  const WebAppBarWidget() :
      Container(
        color: KioskSearchTheme.pageBg,
        padding : EdgeInsets.only(
          top: topPadding < 20 ? 40  : 0,
          bottom: Dimensions.paddingSizeDefault,
          right: Dimensions.paddingSizeLarge,
          left: Dimensions.paddingSizeDefault,
        ),
        child: SafeArea(
          child: Row(children: [

            _ResultCircleButton(
              icon: Icons.arrow_back_ios_new,
              onTap: () => context.pop(),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            Consumer<SearchProvider>(
                builder: (context, searchProvider, _) {
                  return Expanded(child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                    decoration: BoxDecoration(
                      color: KioskSearchTheme.surface,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: KioskSearchTheme.border),
                    ),
                    child: CustomTextFieldWidget(
                      hintText: getTranslated('search_items_here', context),
                      isShowBorder: false,
                      isShowSuffixIcon: true,
                      suffixIconUrl: Images.closeSvg,
                      suffixIconColor: null,
                      controller: _searchController,
                      inputAction: TextInputAction.search,
                      isIcon: true,
                      onSubmit: (value){
                        searchProvider.saveSearchAddress(value);
                        searchProvider.searchProduct(offset: 1, name: value, context: context);
                      },

                      onSuffixTap: () {
                        _searchController.clear();
                      },
                    ),
                  ));
                }
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            const SearchFilterButtonWidget(),

          ]),
        ),
      )),
      body: CustomScrollView(controller: scrollController, slivers: [

        SliverToBoxAdapter(child: Center(child: SizedBox(
          width: Dimensions.webScreenWidth,
          child: Consumer<SearchProvider>(
            builder: (context, searchProvider, child) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              /// for search bar
              if(!isDesktop)

              const SizedBox(height: Dimensions.paddingSizeDefault),


              Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  searchProvider.searchProductModel != null ? Center(
                    child: Container(
                      width: Dimensions.webScreenWidth, padding: EdgeInsets.only(
                      top: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeDefault : 0,
                      bottom: Dimensions.paddingSizeDefault,
                    ),
                      child: Row(children: [

                        Expanded(child: _searchController.text.trim().isEmpty ? const SizedBox() : RichText(softWrap: true, text: TextSpan(text: '', children: <TextSpan>[
                          TextSpan(
                            text: '${searchProvider.searchProductModel?.products?.length} ',
                            style: swiss721Light.copyWith(fontSize: Dimensions.fontSizeDefault, color: KioskSearchTheme.muted),
                          ),
                          TextSpan(
                            text: '${getTranslated('results_for', context)} ',
                            style: swiss721Light.copyWith(fontSize: Dimensions.fontSizeDefault, color: KioskSearchTheme.muted),
                          ),
                          TextSpan(text: '" ${_searchController.text} "', style: loewExtraBold.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                            color: KioskSearchTheme.primary,
                          )),
                        ]))),
                        const SizedBox(width: Dimensions.paddingSizeDefault),

                        // Veg / Non-Veg filter hidden (café — not relevant)
                        // IgnorePointer(
                        //   ignoring: searchProvider.searchProductModel == null,
                        //   child: FoodFilterButtonWidget(
                        //     type: _type,
                        //     items: productProvider.productTypeList,
                        //     isBorder: true,
                        //     onSelected: (selected) {
                        //       _type = selected;
                        //       searchProvider.searchProduct(name: _searchController.text, productType: _type, isUpdate: true, offset: 1, context: context);
                        //     },
                        //   ),
                        // ),

                        if(isDesktop) const SizedBox(width: Dimensions.paddingSizeDefault),
                        if(isDesktop) const SearchFilterButtonWidget(),

                      ]),
                    ),
                  ) : const SizedBox.shrink(),

                  searchProvider.searchProductModel == null ? LayoutBuilder(
                    builder: (context, constraints) {
                      final geo = _KioskResultGrid.geometryFor(constraints.maxWidth);
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisSpacing: geo.gap, mainAxisSpacing: geo.gap,
                          crossAxisCount: geo.columns,
                          mainAxisExtent: geo.tileHeight,
                        ),
                        itemCount: geo.columns * 2,
                        itemBuilder: (BuildContext context, int index) =>
                            _KioskResultSkeleton(tileWidth: geo.tileWidth),
                        padding: EdgeInsets.zero,
                      );
                    },
                  ) :
                  (searchProvider.searchProductModel?.products?.isNotEmpty ?? false) ?  Padding(
                    padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                    child: PaginatedListWidget(
                      scrollController: scrollController,
                      onPaginate: (int? offset){
                        searchProvider.searchProduct(name: _searchController.text, offset: offset ?? 1, context: context, productType: _type);
                      },
                      totalSize: searchProvider.searchProductModel?.totalSize,
                      offset: searchProvider.searchProductModel?.offset,
                      builder: (_)=> LayoutBuilder(
                        builder: (context, constraints) {
                          final geo = _KioskResultGrid.geometryFor(constraints.maxWidth);
                          return GridView.builder(
                            padding: EdgeInsets.zero,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisSpacing: geo.gap, mainAxisSpacing: geo.gap,
                              crossAxisCount: geo.columns,
                              mainAxisExtent: geo.tileHeight,
                            ),
                            itemCount: searchProvider.searchProductModel?.products?.length,
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemBuilder: (context, index) => _KioskResultCard(
                              product: searchProvider.searchProductModel!.products![index],
                              tileWidth: geo.tileWidth,
                            ),
                          );
                        },
                      ),
                    ),
                  ) : const Center(child: NoDataWidget(isFooter: false)),





                ]),
              ),





            ]),
          ),
        ))),



        if(ResponsiveHelper.isDesktop(context)) const SliverFillRemaining(
          hasScrollBody: false,
          child: FooterWidget(),
        ),

        ],
      ),
    );
  }
}

/// Responsive geometry for the search result grid — mirrors the kiosk menu:
/// 3 products per row on phones/small screens, growing on larger displays, with
/// tall portrait cards whose text scales with the tile width.
class _KioskResultGrid {
  final int columns;
  final double gap;
  final double tileWidth;
  final double tileHeight;
  const _KioskResultGrid(this.columns, this.gap, this.tileWidth, this.tileHeight);

  static _KioskResultGrid geometryFor(double width) {
    int columns;
    if (width < 900) {
      columns = 3;
    } else if (width < 1400) {
      columns = 4;
    } else if (width < 1900) {
      columns = 5;
    } else {
      columns = 6;
    }
    const double gap = Dimensions.paddingSizeDefault;
    final double tileWidth = (width - gap * (columns - 1)) / columns;
    final double tileHeight = tileWidth / 0.72 + tileWidth * 0.34;
    return _KioskResultGrid(columns, gap, tileWidth, tileHeight);
  }
}

/// A search-result product card that matches the kiosk menu design: white
/// rounded card with the portrait image and the name + price inside it. No
/// "Add" button — tapping the card opens the customise sheet (same as the menu).
class _KioskResultCard extends StatelessWidget {
  final Product product;
  final double tileWidth;
  const _KioskResultCard({required this.product, required this.tileWidth});

  @override
  Widget build(BuildContext context) {
    final splash = Provider.of<SplashProvider>(context, listen: false);
    final String image = '${splash.baseUrls?.productImageUrl}/${product.image}';
    final double ts = tileWidth / 564.0;

    return KioskTap(
      onTap: () => openKioskCustomize(context, product),
      child: Material(
        color: KioskSearchTheme.surface,
        borderRadius: BorderRadius.circular(60 * ts),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shadowColor: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.all(24 * ts),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40 * ts),
                  child: CustomImageWidget(
                    placeholder: Images.placeholderImage,
                    image: image,
                    fit: BoxFit.cover,
                    useShimmer: true,
                  ),
                ),
              ),
              SizedBox(height: 16 * ts),
              Text(
                product.name ?? '',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: loewExtraBold.copyWith(fontSize: 32 * ts, height: 1.1, color: KioskSearchTheme.primary),
              ),
              SizedBox(height: 8 * ts),
              Text(
                PriceConverterHelper.convertPrice(
                  product.price,
                  discount: product.discount,
                  discountType: product.discountType,
                ),
                textAlign: TextAlign.center,
                style: swiss721Light.copyWith(fontSize: 36 * ts, color: KioskSearchTheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmering skeleton card that matches [_KioskResultCard]'s geometry.
class _KioskResultSkeleton extends StatelessWidget {
  final double tileWidth;
  const _KioskResultSkeleton({required this.tileWidth});

  @override
  Widget build(BuildContext context) {
    final double ts = tileWidth / 564.0;
    return Material(
      color: KioskSearchTheme.surface,
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
            Center(child: CustomImageWidget.shimmerBox(width: 140 * ts, height: 34 * ts)),
          ],
        ),
      ),
    );
  }
}

/// Small white circular icon button (back) in the kiosk theme.
class _ResultCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ResultCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return KioskTap(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: KioskSearchTheme.surface,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: KioskSearchTheme.primary),
      ),
    );
  }
}

class SearchFilterButtonWidget extends StatelessWidget {
  const SearchFilterButtonWidget({
    super.key,
  });


  @override
  Widget build(BuildContext context) {
    final double widthSize = MediaQuery.sizeOf(context).width;
    final double heightSize = MediaQuery.sizeOf(context).height;

    List<double?> prices = [];
    prices.sort();
    double? maxValue = prices.isNotEmpty ? prices[prices.length-1] : 1000;

    return ResponsiveHelper.isDesktop(context) ? PopupMenuButton<dynamic>(
      menuPadding: EdgeInsets.zero,
      offset: const Offset(0, 40),
      constraints: BoxConstraints(maxWidth: widthSize * 0.21),
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          padding: EdgeInsets.zero,
          value: 'open_filter',
          child: SizedBox(height: heightSize * 0.7, width: double.maxFinite, child: FilterWidget(maxValue: maxValue)),
        ),
      ],
      onSelected: (dynamic value) {
      },
      padding: const EdgeInsets.symmetric(horizontal: 2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(Dimensions.paddingSizeSmall)),
      ),
      child: CustomAssetImageWidget(Images.filterSvg, width: 25, height: 25, color: Theme.of(context).primaryColor),
    ) : KioskTap(
      onTap: () {
        showModalBottomSheet(
          isDismissible: true,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          useSafeArea: true,
          context: context,
          builder: (ctx) => Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
              padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
              decoration: const BoxDecoration(
                color: KioskSearchTheme.pageBg,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
              ),
              child: FilterWidget(maxValue: maxValue)),
        );
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: KioskSearchTheme.surface,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const CustomAssetImageWidget(Images.filterSvg, width: 22, height: 22, color: KioskSearchTheme.primary),
      ),
    );
  }
}
