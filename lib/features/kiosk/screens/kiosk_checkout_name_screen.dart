import 'package:flutter/material.dart';
import 'package:acafe_customer/features/kiosk/domain/kiosk_session.dart';
import 'package:acafe_customer/helper/custom_snackbar_helper.dart';
import 'package:acafe_customer/helper/router_helper.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/utill/dimensions.dart';
import 'package:acafe_customer/utill/styles.dart';
import 'package:go_router/go_router.dart';

/// Checkout step 1 — collect the customer name. The focused [TextField] raises
/// the on-screen keyboard automatically on a touch kiosk.
class KioskCheckoutNameScreen extends StatefulWidget {
  const KioskCheckoutNameScreen({super.key});

  @override
  State<KioskCheckoutNameScreen> createState() => _KioskCheckoutNameScreenState();
}

class _KioskCheckoutNameScreenState extends State<KioskCheckoutNameScreen> {
  final TextEditingController _controller =
      TextEditingController(text: KioskSession.instance.customerName);
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _next() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      showCustomSnackBarHelper(getTranslated('please_enter_your_name', context) ?? 'Please enter your name');
      return;
    }
    KioskSession.instance.customerName = name;
    RouterHelper.getKioskConfirmRoute();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(step: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                    Text(
                      getTranslated('fill_in_your_name', context) ?? 'Fill in your name',
                      style: rubikRegular.copyWith(color: Theme.of(context).hintColor),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textCapitalization: TextCapitalization.words,
                      style: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeOverLarge),
                      decoration: const InputDecoration(border: UnderlineInputBorder()),
                      onSubmitted: (_) => _next(),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                    Center(
                      child: SizedBox(
                        width: 280,
                        child: _PrimaryPill(label: getTranslated('next', context) ?? 'NEXT', onTap: _next),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int step;
  const _Header({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              Text(
                getTranslated('checkout', context) ?? 'Checkout',
                style: rubikSemiBold.copyWith(
                  fontSize: Dimensions.fontSizeOverLarge,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              CircleAvatar(
                radius: 14,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text('$step', style: rubikSemiBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall)),
              ),
              const SizedBox(height: 4),
              Text(getTranslated('complete_your_order', context) ?? 'Complete your order',
                  style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
            ],
          ),
          Align(
            alignment: Alignment.topRight,
            child: InkWell(
              onTap: () => context.go(RouterHelper.kioskMenuScreen),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).disabledColor.withValues(alpha: 0.15),
                child: Icon(Icons.close, size: 20, color: Theme.of(context).textTheme.bodyLarge!.color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).primaryColor,
      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          child: Text(label.toUpperCase(), style: rubikSemiBold.copyWith(color: Colors.white, letterSpacing: 1)),
        ),
      ),
    );
  }
}
