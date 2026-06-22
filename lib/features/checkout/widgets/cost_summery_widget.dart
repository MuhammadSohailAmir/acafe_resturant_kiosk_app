import 'package:flutter/material.dart';
import 'package:acafe_customer/features/cart/widgets/item_view_widget.dart';
import 'package:acafe_customer/helper/price_converter_helper.dart';
import 'package:acafe_customer/helper/responsive_helper.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/utill/dimensions.dart';
import 'package:acafe_customer/utill/styles.dart';

class CostSummeryWidget extends StatelessWidget {
  final double? subtotal;
  const CostSummeryWidget({super.key, this.subtotal});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Align(alignment: Alignment.center,
            child: Text(getTranslated('cost_summery', context)!, style: rubikBold.copyWith(
              fontSize: isDesktop ? Dimensions.fontSizeExtraLarge : Dimensions.fontSizeDefault,
              fontWeight: isDesktop ? FontWeight.w700 : FontWeight.w600,
            )),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          const Divider(thickness: 0.08, color: Colors.black),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          ItemViewWidget(
            title: getTranslated('subtotal', context)!,
            subTitle: PriceConverterHelper.convertPrice(subtotal),
            titleStyle: rubikSemiBold,
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          const Divider(thickness: 0.08, color: Colors.black),

          if(isDesktop) ItemViewWidget(
            title: getTranslated('total_amount', context)!,
            subTitle: PriceConverterHelper.convertPrice(subtotal),
            titleStyle: rubikSemiBold,
            subTitleStyle: rubikBold,
          ),
        ]),
      ),
    ]);
  }
}