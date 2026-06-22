import 'package:flutter/material.dart';
import 'package:acafe_customer/features/order/providers/order_provider.dart';
import 'package:acafe_customer/features/order/widgets/item_info_widget.dart';
import 'package:acafe_customer/features/order/widgets/order_status_widget.dart';
import 'package:acafe_customer/features/order/widgets/payment_info_widget.dart';
import 'package:acafe_customer/features/splash/providers/splash_provider.dart';
import 'package:acafe_customer/helper/date_converter_helper.dart';
import 'package:acafe_customer/helper/responsive_helper.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/utill/dimensions.dart';
import 'package:acafe_customer/utill/styles.dart';
import 'package:provider/provider.dart';

class OrderDetailsWidget extends StatelessWidget {
  const OrderDetailsWidget({super.key, this.orderId});
  final int? orderId;

  @override
  Widget build(BuildContext context) {
    final SplashProvider splashProvider = Provider.of<SplashProvider>(context, listen: false);

    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    return Consumer<OrderProvider>(
        builder: (context, order, _) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            if(isDesktop) Container(
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
              margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${getTranslated('order', context)} #$orderId', style: rubikSemiBold.copyWith(
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                )),
                const SizedBox(height: Dimensions.paddingSizeSmall),

               if(order.trackModel?.createdAt != null) Text(DateConverterHelper.formatDate(
                  DateConverterHelper.isoStringToLocalDate(order.trackModel?.createdAt ?? ''), context,
                  isSecond: false,
                ), style: rubikRegular.copyWith(
                  color: Theme.of(context).hintColor,
                  fontSize: Dimensions.fontSizeSmall,
                )),
              ]),
            ),

            OrderStatusWidget(orderModel: order.trackModel),

            if(isDesktop) ...[
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
                margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(getTranslated('item_info', context)!, style: rubikBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  ItemInfoWidget(orderProvider: order, splashProvider: splashProvider),
                ]),
              ),

              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
                margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(getTranslated('payment_info', context)!, style: rubikBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                  PaymentInfoWidget(orderProvider: order),
                ]),
              ),

              if(order.trackModel?.orderNote?.isNotEmpty ?? false)
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
                  margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(getTranslated('order_note', context)!, style: rubikBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                    Text(order.trackModel?.orderNote ?? '', style: rubikRegular.copyWith(color: Theme.of(context).hintColor)),
                  ]),
                ),
            ],

            if(!isDesktop) Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(getTranslated('item_info', context)!, style: rubikBold),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    boxShadow: [BoxShadow(
                      color: Theme.of(context).shadowColor.withValues(alpha:0.5),
                      blurRadius: Dimensions.radiusSmall, spreadRadius: 1, offset: const Offset(2, 2),
                    )],
                  ),
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: ItemInfoWidget(orderProvider: order, splashProvider: splashProvider),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),

                Text(getTranslated('payment_info', context)!, style: rubikBold),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    boxShadow: [
                      BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha:0.5), blurRadius: 5, spreadRadius: 1, offset: const Offset(2, 2)),
                    ],
                  ),
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: PaymentInfoWidget(orderProvider: order),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                if(order.trackModel?.orderNote?.isNotEmpty ?? false) ...[
                  Text(getTranslated('order_note', context)!, style: rubikBold),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      boxShadow: [BoxShadow(
                        color: Theme.of(context).shadowColor.withValues(alpha:0.5), blurRadius: 5, spreadRadius: 1, offset: const Offset(2, 2),
                      )],
                    ),
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: Text(order.trackModel?.orderNote ?? '', style: rubikRegular.copyWith(color: Theme.of(context).hintColor)),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                ],
                const SizedBox(height: Dimensions.paddingSizeSmall),
              ]),
            ),

          ]);
        }
    );
  }
}