import 'dart:convert'as convert;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:acafe_kiosk/common/models/place_order_body.dart';
import 'package:acafe_kiosk/common/models/cart_model.dart';
import 'package:acafe_kiosk/common/models/config_model.dart';
import 'package:acafe_kiosk/features/checkout/domain/enum/delivery_type_enum.dart';
import 'package:acafe_kiosk/features/checkout/providers/checkout_provider.dart';
import 'package:acafe_kiosk/features/checkout/widgets/payment_method_bottom_sheet_widget.dart';
import 'package:acafe_kiosk/helper/checkout_helper.dart';
import 'package:acafe_kiosk/helper/date_converter_helper.dart';
import 'package:acafe_kiosk/helper/responsive_helper.dart';
import 'package:acafe_kiosk/localization/app_localization.dart';
import 'package:acafe_kiosk/localization/language_constrants.dart';
import 'package:acafe_kiosk/features/auth/providers/auth_provider.dart';
import 'package:acafe_kiosk/features/branch/providers/branch_provider.dart';
import 'package:acafe_kiosk/features/coupon/providers/coupon_provider.dart';
import 'package:acafe_kiosk/features/order/providers/order_provider.dart';
import 'package:acafe_kiosk/features/profile/providers/profile_provider.dart';
import 'package:acafe_kiosk/features/splash/providers/splash_provider.dart';
import 'package:acafe_kiosk/utill/app_constants.dart';
import 'package:acafe_kiosk/utill/dimensions.dart';
import 'package:acafe_kiosk/features/payment/payment_router.dart';
import 'package:acafe_kiosk/helper/router_helper.dart';
import 'package:acafe_kiosk/common/widgets/custom_button_widget.dart';
import 'package:acafe_kiosk/helper/custom_snackbar_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;

class ConfirmButtonWidget extends StatelessWidget {
  final bool isCutlery;
  final double orderAmount;
  final List<CartModel?> cartList;
  final OrderType orderType;
  final String? couponCode;
  final TextEditingController noteController;
  final Function callBack;

  const ConfirmButtonWidget({
    super.key,
    required this.cartList, required this.orderAmount, required this.orderType,
    this.couponCode, required this.noteController,
    required this.callBack, required this.isCutlery,
  });

