import 'package:acafe_customer/data/datasource/remote/dio/dio_client.dart';
import 'package:acafe_customer/data/datasource/remote/exception/api_error_handler.dart';
import 'package:acafe_customer/common/models/api_response_model.dart';

/// Device-authenticated kiosk order calls. Currently: minting the post-order
/// claim token used for the QR / loyalty-points offer on the success screen.
class KioskOrderRepo {
  final DioClient dioClient;

  KioskOrderRepo({required this.dioClient});

  /// POST /api/v1/kiosk/order/{orderId}/claim-token  (device auth)
  Future<ApiResponseModel> getClaimToken(String orderId) async {
    try {
      final response =
          await dioClient.post('/api/v1/kiosk/order/$orderId/claim-token');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }
}
