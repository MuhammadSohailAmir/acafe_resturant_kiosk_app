
import 'package:acafe_kiosk/data/datasource/remote/dio/dio_client.dart';
import 'package:acafe_kiosk/data/datasource/remote/exception/api_error_handler.dart';
import 'package:acafe_kiosk/common/models/api_response_model.dart';
import 'package:acafe_kiosk/utill/app_constants.dart';

class NotificationRepo {
  final DioClient? dioClient;

  NotificationRepo({required this.dioClient});

  Future<ApiResponseModel> getNotificationList() async {
    try {
      final response = await dioClient!.get(AppConstants.notificationUri);
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  /// Marks notifications as read. Pass [id] for a single one, or omit to mark
  /// all of the authenticated customer's notifications as read.
  Future<ApiResponseModel> markAsRead({int? id}) async {
    try {
      final response = await dioClient!.put(
        AppConstants.notificationReadUri,
        data: id != null ? {'id': id} : {},
      );
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }
}
