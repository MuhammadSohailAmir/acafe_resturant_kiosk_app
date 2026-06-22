import 'package:flutter/material.dart';
import 'package:acafe_customer/common/enums/product_sort_type_enum.dart';
import 'package:acafe_customer/common/widgets/custom_asset_image_widget.dart';
import 'package:acafe_customer/features/home/enums/product_type_enum.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/utill/dimensions.dart';
import 'package:acafe_customer/utill/images.dart';
import 'package:acafe_customer/utill/styles.dart';

class HomeItemTypeWidget extends StatelessWidget {
  final Function (ProductType productType) onChange;
  const HomeItemTypeWidget({super.key, required this.onChange});


  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ProductType>(
      tooltip: getTranslated('product_type', context),
      padding: const EdgeInsets.all(0),

      onSelected: (ProductType result) {

      },
      itemBuilder: (BuildContext c) => <PopupMenuEntry<ProductType>>[

        PopupMenuItem<ProductType>(
          value: ProductType.local,
          child: _PopUpItem(title: getTranslated('local_eats', context)!, type: ProductSortType.defaultType),
          onTap: ()=> onChange(ProductType.local),
        ),

        PopupMenuItem<ProductType>(
          value: ProductType.local,
          child: _PopUpItem(title: getTranslated('flavorful_set', context)!, type: ProductSortType.defaultType),
          onTap: ()=> onChange(ProductType.flavorful),
        ),

      ],
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        clipBehavior: Clip.hardEdge,
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
          child: CustomAssetImageWidget(
            Images.sortSvg,
            width: Dimensions.paddingSizeDefault,
            height: Dimensions.paddingSizeDefault,
            color: Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }
}

class _PopUpItem extends StatelessWidget {
  final String title;
  final ProductSortType type;
  const _PopUpItem({
    required this.title, required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
            child: Text(title, style: rubikSemiBold),
          ),
        ],
      ),
    );
  }
}
