// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:acafe_kiosk/common/widgets/custom_asset_image_widget.dart';
import 'package:acafe_kiosk/features/splash/providers/splash_provider.dart';
import 'package:acafe_kiosk/helper/responsive_helper.dart';
import 'package:acafe_kiosk/localization/language_constrants.dart';
import 'package:acafe_kiosk/common/providers/product_provider.dart';
import 'package:acafe_kiosk/utill/dimensions.dart';
import 'package:acafe_kiosk/utill/images.dart';
import 'package:acafe_kiosk/utill/styles.dart';
import 'package:provider/provider.dart';


class FoodFilterButtonWidget extends StatelessWidget {
  final String type;
  final List<String> items;
  final bool isBorder;
  final bool isSmall;
  final Function(String value) onSelected;

  const FoodFilterButtonWidget({super.key,
    required this.type, required this.onSelected, required this.items,  this.isBorder = false, this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    /* ORIGINAL Veg / Non-Veg filter — commented for café (uncomment block + remove SizedBox below to restore)
    bool isVegFilter = Provider.of<ProductProvider>(context, listen: false).productTypeList == items;

    return  Consumer<SplashProvider>(
      builder: (c, splashProvider, _) {
        return Visibility(
          visible: splashProvider.configModel!.isVegNonVegActive!,
          child: Align(alignment: Alignment.center, child: SizedBox(height: ResponsiveHelper.isMobile() ? 35 : 40, child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(
                  color: items[index] == type ? Theme.of(context).cardColor : Theme.of(context).hintColor.withValues(alpha:0.1),
                  borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusSmall)),
                  border: items[index] == type ?  Border.all(color: Theme.of(context).primaryColor.withValues(alpha:0.4)) : null,
                ),
                child: InkWell(
                  onTap: () => onSelected(items[index]),
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  child: Row(children: [

                    items[index] != items[0] && isVegFilter ? Padding(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                      child: CustomAssetImageWidget(Images.getImageUrl(items[index])),
                    ) : const SizedBox(),

                    if(index == 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                        child: Text(getTranslated(items[index], context)!, style: rubikRegular),
                      ),

                  ]),
                ),
              );
            },
          ))),
        );
      }
    ); */

    // Hidden while veg/non-veg is disabled for café
    return const SizedBox.shrink();
  }
}
