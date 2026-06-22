import 'package:flutter/material.dart';
import 'package:acafe_customer/common/models/api_response_model.dart';
import 'package:acafe_customer/common/models/error_response_model.dart';
import 'package:acafe_customer/localization/app_localization.dart';
import 'package:acafe_customer/main.dart';
import 'package:acafe_customer/features/auth/providers/auth_provider.dart';
import 'package:acafe_customer/helper/router_helper.dart';
import 'package:acafe_customer/helper/custom_snackbar_helper.dart';
import 'package:provider/provider.dart';

class ApiCheckerHelper {
  static void checkApi(ApiResponseModel apiResponse,{bool firebaseResponse = false} ) {
    ErrorResponseModel error = getError(apiResponse);

    Future.delayed(const Duration(milliseconds: 0)).then((value) {
      if( error.errors![0].code == '401' || error.errors![0].code == 'auth-001'
          &&  ModalRoute.of(Get.context!)?.settings.name != RouterHelper.loginScreen) {
        Provider.of<AuthProvider>(Get.context!, listen: false).clearSharedData(Get.context!).then((value) {
          if(Get.context != null && ModalRoute.of(Get.context!)?.settings.name != RouterHelper.loginScreen) {
            RouterHelper.getLoginRoute(action: RouteAction.pushNamedAndRemoveUntil);
          }
        });

      }else {
        showCustomSnackBarHelper(firebaseResponse ? error.errors?.first.message?.replaceAll('_', ' ').toCapitalized() : error.errors!.first.message);
      }
    });


  }

  static ErrorResponseModel getError(ApiResponseModel apiResponse){
    ErrorResponseModel error;

    try{
      error = ErrorResponseModel.fromJson(apiResponse);
    }catch(e){
      if(apiResponse.error is String){
        error = ErrorResponseModel(errors: [Errors(code: '', message: apiResponse.error.toString())]);

      }else{
        error = ErrorResponseModel.fromJson(apiResponse.error);
      }
    }
    return error;
  }
}