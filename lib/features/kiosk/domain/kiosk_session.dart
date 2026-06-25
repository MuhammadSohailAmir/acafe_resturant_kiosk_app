import 'package:acafe_customer/common/models/cart_model.dart';

/// Lightweight in-memory holder for the current kiosk checkout session.
///
/// Keeps the customer name and the last placed order number across the
/// checkout → payment → success screens without needing a global provider.
/// Reset on a fresh order / idle timeout.
class KioskSession {
  KioskSession._();
  static final KioskSession instance = KioskSession._();

  String customerName = '';
  String? lastOrderNumber;
  String? lastOrderId;

  void reset() {
    customerName = '';
    lastOrderNumber = null;
    lastOrderId = null;
  }
}

/// Line total for a cart item = discounted unit price × qty + active add-ons.
double kioskLineTotal(CartModel cart) {
  double total = (cart.discountedPrice ?? 0) * (cart.quantity ?? 1);
  for (final addOn in cart.addOnIds ?? []) {
    final id = addOn.id;
    final qty = addOn.quantity ?? 1;
    final match = (cart.product?.addOns ?? []).where((a) => a.id == id);
    if (match.isNotEmpty) {
      total += (match.first.price ?? 0) * qty;
    }
  }
  return total;
}

/// Grand total across all cart lines.
double kioskCartTotal(List<CartModel?> cartList) {
  double total = 0;
  for (final cart in cartList) {
    if (cart != null) total += kioskLineTotal(cart);
  }
  return total;
}

/// Total number of items (sum of quantities) in the cart.
int kioskCartItemCount(List<CartModel?> cartList) {
  int count = 0;
  for (final cart in cartList) {
    if (cart != null) count += cart.quantity ?? 1;
  }
  return count;
}
