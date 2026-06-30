import 'package:flutter/material.dart';
import 'package:acafe_kiosk/common/models/product_model.dart';
import 'package:acafe_kiosk/common/widgets/custom_asset_image_widget.dart';
import 'package:acafe_kiosk/features/home/enums/product_group_enum.dart';
import 'package:acafe_kiosk/helper/product_helper.dart';
import 'package:acafe_kiosk/localization/language_constrants.dart';
import 'package:acafe_kiosk/common/providers/product_provider.dart';
import 'package:acafe_kiosk/utill/dimensions.dart';
import 'package:acafe_kiosk/utill/images.dart';
import 'package:acafe_kiosk/utill/styles.dart';
import 'package:provider/provider.dart';

class StockTagWidget extends StatelessWidget {
  final ProductGroup productGroup;
  final Product product;
  const StockTagWidget({
    super.key, required this.product, this.productGroup = ProductGroup.common,
  });

  @override
  Widget build(BuildContext context) {
    final ProductProvider productProvider = Provider.of<ProductProvider>(context, listen: false);
    bool isAvailable = ProductHelper.isProductAvailable(product: product);

    return !productProvider.checkStock(product) || !isAvailable ? Positioned.fill(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      width: double.maxFinite,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha:0.3),
      ),
      child: Center(child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha:0.5),
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const CustomAssetImageWidget(Images.clockSvg, color: Colors.white, width: 14, height: 14),

          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Flexible(child: Text(
            getTranslated(!isAvailable ? 'not_available' : 'stock_out', context)!, textAlign: TextAlign.center,
            style: robotoRegular.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeExtraSmall),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          )),
        ]),
      )),
    )) : const SizedBox();
  }
}