  @override
  Widget build(BuildContext context) {
    final BranchProvider branchProvider = Provider.of<BranchProvider>(context, listen: false);

    return Consumer<CheckoutProvider>(builder: (context, checkoutProvider, _) {
      return SafeArea(child: Container(
        width: Dimensions.webScreenWidth,
        alignment: Alignment.center,
        child: Consumer<OrderProvider>(
          builder: (context, orderProvider, _) => CustomButtonWidget(
            isLoading: orderProvider.isLoading,
            btnTxt: getTranslated('place_order', context),
            onTap: () async {
              final AuthProvider authProvider = Provider.of<AuthProvider>(context, listen: false);
              final ConfigModel configModel = Provider.of<SplashProvider>(context, listen: false).configModel!;
              final ProfileProvider profileProvider = Provider.of<ProfileProvider>(context, listen: false);

              if(checkoutProvider.selectedPaymentMethod != null || checkoutProvider.selectedOfflineValue != null){
                bool isAvailable = true;
                DateTime scheduleStartDate = DateTime.now();
                DateTime scheduleEndDate = DateTime.now();

                if(checkoutProvider.timeSlots == null || checkoutProvider.timeSlots!.isEmpty) {
                  isAvailable = false;

                }else {
                  DateTime date = checkoutProvider.selectDateSlot == 0 ? DateTime.now() : DateTime.now().add(const Duration(days: 1));
                  DateTime startTime = checkoutProvider.timeSlots![checkoutProvider.selectTimeSlot].startTime!;
                  DateTime endTime = checkoutProvider.timeSlots![checkoutProvider.selectTimeSlot].endTime!;
                  scheduleStartDate = DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute+1);
                  scheduleEndDate = DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute+1);
                  for (CartModel? cart in cartList) {
                    if (!DateConverterHelper.isAvailable(cart!.product!.availableTimeStarts!, cart.product!.availableTimeEnds!, time: scheduleStartDate,)
                        && !DateConverterHelper.isAvailable(cart.product!.availableTimeStarts!, cart.product!.availableTimeEnds!, time: scheduleEndDate)
                    ) {
                      isAvailable = false;
                      break;
                    }
                  }
                }

                if(orderAmount < configModel.minimumOrderValue!) {
                  showCustomSnackBarHelper('Minimum order amount is ${configModel.minimumOrderValue}');
                }else if(checkoutProvider.partialAmount != null && (checkoutProvider.selectedPaymentMethod == null ? (checkoutProvider.selectedOfflineValue == null) : checkoutProvider.selectedPaymentMethod == null )){
                  ResponsiveHelper.showDialogOrBottomSheet(context, PaymentMethodBottomSheetWidget(totalPrice: orderAmount));

                }else if (checkoutProvider.timeSlots == null || checkoutProvider.timeSlots!.isEmpty) {
                  showCustomSnackBarHelper(getTranslated('select_a_time', context));
                }else if (!isAvailable) {
                  showCustomSnackBarHelper(getTranslated('one_or_more_products_are_not_available_for_this_selected_time', context));
                }else {
                  List<Cart> carts = [];
                  for (int index = 0; index < cartList.length; index++) {
                    CartModel cart = cartList[index]!;
                    List<int?> addOnIdList = [];
                    List<int?> addOnQtyList = [];
                    List<OrderVariation> variations = [];

                    for (var addOn in cart.addOnIds!) {
                      addOnIdList.add(addOn.id);
                      addOnQtyList.add(addOn.quantity);
                    }

                    if(cart.product!.variations != null && cart.variations != null && cart.variations!.isNotEmpty){
                      for(int i=0; i<cart.product!.variations!.length; i++) {
                        if(  cart.variations![i].contains(true)) {
                          variations.add(OrderVariation(
                            name: cart.product!.variations![i].name,
                            values: OrderVariationValue(label: []),
                          ));

                          for(int j=0; j<cart.product!.variations![i].variationValues!.length; j++) {
                            if(cart.variations![i][j]!) {
                              variations[variations.length-1].values!.label!.add(cart.product!.variations![i].variationValues![j].level);
                            }
                          }
                        }
                      }
                    }


                    carts.add(Cart(
                      cart.product!.id.toString(), cart.discountedPrice.toString(), [], variations,
                      cart.discountAmount, cart.quantity, cart.taxAmount, addOnIdList, addOnQtyList,
                    ));
                  }



                  PlaceOrderBody placeOrderBody = PlaceOrderBody(
                      cart: carts, couponDiscountAmount: Provider.of<CouponProvider>(context, listen: false).discount,
                      couponDiscountTitle: couponCode,
                      deliveryAddressId: 0,
                      deliveryAddress: null,
                      orderAmount: double.parse(orderAmount.toStringAsFixed(2)),
                      orderNote: noteController.text,
                      orderType: orderType.name.camelCaseToSnakeCase(),
                      paymentMethod: checkoutProvider.selectedOfflineValue != null
                          ? 'offline_payment' : checkoutProvider.selectedPaymentMethod!.getWay!,
                      couponCode: couponCode,
                      distance: 0,
                      branchId: branchProvider.getBranch()?.id,
                      deliveryDate: DateFormat('yyyy-MM-dd').format(scheduleStartDate),
                      paymentInfo: checkoutProvider.selectedOfflineValue != null ?  OfflinePaymentInfo(
                        methodFields: CheckOutHelper.getOfflineMethodJson(checkoutProvider.selectedOfflineMethod?.methodFields),
                        methodInformation: checkoutProvider.selectedOfflineValue,
                        paymentName: checkoutProvider.selectedOfflineMethod?.methodName,
                        paymentNote: checkoutProvider.selectedOfflineMethod?.paymentNote,
                      ) : null,
                      deliveryTime: (checkoutProvider.selectTimeSlot == 0 && checkoutProvider.selectDateSlot == 0) ? 'now' : DateFormat('HH:mm').format(scheduleStartDate),
                      isPartial: checkoutProvider.partialAmount == null ? '0' : '1' ,
                      isCutleryRequired: '${isCutlery ? 1 : 0}',
                      selectedDeliveryArea: null,
                      bringChangeAmount: checkoutProvider.bringChangeAmount ?? 0
                  );

                  if(placeOrderBody.paymentMethod == 'wallet_payment'
                      || placeOrderBody.paymentMethod == 'cash_on_delivery'
                      || placeOrderBody.paymentMethod == 'offline_payment') {
                    orderProvider.placeOrder(placeOrderBody, callBack);
                  }
                  else {
                    String? hostname = html.window.location.hostname;
                    String protocol = html.window.location.protocol;
                    String port = html.window.location.port;
                    final String placeOrder =  convert.base64Url.encode(convert.utf8.encode(convert.jsonEncode(placeOrderBody.toJson())));

                    String url = "customer_id=${authProvider.getGuestId() ?? profileProvider.userInfoModel!.id}&&is_guest=${authProvider.getGuestId() != null ? '1' :'0'}"
                        "&&callback=${AppConstants.baseUrl}${PaymentRouter.orderSuccessScreen}&&order_amount=${orderAmount.toStringAsFixed(2)}";

                    String webUrl = "customer_id=${authProvider.getGuestId() ?? profileProvider.userInfoModel!.id}&&is_guest=${authProvider.getGuestId() != null ? '1' :'0'}"
                        "&&callback=$protocol//$hostname${kDebugMode ? ':$port' : ''}${PaymentRouter.orderWebPayment}&&order_amount=${orderAmount.toStringAsFixed(2)}&&status=";


                    String tokenUrl = convert.base64Encode(convert.utf8.encode(ResponsiveHelper.isWeb() ? (webUrl) : url));
                    String selectedUrl = '${AppConstants.baseUrl}/payment-mobile?token=$tokenUrl&&payment_method=${checkoutProvider.selectedPaymentMethod?.getWay}&&payment_platform=${kIsWeb ? 'web' : 'app'}&&is_partial=${checkoutProvider.partialAmount == null ? '0' : '1'}';

                    orderProvider.clearPlaceOrder().then((_) => orderProvider.setPlaceOrder(placeOrder).then((value) {
                     if(context.mounted){
                       if(kIsWeb){
                         html.window.open(selectedUrl,"_self");
                       }else{
                         context.pop();
                         PaymentRouter.getPaymentRoute(selectedUrl, fromCheckout: true);
                       }
                     }
                    }));
                  }
                }
              } else{

                ResponsiveHelper.showDialogOrBottomSheet(context, PaymentMethodBottomSheetWidget(totalPrice: orderAmount));
              }
            },
          ),
        ),
      ));
    });
  }

}