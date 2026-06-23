import 'package:acafe_customer/common/models/cart_model.dart';

class KioskOrderResult {
  final bool success;
  final String? orderNumber;
  final String? message;
  const KioskOrderResult({required this.success, this.orderNumber, this.message});
}

/// Submits a paid kiosk order into the existing order pipeline.
///
/// REAL IMPLEMENTATION TODO (mirror acafe_restaurant_user_web_app):
///   POST the order to the same ORDER_SUBMIT_ENDPOINT the web app uses so it
///   lands in the kitchen app identically. Include: line items + resolved
///   modifiers/quantities, customerName, paymentRef, channel = "kiosk",
///   locationId, kioskId, and a stable idempotencyKey so a network retry never
///   creates a duplicate kitchen ticket. Only call this AFTER payment is `paid`.
abstract class KioskOrderService {
  Future<KioskOrderResult> submit({
    required List<CartModel?> cartList,
    required String customerName,
    required double total,
    required String? paymentRef,
    required String idempotencyKey,
  });
}

/// Simulated submission for development. Returns a generated order number.
/// Replace with a repository that calls the existing backend order endpoint.
class SimulatedKioskOrderService implements KioskOrderService {
  @override
  Future<KioskOrderResult> submit({
    required List<CartModel?> cartList,
    required String customerName,
    required double total,
    required String? paymentRef,
    required String idempotencyKey,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final number = (DateTime.now().millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');
    return KioskOrderResult(success: true, orderNumber: '#$number');
  }
}
