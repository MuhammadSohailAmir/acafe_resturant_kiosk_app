import 'package:acafe_kiosk/common/enums/data_source_enum.dart';
import 'package:acafe_kiosk/common/models/api_response_model.dart';
import 'package:acafe_kiosk/common/reposotories/data_sync_repo.dart';
import 'package:acafe_kiosk/data/datasource/remote/exception/api_error_handler.dart';
import 'package:acafe_kiosk/utill/app_constants.dart';

class BannerRepo extends DataSyncRepo {
  BannerRepo({required super.dioClient, required super.sharedPreferences});

  // Method to fetch banner list (expects a list response)
  Future<ApiResponseModel<T>> getBannerList<T>({required DataSourceEnum source}) async {
    return await fetchData<T>(AppConstants.bannerUri, source);
  }


  Future<ApiResponseModel> getProductDetails(String productID) async {
    try {
      final response = await dioClient.get('${AppConstants.productDetailsUri}$productID');

      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }
}