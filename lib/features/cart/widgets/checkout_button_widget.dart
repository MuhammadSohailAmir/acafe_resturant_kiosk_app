import 'package:flutter/material.dart';
import 'package:acafe_customer/common/widgets/custom_button_widget.dart';
import 'package:acafe_customer/features/auth/providers/auth_provider.dart';
import 'package:acafe_customer/features/cart/widgets/guest_checkout_widget.dart';
import 'package:acafe_customer/features/checkout/providers/checkout_provider.dart';
import 'package:acafe_customer/features/coupon/providers/coupon_provider.dart';
import 'package:acafe_customer/features/splash/providers/splash_provider.dart';
import 'package:acafe_customer/helper/custom_snackbar_helper.dart';
import 'package:acafe_customer/helper/price_converter_helper.dart';
import 'package:acafe_customer/helper/responsive_helper.dart';
import 'package:acafe_customer/helper/router_helper.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/utill/dimensions.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CheckOutButtonWidget extends StatelessWidget {
  const CheckOutButtonWidget({
    super.key,
    required this.orderAmount,
    required this.totalWithoutDeliveryFee,
  });

  final double orderAmount;
  final double totalWithoutDeliveryFee;

  @override
  Widget build(BuildContext context) {
    final splashProvider = Provider.of<SplashProvider>(context, listen: false);
    final AuthProvider authProvider = Provider.of<AuthProvider>(context, listen: false);
    final CouponProvider couponProvider = Provider.of<CouponProvider>(context, listen: false);
    final CheckoutProvider checkoutProvider = Provider.of<CheckoutProvider>(context, listen: false);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Dimensions.radiusDefault),
          topRight: Radius.circular(Dimensions.radiusDefault),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor,
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        width: Dimensions.webScreenWidth,
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        child: CustomButtonWidget(btnTxt: getTranslated('proceed_to_checkout', context), onTap: () {
          if(authProvider.isLoggedIn()){
            if(orderAmount < (splashProvider.configModel?.minimumOrderValue ?? 0)) {
              showCustomSnackBarHelper('${getTranslated('minimum_order_is', context)} ${PriceConverterHelper.convertPrice(splashProvider.configModel!
                  .minimumOrderValue)}, ${getTranslated('you_have', context)} ${PriceConverterHelper.convertPrice(orderAmount)} ${getTranslated('in_your_cart_please_add_more', context)}');
            } else {
              RouterHelper.getCheckoutRoute(
                totalWithoutDeliveryFee, 'cart',
                couponProvider.code, checkoutProvider.isCutlerySelected,
              );
            }
          } else{
            ResponsiveHelper.showDialogOrBottomSheet(context, GuestCheckoutWidget(onGuestTap: () {
              if(orderAmount < splashProvider.configModel!.minimumOrderValue!) {
                showCustomSnackBarHelper('${getTranslated('minimum_order_is', context)} ${PriceConverterHelper.convertPrice(splashProvider.configModel!
                    .minimumOrderValue)}, ${getTranslated('you_have', context)} ${PriceConverterHelper.convertPrice(orderAmount)} ${getTranslated('in_your_cart_please_add_more', context)}');
              } else {
                context.pop();
                RouterHelper.getCheckoutRoute(
                  totalWithoutDeliveryFee, 'cart',
                  couponProvider.code,
                  checkoutProvider.isCutlerySelected,
                );
              }
            }));
          }
        }),
      ),
    );
  }
}