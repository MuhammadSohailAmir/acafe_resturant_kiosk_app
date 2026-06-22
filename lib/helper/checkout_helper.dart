import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:acafe_customer/common/models/config_model.dart';
import 'package:acafe_customer/common/models/offline_payment_model.dart';
import 'package:acafe_customer/common/widgets/custom_loader_widget.dart';
import 'package:acafe_customer/features/address/domain/models/address_model.dart';
import 'package:acafe_customer/features/address/providers/location_provider.dart';
import 'package:acafe_customer/features/auth/providers/auth_provider.dart';
import 'package:acafe_customer/features/branch/providers/branch_provider.dart';
import 'package:acafe_customer/features/checkout/domain/enum/delivery_type_enum.dart';
import 'package:acafe_customer/features/checkout/providers/checkout_provider.dart';
import 'package:acafe_customer/features/order/providers/order_provider.dart';
import 'package:acafe_customer/features/profile/domain/models/userinfo_model.dart';
import 'package:acafe_customer/features/profile/providers/profile_provider.dart';
import 'package:acafe_customer/features/splash/providers/splash_provider.dart';
import 'package:acafe_customer/helper/custom_snackbar_helper.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/main.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class CheckOutHelper{
  static bool isWalletPayment({required ConfigModel configModel, required bool isLogin, required double? partialAmount, required bool isPartialPayment}){
    return configModel.walletStatus! && configModel.isPartialPayment! && isLogin && (partialAmount == null) && !isPartialPayment;
  }

  static bool isPartialPayment({required ConfigModel configModel, required bool isLogin, required UserInfoModel? userInfoModel}){
    return isLogin && configModel.isPartialPayment! && configModel.walletStatus! && (userInfoModel != null && userInfoModel.walletBalance! > 0);
  }

  static bool isPartialPaymentSelected({required int? paymentMethodIndex, required PaymentMethod? selectedPaymentMethod}){
    return (paymentMethodIndex == 1 && selectedPaymentMethod != null);
  }

  static List<Map<String, dynamic>> getOfflineMethodJson(List<MethodField>? methodList){
    List<Map<String, dynamic>> mapList = [];
    List<String?> keyList = [];
    List<String?> valueList = [];

    for(MethodField methodField in (methodList ?? [])){
      keyList.add(methodField.fieldName);
      valueList.add(methodField.fieldData);
    }

    for(int i = 0; i < keyList.length; i++) {
      mapList.add({'${keyList[i]}' : '${valueList[i]}'});
    }

    return mapList;
  }

  static AddressModel? getDeliveryAddress({
    required List<AddressModel?>? addressList,
    required AddressModel? selectedAddress,
    required AddressModel? lastOrderAddress,
    OrderType orderType = OrderType.takeAway
  }){
    final BranchProvider branchProvider = Provider.of<BranchProvider>(Get.context!, listen: false);
    final SplashProvider splashProvider = Provider.of<SplashProvider>(Get.context!, listen: false);
    final ProfileProvider profileProvider = Provider.of<ProfileProvider>(Get.context!, listen: false);
    final AuthProvider authProvider = Provider.of<AuthProvider>(Get.context!, listen: false);
    final LocationProvider locationProvider = Provider.of<LocationProvider>(Get.context!, listen: false);

    AddressModel? deliveryAddress;
    if(selectedAddress != null) {
      deliveryAddress = AddressModel.fromJson(selectedAddress.toJson());
      print('------deliveryAddress: ${deliveryAddress.toJson()}');

    }else if(lastOrderAddress != null){
      deliveryAddress = lastOrderAddress;
    }else if(addressList != null && addressList.isNotEmpty){
      deliveryAddress = addressList.first;
    }

    if(deliveryAddress != null && !isAddressInCoverage(branchProvider.getBranch(), deliveryAddress) && orderType != OrderType.takeAway) {
      deliveryAddress = null;
    }

    if(deliveryAddress == null ){
      if(authProvider.isLoggedIn()){
        deliveryAddress = AddressModel(
          contactPersonName: "${profileProvider.userInfoModel?.fName?? ""} ${profileProvider.userInfoModel?.lName ?? ""}",
          contactPersonNumber: profileProvider.userInfoModel?.phone,
          address: locationProvider.currentAddress?.address,
          latitude: locationProvider.currentAddress?.latitude,
          longitude: locationProvider.currentAddress?.longitude,
        );
      }else if (locationProvider.currentAddress != null){
        deliveryAddress = locationProvider.currentAddress;
      }
    }

    return deliveryAddress;
  }


  static bool isKmWiseCharge({dynamic deliveryInfoModel}) => false;



  static Future<void> selectDeliveryAddress({
    required bool isAvailable,
    required AddressModel? address,
    required ConfigModel? configModel,
    required LocationProvider locationProvider,
    required CheckoutProvider checkoutProvider,
    required SplashProvider splashProvider,
    required bool shouldResetPaymentAndShowDeliveryDialog,
    bool enableChargeCalculation = true,
    bool isFreeDelivery = false,
  }) async {
    if (isAvailable) {
      checkoutProvider.setSelectedAddress(address, isUpdate: true);
    } else {
      showCustomSnackBarHelper(getTranslated('out_of_coverage_for_this_branch', Get.context!));
    }
  }

  static double getDeliveryCharge({
    required SplashProvider splashProvider,
    required int googleMapStatus,
    int? areaID,
    required double distance,
    required double shippingPerKm,
    required double minShippingCharge,
    required double defaultDeliveryCharge,
    required double minimumDistanceForFreeDelivery,
    bool isTakeAway = false,
    bool kmWiseCharge = true,
    bool isFreeDelivery = false,
  }) => 0.0;



  static Future<AddressModel?> selectDeliveryAddressAuto({AddressModel ? pickedAddress , AddressModel? lastAddress, required bool isLoggedIn, required OrderType? orderType, bool shouldResetPaymentAndShowDeliveryDialog = false,  bool isFreeDelivery = false}) async {
    final LocationProvider locationProvider = Provider.of<LocationProvider>(Get.context!, listen: false);
    final CheckoutProvider checkoutProvider = Provider.of<CheckoutProvider>(Get.context!, listen: false);
    final SplashProvider splashProvider = Provider.of<SplashProvider>(Get.context!, listen: false);


    AddressModel? deliveryAddress = pickedAddress ?? CheckOutHelper.getDeliveryAddress(
      addressList: locationProvider.addressList,
      selectedAddress: checkoutProvider.selectedAddress,
      lastOrderAddress: lastAddress,
    );


    return deliveryAddress;

  }

  static bool isAddressInCoverage(Branches? currentBranch, AddressModel address ){
    bool isAvailable = currentBranch == null || (currentBranch.latitude == null);
    if(!isAvailable && address.longitude != null && address.latitude != null) {
      double distance = Geolocator.distanceBetween(
        currentBranch.latitude!, currentBranch.longitude!,
        (address.latitude?.isNotEmpty ?? false) ? double.parse(address.latitude ?? '0') : 0,
        (address.longitude?.isNotEmpty ?? false) ? double.parse(address.longitude ?? '0') : 0,
      ) / 1000;

      isAvailable = distance < (currentBranch.coverage ?? 0);
    }

    return isAvailable;
  }

  static double getReferralDiscount({ReferralCustomerDetails? referralDetails, required double totalAmount}) {
    if (referralDetails == null || referralDetails.customerDiscountAmount == null) {
      return 0;
    }

    final discountAmount = referralDetails.customerDiscountAmount!;
    double referralDiscount;

    switch (referralDetails.customerDiscountAmountType?.toLowerCase()) {
      case 'amount':
        referralDiscount = discountAmount;
        break;
      case 'percent':
        referralDiscount = totalAmount * (discountAmount / 100);
        break;
      default:
        referralDiscount = 0;
    }

    return referralDiscount.clamp(0, totalAmount);
  }


  static selectPaymentMethodAutomatically({required List<PaymentMethod> activePaymentMethodList, required bool isCashOnDeliveryActive}) {
    final CheckoutProvider checkoutProvider = Provider.of<CheckoutProvider>(Get.context!, listen: false);

    final PaymentMethod? lastOrderedPaymentMethod = _getPreferredPaymentMethod(activePaymentMethodList);


    if(isCashOnDeliveryActive && lastOrderedPaymentMethod == null) {
      checkoutProvider.savePaymentMethod(index: 1);

    }else {
      if(activePaymentMethodList.isEmpty) return;
      checkoutProvider.savePaymentMethod(method: lastOrderedPaymentMethod ?? activePaymentMethodList.first);
    }

  }

  static PaymentMethod? _getPreferredPaymentMethod(List<PaymentMethod> availableMethods) {
    const excludedMethods = {
      'cash_on_delivery',
      'offline_payment',
      'wallet',
    };

    if(!Provider.of<AuthProvider>(Get.context!, listen: false).isLoggedIn()) {
      return null;
    }

    final String? lastUsedMethod = Provider.of<OrderProvider>(Get.context!, listen: false).getLastOrderPaymentMethod();

    if (lastUsedMethod == null ||
        lastUsedMethod.isEmpty ||
        excludedMethods.contains(lastUsedMethod)) {
      return null;
    }

    return availableMethods.firstWhereOrNull((method) => method.getWay == lastUsedMethod);
  }

}