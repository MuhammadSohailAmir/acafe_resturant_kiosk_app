import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:acafe_kiosk/common/feature_flags.dart';
import 'package:acafe_kiosk/features/checkout/screens/order_successful_screen.dart';
import 'package:acafe_kiosk/features/payment/screens/order_web_payment.dart';
import 'package:acafe_kiosk/features/payment/screens/payment_screen.dart';
import 'package:acafe_kiosk/features/wallet/screens/wallet_screen.dart';
import 'package:acafe_kiosk/helper/router_helper.dart';
import 'package:acafe_kiosk/main.dart';
import 'package:go_router/go_router.dart';

/// Customer payment routes — preserved for future integration.
///
/// Routes are registered in [RouterHelper.goRoutes] only when
/// [FeatureFlags.paymentModuleEnabled] is `true`. Navigation helpers guard
/// against accidental use while the flag is off.
class PaymentRouter {
  PaymentRouter._();

  static const String paymentScreen = '/payment';
  static const String orderSuccessScreen = '/order-completed';
  static const String orderWebPayment = '/order-web-payment';
  static const String wallet = '/wallet-screen';

  static bool get isEnabled => FeatureFlags.paymentModuleEnabled;

  static bool isPaymentPath(String path) =>
      path == paymentScreen ||
      path == orderSuccessScreen ||
      path == orderWebPayment ||
      path == wallet;

  static String getPaymentRoute(String url, {bool fromCheckout = true}) {
    return _navigateRoute(
        '$paymentScreen?url=${Uri.encodeComponent(url)}&from_checkout=$fromCheckout');
  }

  static String getWalletRoute(
      {String? token, String? flag, RouteAction? action}) {
    return _navigateRoute('$wallet?token=$token&&flag=$flag', route: action);
  }

  static String getOrderSuccessScreen(String orderId, String statusMessage,
      {RouteAction? action}) {
    return _navigateRoute(
        '$orderSuccessScreen?order_id=$orderId&status=$statusMessage',
        route: action ?? RouteAction.pushReplacement);
  }

  static String getOrderWebPaymentRoute(String token) {
    return _navigateRoute('$orderWebPayment?token=$token');
  }

  /// Payment module routes — merged into [RouterHelper.goRoutes] when enabled.
  static List<RouteBase> get routes => [
        GoRoute(
          path: paymentScreen,
          builder: (context, state) => RouterHelper.routeHandler(
            context,
            path: RouterHelper.pathFromState(state),
            PaymentScreen(
              url: Uri.decodeComponent('${state.uri.queryParameters['url']}'),
              formCheckout:
                  state.uri.queryParameters['from_checkout'] == 'true',
            ),
            isBranchCheck: true,
          ),
        ),
        GoRoute(
          path: orderWebPayment,
          builder: (context, state) => RouterHelper.routeHandler(
            context,
            path: RouterHelper.pathFromState(state),
            OrderWebPayment(
              token: state.uri.queryParameters['token'],
            ),
            isBranchCheck: true,
          ),
        ),
        GoRoute(
          path: orderSuccessScreen,
          builder: (context, state) {
            final statusParam = state.uri.queryParameters['status'];
            final status = (statusParam == 'success' ||
                    statusParam == 'payment-success')
                ? 0
                : statusParam == 'payment-fail'
                    ? 1
                    : statusParam == 'order-fail'
                        ? 2
                        : 3;
            return RouterHelper.routeHandler(
              context,
              path: RouterHelper.pathFromState(state),
              OrderSuccessfulScreen(
                orderID: state.uri.queryParameters['order_id'],
                status: status,
              ),
              isBranchCheck: true,
            );
          },
        ),
        GoRoute(
          path: wallet,
          builder: (context, state) => RouterHelper.routeHandler(
            context,
            path: RouterHelper.pathFromState(state),
            WalletScreen(
              token: state.uri.queryParameters['token'],
              status: state.uri.queryParameters['flag'],
            ),
          ),
        ),
      ];

  static String _navigateRoute(String path,
      {RouteAction? route = RouteAction.push}) {
    if (!isEnabled) {
      debugPrint(
          'PaymentRouter: navigation blocked — set FeatureFlags.paymentModuleEnabled = true');
      return path;
    }
    if (route == RouteAction.pushNamedAndRemoveUntil) {
      Get.context?.go(path);
    } else if (route == RouteAction.pushReplacement) {
      Get.context?.pushReplacement(path);
    } else {
      Get.context?.push(path);
    }
    return path;
  }
}
