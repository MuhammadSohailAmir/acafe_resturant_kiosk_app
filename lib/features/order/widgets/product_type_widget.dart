// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/features/splash/providers/splash_provider.dart';
import 'package:acafe_customer/utill/dimensions.dart';
import 'package:acafe_customer/utill/styles.dart';
import 'package:provider/provider.dart';

class ProductTypeWidget extends StatelessWidget {
  final String? productType;
  const ProductTypeWidget({super.key, this.productType});

  @override
  Widget build(BuildContext context) {
    /* ORIGINAL Veg / Non-Veg tag — commented for café (uncomment block + remove SizedBox below to restore)
    final bool isVegNonVegActive = Provider.of<SplashProvider>(context, listen: false).configModel!.isVegNonVegActive!;
    return productType == null ||  !isVegNonVegActive ? const SizedBox() : Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusSmall)),
        color: Theme.of(context).primaryColor,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0 ,vertical: 2),
        child: Text(getTranslated(productType, context,
        )!, style: robotoRegular.copyWith(color: Colors.white),
        ),
      ),
    ); */

    // Hidden while veg/non-veg is disabled for café
    return const SizedBox.shrink();
  }
}
