import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:acafe_kiosk/common/models/place_order_body.dart';
import 'package:acafe_kiosk/features/auth/providers/auth_provider.dart';
import 'package:acafe_kiosk/features/branch/providers/branch_provider.dart';
import 'package:acafe_kiosk/features/cart/providers/cart_provider.dart';
import 'package:acafe_kiosk/features/kiosk/domain/kiosk_session.dart';
import 'package:acafe_kiosk/features/order/providers/order_provider.dart';
import 'package:acafe_kiosk/features/splash/providers/splash_provider.dart';
import 'package:provider/provider.dart';

/// Result of submitting a kiosk order to the backend.
class KioskPlaceResult {
  final bool success;
  final String? orderId;
  final String? message;
  const KioskPlaceResult({required this.success, this.orderId, this.message});
}

/// Places the current cart as a guest kiosk order via the SAME path as the user
/// web app (OrderProvider.placeOrder → /api/v1/customer/order/place), so it
/// lands in the orders table and kitchen app identically.
///
/// The caller is responsible for what happens on success (store the order
/// number, clear the cart, navigate). [amount] is the order total to charge.
Future<KioskPlaceResult> placeKioskOrder(
  BuildContext context, {
  required double amount,
  String? paymentRef,
}) async {
  final cartProvider = Provider.of<CartProvider>(context, listen: false);
  final orderProvider = Provider.of<OrderProvider>(context, listen: false);
  final branchProvider = Provider.of<BranchProvider>(context, listen: false);
  final splashProvider = Provider.of<SplashProvider>(context, listen: false);
  final authProvider = Provider.of<AuthProvider>(context, listen: false);

  // Kiosk orders are placed as a guest — make sure a guest account exists so the
  // backend's required guest_id is attached by the order repository.
  if (authProvider.getGuestId() == null) {
    await authProvider.addGuest();
  }

  // Build the order cart items — mirrors the web app's confirm_button_widget.
  final List<Cart> carts = [];
  for (final cart in cartProvider.cartList) {
    if (cart == null) continue;

    final List<int?> addOnIdList = [];
    final List<int?> addOnQtyList = [];
    for (final addOn in cart.addOnIds ?? []) {
      addOnIdList.add(addOn.id);
      addOnQtyList.add(addOn.quantity);
    }

    final List<OrderVariation> variations = [];
    final productVariations = cart.product?.variations;
    final selected = cart.variations;
    if (productVariations != null && selected != null && selected.isNotEmpty) {
      for (int i = 0; i < productVariations.length; i++) {
        if (i < selected.length && selected[i].contains(true)) {
          variations.add(OrderVariation(name: productVariations[i].name, values: OrderVariationValue(label: [])));
          final values = productVariations[i].variationValues ?? [];
          for (int j = 0; j < values.length; j++) {
            if (j < selected[i].length && (selected[i][j] ?? false)) {
              variations.last.values!.label!.add(values[j].level);
            }
          }
        }
      }
    }

    carts.add(Cart(
      cart.product!.id.toString(), cart.discountedPrice.toString(), [], variations,
      cart.discountAmount, cart.quantity, cart.taxAmount, addOnIdList, addOnQtyList,
    ));
  }

  final branches = splashProvider.configModel?.branches;
  final int? branchId = branchProvider.getBranch()?.id ??
      ((branches != null && branches.isNotEmpty) ? branches.first?.id : null);

  final name = KioskSession.instance.customerName;
  final placeOrderBody = PlaceOrderBody(
    cart: carts,
    couponDiscountAmount: 0,
    couponDiscountTitle: null,
    couponCode: null,
    orderAmount: double.parse(amount.toStringAsFixed(2)),
    deliveryAddressId: 0,
    deliveryAddress: null,
    orderType: 'take_away',
    paymentMethod: 'cash_on_delivery',
    branchId: branchId,
    deliveryTime: 'now',
    deliveryDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    orderNote: name.isNotEmpty ? 'Kiosk order — $name' : 'Kiosk order',
    distance: 0,
    isPartial: '0',
    isCutleryRequired: '0',
    transactionReference: paymentRef,
    bringChangeAmount: 0,
  );

  final completer = Completer<KioskPlaceResult>();
  orderProvider.placeOrder(placeOrderBody, (bool success, String? message, String orderId) {
    if (!completer.isCompleted) {
      completer.complete(KioskPlaceResult(success: success, orderId: orderId, message: message));
    }
  });
  return completer.future;
}
