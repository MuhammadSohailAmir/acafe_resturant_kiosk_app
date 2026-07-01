import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:acafe_customer/common/models/product_model.dart';
import 'package:acafe_customer/common/widgets/custom_image_widget.dart';
import 'package:acafe_customer/features/category/providers/category_provider.dart';
import 'package:acafe_customer/features/splash/providers/splash_provider.dart';

/// Warms Flutter's image cache for kiosk menu product/category images.
class KioskMenuImageHelper {
  static void precacheFromProvider(
    BuildContext context,
    CategoryProvider categories,
    SplashProvider splash,
  ) {
    final String? productBase = splash.baseUrls?.productImageUrl;
    final String? categoryBase = splash.baseUrls?.categoryImageUrl;
    if (productBase == null) return;

    for (final product in categories.allPrefetchedProducts) {
      _precache(context, '$productBase/${product.image}');
    }

    if (categoryBase != null) {
      for (final category in categories.categoryList ?? []) {
        if ((category.image ?? '').isNotEmpty) {
          _precache(context, '$categoryBase/${category.image}');
        }
      }
    }
  }

  static void precacheProducts(
    BuildContext context,
    SplashProvider splash,
    List<Product> products,
  ) {
    final String? base = splash.baseUrls?.productImageUrl;
    if (base == null) return;
    for (final product in products) {
      _precache(context, '$base/${product.image}');
    }
  }

  static void _precache(BuildContext context, String rawUrl) {
    final url = CustomImageWidget.resolveWebImageUrl(rawUrl);
    if (url.isEmpty) return;
    precacheImage(CachedNetworkImageProvider(url), context).catchError((_) {});
  }
}
