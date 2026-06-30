import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:acafe_customer/common/models/cart_model.dart';
import 'package:acafe_customer/common/models/product_model.dart';
import 'package:acafe_customer/common/widgets/custom_image_widget.dart';
import 'package:acafe_customer/features/category/domain/category_model.dart';
import 'package:acafe_customer/features/category/providers/category_provider.dart';
import 'package:acafe_customer/features/home/providers/banner_provider.dart';
import 'package:acafe_customer/features/home/widgets/cart_bottom_sheet_widget.dart';
import 'package:acafe_customer/features/splash/providers/splash_provider.dart';
import 'package:acafe_customer/helper/custom_snackbar_helper.dart';
import 'package:acafe_customer/helper/responsive_helper.dart';
import 'package:acafe_customer/helper/router_helper.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/utill/images.dart';
import 'package:provider/provider.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class BannerWidget extends StatefulWidget {
  const BannerWidget({super.key});

  @override
  State<BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<BannerWidget> {
  final CarouselSliderController _controller = CarouselSliderController();
  int _currentIndex = 0;

  void _onTap(BuildContext context, BannerProvider bannerProvider, int index) {
    if (bannerProvider.bannerList![index].productId != null) {
      Product? product;
      for (final prod in bannerProvider.productList) {
        if (prod.id == bannerProvider.bannerList![index].productId) {
          product = prod;
          break;
        }
      }
      if (product != null && (product.branchProduct?.isAvailable ?? false)) {
        ResponsiveHelper.showDialogOrBottomSheet(
          context,
          CartBottomSheetWidget(
            product: product,
            fromSetMenu: true,
            callback: (CartModel cartModel) {
              showCustomSnackBarHelper(
                getTranslated('added_to_cart', context),
                isError: false,
              );
            },
          ),
        );
      }
    } else if (bannerProvider.bannerList![index].categoryId != null) {
      CategoryModel? category;
      for (final cat in Provider.of<CategoryProvider>(context, listen: false).categoryList!) {
        if (cat.id == bannerProvider.bannerList![index].categoryId) {
          category = cat;
          break;
        }
      }
      if (category != null && category.status == 1) {
        RouterHelper.getCategoryRoute(category);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final splashProvider = Provider.of<SplashProvider>(context, listen: false);
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    final double height = isDesktop ? 260 : 180;

    return Consumer<BannerProvider>(
      builder: (context, bannerProvider, _) {
        if (bannerProvider.bannerList == null) {
          return _BannerShimmer(height: height);
        }
        if (bannerProvider.bannerList?.isEmpty ?? true) {
          return const SizedBox();
        }

        final int count = bannerProvider.bannerList!.length.clamp(0, 10);

        return Column(children: [

          // ── Carousel ──────────────────────────────────────────
          Stack(alignment: Alignment.center, children: [

            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(
                    color: Theme.of(context).shadowColor.withValues(alpha: 0.18),
                    blurRadius: 20, offset: const Offset(0, 8),
                  )],
                ),
                child: CarouselSlider.builder(
                  carouselController: _controller,
                  itemCount: count,
                  options: CarouselOptions(
                    height: height,
                    viewportFraction: 1.0,
                    enableInfiniteScroll: true,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 4),
                    autoPlayAnimationDuration: const Duration(milliseconds: 700),
                    autoPlayCurve: Curves.easeInOutCubic,
                    onPageChanged: (index, _) {
                      if (mounted) setState(() => _currentIndex = index);
                    },
                  ),
                  itemBuilder: (context, index, _) {
                    return GestureDetector(
                      onTap: () => _onTap(context, bannerProvider, index),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(fit: StackFit.expand, children: [
                          CustomImageWidget(
                            image: '${splashProvider.baseUrls!.bannerImageUrl}/${bannerProvider.bannerList![index].image}',
                            placeholder: Images.placeholderBanner,
                            width: double.infinity,
                            height: height,
                            fit: BoxFit.cover,
                          ),

                          // Soft bottom vignette — adds depth without altering banner content
                          IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              stops: const [0.55, 1.0],
                              colors: [
                                Colors.black.withValues(alpha: 0.0),
                                Colors.black.withValues(alpha: 0.22),
                              ],
                            ),
                          ))),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Left arrow
            Positioned(
              left: 10,
              child: _NavArrow(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => _controller.previousPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                ),
              ),
            ),

            // Right arrow
            Positioned(
              right: 10,
              child: _NavArrow(
                icon: Icons.arrow_forward_ios_rounded,
                onTap: () => _controller.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                ),
              ),
            ),

          ]),

          // ── Dots ──────────────────────────────────────────────
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(count, (i) {
              final bool active = i == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 22 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: active
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).primaryColor.withValues(alpha: 0.18),
                  boxShadow: active ? [BoxShadow(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
                    blurRadius: 6, offset: const Offset(0, 2),
                  )] : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 4),

        ]);
      },
    );
  }
}

// ── Navigation arrow ──────────────────────────────────────────
class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

// ── Shimmer placeholder ───────────────────────────────────────
class _BannerShimmer extends StatelessWidget {
  final double height;
  const _BannerShimmer({required this.height});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      duration: const Duration(seconds: 2),
      enabled: true,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).shadowColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}