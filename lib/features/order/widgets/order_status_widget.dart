import 'package:flutter/material.dart';
import 'package:acafe_customer/common/widgets/custom_asset_image_widget.dart';
import 'package:acafe_customer/features/order/domain/models/order_model.dart';
import 'package:acafe_customer/features/order/enum/order_status_enum.dart';
import 'package:acafe_customer/helper/date_converter_helper.dart';
import 'package:acafe_customer/helper/responsive_helper.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/utill/dimensions.dart';
import 'package:acafe_customer/utill/images.dart';
import 'package:acafe_customer/utill/styles.dart';
import 'package:provider/provider.dart';

class OrderStatusWidget extends StatelessWidget {
  final Order? orderModel;
  const OrderStatusWidget({super.key, required this.orderModel});

  @override
  Widget build(BuildContext context) {

    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    return Column(mainAxisSize: MainAxisSize.min, children: [

      if(isDesktop) ...[
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha:0.07),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            // boxShadow: [BoxShadow(color: Theme.of(context).shadowColor, blurRadius: Dimensions.radiusSmall, spreadRadius: 1)],
          ),
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
          child:  Column(mainAxisAlignment: MainAxisAlignment.center, children: [
             Center(child: CustomAssetImageWidget( _getOrderStatusImage(), width: 110, height: 110)),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            _StatusWidget(orderModel: orderModel),
            
          ]),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
      ],

      if(!isDesktop) ...[
        Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          color: Theme.of(context).primaryColor.withValues(alpha:0.07),
          child: Center(child: CustomAssetImageWidget(_getOrderStatusImage(), width: 120)),
        ),

        Container(
          transform: Matrix4.translationValues(0, -25, 0),
          height: 80,
          margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusDefault)),
            boxShadow: [BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha:0.5),
              blurRadius: Dimensions.radiusDefault, spreadRadius: 1,
              offset: const Offset(2, 2),
            )],
          ),
          child: _StatusWidget(orderModel: orderModel),
        ),
      ],

    ]);
  }

  String _getOrderStatusImage() {
    String? image;
    if(orderModel?.orderStatus == 'new') {
      image = Images.pendingAnimation;
    } else if(orderModel?.orderStatus == 'preparing') {
      image = Images.processingAnimation;
    } else if(orderModel?.orderStatus == 'item_to_collect') {
      image = Images.confirmedDeliveryAnimation;
    } else if(orderModel?.orderStatus == 'on_hold') {
      image = Images.processingAnimation;
    } else if(orderModel?.orderStatus == OrderStatus.canceled.apiValue) {
      image = Images.canceledDeliveryAnimation;
    }
    return image ?? "";
  }
}

class _StatusWidget extends StatelessWidget {
  const _StatusWidget({
    required this.orderModel,
  });
  final Order? orderModel;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      if(isDesktop) const Expanded(child: SizedBox()),

      Expanded(flex: 8, child: Column(crossAxisAlignment: isDesktop ? CrossAxisAlignment.center : CrossAxisAlignment.start, children: [
        Text(
          '${getTranslated('your_order_is', context)!} ${getTranslated(orderModel?.orderStatus, context)}',
          style: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        const SizedBox(),

      ])),
      const SizedBox(width: Dimensions.paddingSizeDefault),

    ]);
  }
}

