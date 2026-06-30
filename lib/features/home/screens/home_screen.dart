import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:acafe_customer/common/enums/data_source_enum.dart';
import 'package:acafe_customer/common/providers/product_provider.dart';
import 'package:acafe_customer/common/widgets/branch_button_widget.dart';
import 'package:acafe_customer/common/widgets/branch_list_widget.dart';
import 'package:acafe_customer/common/widgets/custom_asset_image_widget.dart';
import 'package:acafe_customer/common/widgets/customizable_space_bar_widget.dart';
import 'package:acafe_customer/common/widgets/footer_widget.dart';
import 'package:acafe_customer/common/widgets/paginated_list_widget.dart';
import 'package:acafe_customer/common/widgets/sliver_delegate_widget.dart';
import 'package:acafe_customer/common/widgets/title_widget.dart';
import 'package:acafe_customer/common/widgets/web_app_bar_widget.dart';
import 'package:acafe_customer/features/address/providers/location_provider.dart';
import 'package:acafe_customer/features/auth/providers/auth_provider.dart';
import 'package:acafe_customer/features/branch/providers/branch_provider.dart';
import 'package:acafe_customer/features/cart/providers/cart_provider.dart';
import 'package:acafe_customer/features/cart/providers/frequently_bought_provider.dart';
import 'package:acafe_customer/features/category/providers/category_provider.dart';
import 'package:acafe_customer/features/checkout/widgets/selected_address_list_widget.dart';
import 'package:acafe_customer/features/home/providers/banner_provider.dart';
import 'package:acafe_customer/features/home/widgets/banner_widget.dart';
import 'package:acafe_customer/features/home/widgets/category_web_widget.dart';
import 'package:acafe_customer/features/home/widgets/chefs_recommendation_widget.dart';
import 'package:acafe_customer/features/home/widgets/home_local_eats_widget.dart';
import 'package:acafe_customer/features/home/widgets/home_set_menu_widget.dart';
import 'package:acafe_customer/features/home/widgets/product_view_widget.dart';
import 'package:acafe_customer/features/home/widgets/sorting_button_widget.dart';
import 'package:acafe_customer/features/menu/widgets/options_widget.dart';
import 'package:acafe_customer/features/order/providers/order_provider.dart';
import 'package:acafe_customer/features/profile/providers/profile_provider.dart';
import 'package:acafe_customer/features/search/providers/search_provider.dart';
import 'package:acafe_customer/features/splash/providers/splash_provider.dart';
import 'package:acafe_customer/features/wishlist/providers/wishlist_provider.dart';
import 'package:acafe_customer/helper/responsive_helper.dart';
import 'package:acafe_customer/helper/router_helper.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/main.dart';
import 'package:acafe_customer/utill/color_resources.dart';
import 'package:acafe_customer/utill/dimensions.dart';
import 'package:acafe_customer/utill/images.dart';
import 'package:acafe_customer/utill/styles.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  final bool fromAppBar;
  const HomeScreen(this.fromAppBar, {super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

  static Future<void> loadData(bool reload, {bool isFcmUpdate = false }) async {
    final ProductProvider productProvider = Provider.of<ProductProvider>(Get.context!, listen: false);
    final CategoryProvider categoryProvider = Provider.of<CategoryProvider>(Get.context!, listen: false);
    final SplashProvider splashProvider = Provider.of<SplashProvider>(Get.context!, listen: false);
    final BannerProvider bannerProvider = Provider.of<BannerProvider>(Get.context!, listen: false);
    final ProfileProvider profileProvider = Provider.of<ProfileProvider>(Get.context!, listen: false);
    final WishListProvider wishListProvider = Provider.of<WishListProvider>(Get.context!, listen: false);
    final SearchProvider searchProvider = Provider.of<SearchProvider>(Get.context!, listen: false);
    final FrequentlyBoughtProvider frequentlyBoughtProvider = Provider.of<FrequentlyBoughtProvider>(Get.context!, listen: false);

    final isLogin = Provider.of<AuthProvider>(Get.context!, listen: false).isLoggedIn();

    if(isLogin){
      profileProvider.getUserInfo(reload, isUpdate: reload);
      if(isFcmUpdate){
        Provider.of<AuthProvider>(Get.context!, listen: false).updateToken();
      }
    }else{
      profileProvider.setUserInfoModel = null;
    }
     wishListProvider.initWishList();

    if(productProvider.latestProductModel == null || reload) {
      productProvider.getLatestProductList(1, reload);
    }


    if(reload || productProvider.popularLocalProductModel == null){
      productProvider.getPopularLocalProductList(1,  true, isUpdate: false);
    }

    if(reload) {
       splashProvider.getPolicyPage();
    }
     categoryProvider.getCategoryList(reload, source: DataSourceEnum.local);

    if(productProvider.flavorfulMenuProductMenuModel == null || reload) {
      productProvider.getFlavorfulMenuProductMenuList(1, reload);
    }

    if(productProvider.recommendedProductModel == null || reload) {
      productProvider.getRecommendedProductList(1, reload);
    }

     bannerProvider.getBannerList(reload);
     searchProvider.getSearchRecommendedData(isReload: reload);
     frequentlyBoughtProvider.getFrequentlyBoughtProduct(1, reload);

  }
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> drawerGlobalKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _localEatsScrollController = ScrollController();
  final ScrollController _setMenuScrollController = ScrollController();
  final ScrollController _branchListScrollController = ScrollController();


  @override
  void initState() {
    final BranchProvider branchProvider = Provider.of<BranchProvider>(Get.context!, listen: false);
    branchProvider.getBranchValueList(context);
    HomeScreen.loadData(false);
    super.initState();
  }
  @override
  void dispose() {
    _scrollController.dispose();
    _localEatsScrollController.dispose();
    _setMenuScrollController.dispose();
    _branchListScrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final BranchProvider branchProvider = Provider.of<BranchProvider>(context, listen: false);

    return Scaffold(
      key: drawerGlobalKey,
      endDrawerEnableOpenDragGesture: false,
      drawer: ResponsiveHelper.isTab(context) ? const Drawer(child: OptionsWidget(onTap: null)) : const SizedBox(),
      appBar: isDesktop ? const PreferredSize(preferredSize: Size.fromHeight(100), child: WebAppBarWidget()) : null,
      body: RefreshIndicator(
        onRefresh: () async {
          Provider.of<OrderProvider>(context, listen: false).changeStatus(true, notify: true);
          Provider.of<SplashProvider>(context, listen: false).initConfig(context, DataSourceEnum.client).then((value) {
            if(value != null) {
              HomeScreen.loadData(true);
            }
          });
        },
        backgroundColor: Theme.of(context).primaryColor,
        color: Theme.of(context).cardColor,
        child: Consumer<ProductProvider>(builder: (context, productProvider, _)=> PaginatedListWidget(
          scrollController: _scrollController,
          onPaginate: (int? offset) async {
            await productProvider.getLatestProductList(offset ?? 1, false);
          },
          totalSize: productProvider.latestProductModel?.totalSize,
          offset: productProvider.latestProductModel?.offset,
          limit: productProvider.latestProductModel?.limit,
          isDisableWebLoader: !ResponsiveHelper.isDesktop(context),
          builder: (loaderWidget) {
            return Expanded(child: CustomScrollView(controller: _scrollController, slivers: [

              if(!isDesktop) SliverAppBar(
                pinned: true, toolbarHeight: Dimensions.paddingSizeDefault,
                automaticallyImplyLeading: false,
                expandedHeight: kIsWeb ? 84 : 64,
                floating: false, elevation: 0,
                backgroundColor: isDesktop ? Colors.transparent : Theme.of(context).primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: EdgeInsets.zero, centerTitle: true, expandedTitleScale: 1,
                  title: CustomizableSpaceBarWidget(builder: (context, scrollingRate)=> Center(child: Container(
                    width: Dimensions.webScreenWidth,
                    color: Theme.of(context).primaryColor,
                    padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                    child: Opacity(
                      opacity: (1 - scrollingRate),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [

                          if(scrollingRate < 0.01)
                            Expanded(child: GestureDetector(
                              onTap: () => ResponsiveHelper.showDialogOrBottomSheet(context, SelectedAddressListWidget(
                                currentBranch: branchProvider.getBranch(),
                                isFromAppbar: true,
                              )),
                              child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
                                Container(
                                  width: 34, height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: Dimensions.paddingSizeSmall),

                                Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                                  Text(getTranslated('current_location', context)!, style: rubikRegular.copyWith(
                                    color: Colors.white.withValues(alpha: 0.7), fontSize: 10, letterSpacing: 0.4,
                                  )),
                                  const SizedBox(height: 1),
                                  Row(mainAxisSize: MainAxisSize.min, children: [
                                    Flexible(child: Consumer<LocationProvider>(builder: (context, locationProvider, _) => Text(
                                      _getDisplayLocationText(locationProvider.currentAddress?.address, context),
                                      style: rubikSemiBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ))),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.expand_more_rounded, color: Colors.white, size: 16),
                                  ]),
                                ])),
                              ]),
                            )),

                          if(scrollingRate < 0.01)
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                                ),
                                child: const BranchButtonWidget(isRow: true, color: Colors.white),
                              ),

                              ResponsiveHelper.isTab(context) ? InkWell(
                                onTap: () => RouterHelper.getDashboardRoute('cart'),
                                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
                                  CountIconView(
                                    count: Provider.of<CartProvider>(context).cartList.length.toString(),
                                    icon: Icons.shopping_cart_outlined,
                                    color: ColorResources.white,
                                  ),
                                  const SizedBox(height: 3),

                                  Text(
                                    getTranslated('cart', context)!,
                                    style:  rubikRegular.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                ]),
                              ) : const SizedBox(),
                            ]),
                        ]),
                      ),
                    ),
                  ))),
                ),
              ),

              /// Search Button
              if(!isDesktop) SliverPersistentHeader(pinned: true, delegate: SliverDelegateWidget(
                child: Center(child: Stack(children: [
                  Container(
                    transform: Matrix4.translationValues(0, -2, 0),
                    height: 60, width: Dimensions.webScreenWidth,
                    color: Colors.transparent,
                    child: Column(children: [
                      Expanded(child: Container(color: Theme.of(context).primaryColor)),

                      Expanded(child: Container(color: Colors.transparent)),
                    ]),
                  ),

                  Positioned(
                    left: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall,
                    top: Dimensions.paddingSizeExtraSmall, bottom: Dimensions.paddingSizeExtraSmall,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => RouterHelper.getSearchRoute(),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                        height: 50, width: Dimensions.webScreenWidth,
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(
                            color: Theme.of(context).shadowColor.withValues(alpha: 0.18),
                            blurRadius: 20, offset: const Offset(0, 8),
                          )],
                        ),
                        child: Row(children: [
                          CustomAssetImageWidget(
                            Images.search, color: Theme.of(context).hintColor,
                            height: Dimensions.paddingSizeDefault,
                          ),
                          const SizedBox(width: Dimensions.paddingSizeSmall),

                          Expanded(child: Text(getTranslated('are_you_hungry', context)!, style: rubikRegular.copyWith(
                            color: Theme.of(context).hintColor,
                          ))),
                        ]),
                      ),
                    ),
                  ),
                ])),
              )),

              /// for Web banner and category
              if(isDesktop)  SliverToBoxAdapter(child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeDefault),
                  child: SizedBox(width: Dimensions.webScreenWidth, child: Consumer<BannerProvider>(
                    builder: (context, bannerProvider, _) {
                      return Consumer<CategoryProvider>(
                        builder: (context, categoryProvider, _) {
                          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

                            if (!(bannerProvider.bannerList?.isEmpty ?? false))
                              const SizedBox(child: BannerWidget()),

                            const SizedBox(height: Dimensions.paddingSizeDefault),

                            if (categoryProvider.categoryList?.isNotEmpty ?? true)
                              const CategoryWebWidget(),

                          ]);
                        },
                      );
                    },
                  )),
                ),
              )),

              /// for App banner and category
              if(!isDesktop) SliverToBoxAdapter(child: Column(children: [
                const BannerWidget(),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                Container(
                  decoration: BoxDecoration(color: ColorResources.getTertiaryColor(context)),
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                  child: const CategoryWebWidget(),
                ),
              ])),

              /// for Local eats
              SliverToBoxAdapter(child: Consumer<ProductProvider>(
                  builder: (context, productProvider, _) {
                    return (productProvider.popularLocalProductModel?.products?.isEmpty ?? false) ? const SizedBox() :  HomeLocalEatsWidget(controller: _localEatsScrollController);
                  }
              )),

              /// for Set menu
              SliverToBoxAdapter(child: Consumer<ProductProvider>(
                  builder: (context, productProvider,_) {
                    return (productProvider.flavorfulMenuProductMenuModel?.products?.isEmpty ?? false) ? const SizedBox() : HomeSetMenuWidget(controller: _setMenuScrollController);
                  }
              )),

              /*SliverToBoxAdapter(child: Center(child: Container(
                      width: Dimensions.webScreenWidth,
                      color: Theme.of(context).cardColor,
                      // padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                        isDesktop? const SetMenuWebWidget() :  const SetMenuWidget(),
                        const SizedBox(height: Dimensions.paddingSizeDefault),

                      ]),
                    ))),*/

              /// for web Chefs recommendation banner
              if(isDesktop) ...[
                SliverToBoxAdapter(child: Consumer<ProductProvider>(
                    builder: (context, productProvider, _) {
                      return (productProvider.recommendedProductModel?.products?.isEmpty ?? false) ? const SizedBox() : const ChefsRecommendationWidget();
                    }
                )),
                const SliverToBoxAdapter(child: SizedBox(height: Dimensions.paddingSizeLarge)),
              ],

              /// for Branch list
              SliverToBoxAdapter(child: Consumer<BranchProvider>(
                  builder: (context, branchProvider, _) {
                    return (branchProvider.branchValueList?.isEmpty ?? false) ? const SizedBox() : Center(child: SizedBox(
                      width: Dimensions.webScreenWidth,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : Dimensions.paddingSizeSmall),
                        child: BranchListWidget(controller: _branchListScrollController),
                      ),
                    ));
                  }
              )),

              /// for app Chefs recommendation banner
              if(!isDesktop)  SliverToBoxAdapter(child: Consumer<ProductProvider>(
                  builder: (context, productProvider,_) {
                    return (productProvider.recommendedProductModel?.products?.isEmpty ?? false) ? const SizedBox() : const ChefsRecommendationWidget();
                  }
              )),

              if(productProvider.latestProductModel == null || (productProvider.latestProductModel?.products?.isNotEmpty ?? false))
                SliverToBoxAdapter(child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                    width: Dimensions.webMaxWidth,
                    child: TitleWidget(
                      title: getTranslated(isDesktop ? 'latest_item' : 'all_foods', context),
                      trailingIcon: const SortingButtonWidget(),
                      isShowTrailingIcon: true,
                    ),
                  ),
                )),


              const ProductViewWidget(),

              if(ResponsiveHelper.isDesktop(context)) SliverToBoxAdapter(child: loaderWidget),


              if(isDesktop) const SliverToBoxAdapter(child: FooterWidget()),

            ]));
          },
        )),
      ),
    );
  }
  String _getDisplayLocationText(String? address, BuildContext context) {
    const maxLength = 35; // Define the maximum length for the address

    if (address?.isNotEmpty ?? false) {
      // If the address is not empty, truncate it if necessary
      return address!.length > maxLength
          ? '${address.substring(0, maxLength)}...'
          : address;
    } else {
      // If the address is empty, return a fallback text
      return getTranslated('no_location_selected', context)!;
    }
  }

}



