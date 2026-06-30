// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:acafe_kiosk/common/models/product_model.dart';
import 'package:acafe_kiosk/features/splash/providers/splash_provider.dart';
import 'package:provider/provider.dart';

class ProductTagWidget extends StatelessWidget {
  final Product product;
  const ProductTagWidget({
    super.key, required this.product,
  });

  @override
  Widget build(BuildContext context) {
    /* ORIGINAL Veg / Non-Veg tag — commented for café (uncomment block + remove SizedBox below to restore)
    return Consumer<SplashProvider>(builder: (context, splashProvider, _) {
      return Visibility(
        visible: splashProvider.configModel!.isVegNonVegActive!,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: product.productType == 'veg'
                  ? Theme.of(context).secondaryHeaderColor
                  : Theme.of(context).primaryColor, width: 2,
            ),
          ),
          padding: const EdgeInsets.all(1),
          child: Container(
            height: 8,
            width: 8,
            decoration: BoxDecoration(
              color: product.productType == 'veg'
                  ? Theme.of(context).secondaryHeaderColor
                  : Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }); */

    // Hidden while veg/non-veg is disabled for café
    return const SizedBox.shrink();
  }
}
