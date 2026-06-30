import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:acafe_customer/common/models/cart_model.dart';
import 'package:acafe_customer/features/branch/providers/branch_provider.dart';
import 'package:acafe_customer/main.dart';
import 'package:acafe_customer/utill/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartRepo{
  final SharedPreferences? sharedPreferences;
  CartRepo({required this.sharedPreferences});

  String  _getCartDataKey(BuildContext context){
    return  '${AppConstants.cartList}_${Provider.of<BranchProvider>(context, listen: false).getBranchId()}';
  }

  List<CartModel> getCartList(BuildContext context) {
    List<String>? carts = [];
    if(sharedPreferences!.containsKey(_getCartDataKey(context))) {
      carts = sharedPreferences!.getStringList(_getCartDataKey(context));
    }
    List<CartModel> cartList = [];
    for (var cart in carts!) {
      cartList.add(CartModel.fromJson(jsonDecode(cart)));
    }

    return cartList;
  }

  void addToCartList(List<CartModel?> cartProductList) {
    List<String> carts = [];
    for (var cartModel in cartProductList) {
      carts.add(jsonEncode(cartModel));
    }
    sharedPreferences!.setStringList(_getCartDataKey(Get.context!), carts);
  }

}