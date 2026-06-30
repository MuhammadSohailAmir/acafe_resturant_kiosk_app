/// Compile-time feature toggles for optional modules.
///
/// Set [paymentModuleEnabled] to `true` to register payment/wallet routes and
/// allow navigation into the dormant customer payment flow.
class FeatureFlags {
  FeatureFlags._();

  /// When `false` (default): payment routes are not registered, navigation
  /// helpers no-op, and payment providers are not mounted in the widget tree.
  /// Kiosk checkout uses the built-in kiosk payment screen only.
  static const bool paymentModuleEnabled = false;
}
