import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:acafe_kiosk/utill/app_constants.dart';
import 'package:acafe_kiosk/utill/images.dart';

class CustomImageWidget extends StatelessWidget {
  final String image;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final bool isNotification;
  final String placeholder;

  static const Map<String, String> webImageHeaders = {
    'ngrok-skip-browser-warning': 'true',
  };

  const CustomImageWidget({
    super.key,
    required this.image,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.isNotification = false,
    this.placeholder = '',
  });

  static bool isDefaultImage(String image) {
    if (image.isEmpty) return true;
    final path = Uri.tryParse(image)?.path ?? image;
    return path.endsWith('/def.png') || path.endsWith('def.png');
  }

  static String normalizeStorageUrl(String image) {
    final uri = Uri.tryParse(image);
    if (uri == null || !uri.path.contains('/storage/app/public/')) {
      return image;
    }
    final base = Uri.parse(AppConstants.baseUrl);
    return base.replace(path: uri.path, query: null, fragment: null).toString();
  }

  static String resolveWebImageUrl(String image) {
    if (!kIsWeb || image.isEmpty || isDefaultImage(image)) return image;
    final normalized = normalizeStorageUrl(image);
    return '${AppConstants.baseUrl}/image-proxy?url=${Uri.encodeComponent(normalized)}';
  }

  @override
  Widget build(BuildContext context) {
    final placeholderWidget = Image.asset(
      placeholder.isNotEmpty ? placeholder : Images.placeholderImage,
      height: height, width: width, fit: fit,
    );

    if (image.isEmpty || (kIsWeb && isDefaultImage(image))) {
      return placeholderWidget;
    }

    // Downscale decode to the displayed size (px) to cut memory + decode time.
    // Cache by the raw image URL so volatile query params don't cause misses
    // and the same asset is reused across navigation / app restarts.
    final double dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
    final int? memCacheWidth = width != null && width!.isFinite ? (width! * dpr).round() : null;

    return CachedNetworkImage(
      imageUrl: resolveWebImageUrl(image),
      cacheKey: image,
      height: height,
      width: width,
      fit: fit,
      memCacheWidth: memCacheWidth,
      maxWidthDiskCache: memCacheWidth,
      // Short fade so a cache hit appears almost instantly (no slow pop), and
      // there is no placeholder flash when the widget is rebuilt for a hit.
      fadeInDuration: const Duration(milliseconds: 150),
      fadeOutDuration: const Duration(milliseconds: 50),
      httpHeaders: kIsWeb ? webImageHeaders : null,
      imageRenderMethodForWeb: kIsWeb ? ImageRenderMethodForWeb.HttpGet : ImageRenderMethodForWeb.HtmlImage,
      placeholder: (context, url) => placeholderWidget,
      errorWidget: (context, url, error) => placeholderWidget,
    );
  }
}
