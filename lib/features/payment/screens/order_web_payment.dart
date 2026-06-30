import 'dart:convert';
import 'package:acafe_kiosk/main.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:acafe_kiosk/common/models/place_order_body.dart';
import 'package:acafe_kiosk/features/cart/providers/cart_provider.dart';
import 'package:acafe_kiosk/features/order/providers/order_provider.dart';
import 'package:acafe_kiosk/features/payment/payment_router.dart';
import 'package:acafe_kiosk/helper/router_helper.dart';
import 'package:acafe_kiosk/helper/custom_snackbar_helper.dart';
import 'package:provider/provider.dart';

class OrderWebPayment extends StatefulWidget {
  final String? token;
  const OrderWebPayment({super.key, this.token});

  @override
  State<OrderWebPayment> createState() => _OrderWebPaymentState();
}

class _OrderWebPaymentState extends State<OrderWebPayment> {

  getValue() async {
    if(html.window.location.href.contains('success')){
      final orderProvider =  Provider.of<OrderProvider>(Get.context!, listen: false);
      String placeOrderString =  utf8.decode(base64Url.decode('${orderProvider.getPlaceOrder()?.replaceAll(' ', '+')}'));
      if(widget.token != null){
        String tokenString = utf8.decode(base64Url.decode('${widget.token?.replaceAll(' ', '+')}'));
        String paymentMethod = tokenString.substring(0, tokenString.indexOf('&&'));
        String transactionReference = tokenString.substring(tokenString.indexOf('&&') + '&&'.length, tokenString.length);

        PlaceOrderBody placeOrderBody =  PlaceOrderBody.fromJson(jsonDecode(placeOrderString)).copyWith(
          paymentMethod: paymentMethod.replaceAll('payment_method=', ''),
          transactionReference:  transactionReference.replaceRange(0, transactionReference.indexOf('transaction_reference='), '').replaceAll('transaction_reference=', ''),
        );
        orderProvider.placeOrder(placeOrderBody, _callback, isUpdate: false);
      }


    }else{
      Future.delayed(const Duration(milliseconds: 500)).then((value) => PaymentRouter.getOrderSuccessScreen('-1', 'payment-fail'));
    }
  }

  void _callback(bool isSuccess, String message, String orderID) async {
    Provider.of<CartProvider>(context, listen: false).clearCartList();
    Provider.of<OrderProvider>(context, listen: false).clearPlaceOrder();
    Provider.of<OrderProvider>(context, listen: false).stopLoader();
    if(isSuccess) {
      PaymentRouter.getOrderSuccessScreen(orderID, 'success');
    }else {
      showCustomSnackBarHelper(message);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getValue();
  }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
