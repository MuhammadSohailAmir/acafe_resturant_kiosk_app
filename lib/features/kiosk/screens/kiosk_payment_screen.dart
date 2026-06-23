import 'dart:async';
import 'package:flutter/material.dart';
import 'package:acafe_customer/features/cart/providers/cart_provider.dart';
import 'package:acafe_customer/features/kiosk/domain/kiosk_order_service.dart';
import 'package:acafe_customer/features/kiosk/domain/kiosk_payment_service.dart';
import 'package:acafe_customer/features/kiosk/domain/kiosk_session.dart';
import 'package:acafe_customer/helper/price_converter_helper.dart';
import 'package:acafe_customer/helper/router_helper.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/utill/dimensions.dart';
import 'package:acafe_customer/utill/styles.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

enum _Phase { processing, submitting, failed }

/// Drives the terminal payment state machine:
/// processing → paid → submit order → success
/// processing → failed → Retry / Stop(30)
class KioskPaymentScreen extends StatefulWidget {
  const KioskPaymentScreen({super.key});

  @override
  State<KioskPaymentScreen> createState() => _KioskPaymentScreenState();
}

class _KioskPaymentScreenState extends State<KioskPaymentScreen> {
  // Swap these for the real Mollie + backend implementations when ready.
  final KioskPaymentService _payment = SimulatedKioskPaymentService();
  final KioskOrderService _orders = SimulatedKioskOrderService();

  // Stable across retries of this checkout attempt (idempotency).
  final String _idempotencyKey = 'kiosk-${DateTime.now().millisecondsSinceEpoch}';

  _Phase _phase = _Phase.processing;
  double _amount = 0;
  Timer? _stopTimer;
  int _stopCountdown = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amount = kioskCartTotal(Provider.of<CartProvider>(context, listen: false).cartList);
      _startPayment();
    });
  }

  @override
  void dispose() {
    _stopTimer?.cancel();
    super.dispose();
  }

  Future<void> _startPayment() async {
    setState(() => _phase = _Phase.processing);
    final result = await _payment.pay(amount: _amount, idempotencyKey: _idempotencyKey);
    if (!mounted) return;

    switch (result.status) {
      case KioskPaymentStatus.paid:
        await _submitOrder(result.paymentRef);
        break;
      case KioskPaymentStatus.failed:
        _showFailure();
        break;
      case KioskPaymentStatus.canceled:
        _exitToCart();
        break;
    }
  }

  Future<void> _submitOrder(String? paymentRef) async {
    setState(() => _phase = _Phase.submitting);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    final result = await _orders.submit(
      cartList: cartProvider.cartList,
      customerName: KioskSession.instance.customerName,
      total: _amount,
      paymentRef: paymentRef,
      idempotencyKey: _idempotencyKey,
    );
    if (!mounted) return;

    if (result.success) {
      KioskSession.instance.lastOrderNumber = result.orderNumber;
      cartProvider.clearCartList();
      RouterHelper.getKioskSuccessRoute(action: RouteAction.pushReplacement);
    } else {
      // Paid but submission failed — surface as a recoverable failure.
      _showFailure();
    }
  }

  void _showFailure() {
    setState(() => _phase = _Phase.failed);
    _stopCountdown = 30;
    _stopTimer?.cancel();
    _stopTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _stopCountdown--);
      if (_stopCountdown <= 0) {
        t.cancel();
        _stop();
      }
    });
  }

  void _retry() {
    _stopTimer?.cancel();
    _startPayment();
  }

  Future<void> _stop() async {
    _stopTimer?.cancel();
    await _payment.cancel();
    _exitToCart();
  }

  void _exitToCart() {
    // Preserve the cart and return to the menu so the customer can retry/adjust.
    if (mounted) context.go(RouterHelper.kioskMenuScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(child: _phase == _Phase.failed ? const SizedBox() : _processingView()),
            if (_phase == _Phase.failed) _FailureModal(countdown: _stopCountdown, onRetry: _retry, onStop: _stop),
          ],
        ),
      ),
    );
  }

  Widget _processingView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 64, height: 64, child: CircularProgressIndicator(strokeWidth: 5)),
        const SizedBox(height: Dimensions.paddingSizeExtraLarge),
        Text(
          _phase == _Phase.submitting
              ? (getTranslated('placing_your_order', context) ?? 'Placing your order…')
              : (getTranslated('follow_instructions_on_reader', context) ?? 'Follow the instructions on the card reader'),
          textAlign: TextAlign.center,
          style: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge!.color),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
        Text(PriceConverterHelper.convertPrice(_amount),
            style: rubikBold.copyWith(fontSize: 28, color: Theme.of(context).primaryColor)),
      ],
    );
  }
}

class _FailureModal extends StatelessWidget {
  final int countdown;
  final VoidCallback onRetry;
  final VoidCallback onStop;
  const _FailureModal({required this.countdown, required this.onRetry, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      alignment: Alignment.center,
      child: Container(
        width: 360,
        margin: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              child: Icon(Icons.error_outline, size: 40, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(getTranslated('payment_failed', context) ?? 'Payment failed…',
                style: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor)),
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),
            Row(
              children: [
                Expanded(child: _Btn(label: getTranslated('retry', context) ?? 'Retry', onTap: onRetry)),
                const SizedBox(width: Dimensions.paddingSizeDefault),
                Expanded(child: _Btn(label: '${getTranslated('stop', context) ?? 'Stop'} ($countdown)', onTap: onStop)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Btn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).primaryColor,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Container(height: 50, alignment: Alignment.center, child: Text(label, style: rubikSemiBold.copyWith(color: Colors.white))),
      ),
    );
  }
}
