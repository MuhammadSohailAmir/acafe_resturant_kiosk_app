import 'package:acafe_customer/data/datasource/remote/dio/dio_client.dart';
import 'package:acafe_customer/data/datasource/remote/exception/api_error_handler.dart';
import 'package:acafe_customer/common/models/api_response_model.dart';
import 'package:acafe_customer/utill/app_constants.dart';

class SetMenuRepo {
  final DioClient? dioClient;
  SetMenuRepo({required this.dioClient});

  Future<ApiResponseModel> getSetMenuList() async {
    try {
      final response = await dioClient!.get(AppConstants.setMenuUri,
      );
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }
}