import 'package:flutter/material.dart';
import 'package:acafe_customer/features/kiosk/domain/kiosk_session.dart';
import 'package:acafe_customer/helper/router_helper.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/utill/styles.dart';
import 'package:go_router/go_router.dart';

// ===========================================================================
// CHECKOUT · NAME step — faithful, fully-responsive port of the Figma design
// (node 655:2924). Sizes come from the 2572px-wide artboard, scaled by
// `s = screenWidth / _kDesignWidth`.
// ===========================================================================
const double _kDesignWidth = 2572;
const Color _kPageBg = Color(0xFFF7F1DE);
const Color _kFieldBg = Color(0xFFFBF8EF);
const Color _kErrorRed = Color(0xFFEF4444);
const Color _kHintColor = Color(0xFFB9B5A6);

double _scaleFor(double w) => w / _kDesignWidth;

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
  bool _showError = false;

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
      setState(() => _showError = true);
      return;
    }
    KioskSession.instance.customerName = name;
    RouterHelper.getKioskConfirmRoute();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPageBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double s = _scaleFor(constraints.maxWidth);
            return Column(
              children: [
                _CheckoutHeader(s: s, activeStep: 0),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 107 * s),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 150 * s),
                        Text(
                          "What's your name?",
                          textAlign: TextAlign.center,
                          style: loewExtraBold.copyWith(fontSize: 128 * s, height: 1, color: Colors.black),
                        ),
                        SizedBox(height: 30 * s),
                        Opacity(
                          opacity: 0.75,
                          child: Text(
                            "We'll use your name when your order is ready for pick up.",
                            textAlign: TextAlign.center,
                            style: loewMedium.copyWith(fontSize: 48 * s, height: 1.2, color: Colors.black),
                          ),
                        ),
                        SizedBox(height: 380 * s),
                        Text(
                          getTranslated('name', context)?.toUpperCase() ?? 'NAME',
                          textAlign: TextAlign.center,
                          style: loewExtraBold.copyWith(fontSize: 72 * s, color: Colors.black),
                        ),
                        SizedBox(height: 30 * s),
                        _NameField(
                          s: s,
                          controller: _controller,
                          focusNode: _focusNode,
                          hasError: _showError,
                          onChanged: (_) {
                            if (_showError) setState(() => _showError = false);
                          },
                          onSubmitted: (_) => _next(),
                        ),
                        if (_showError) ...[
                          SizedBox(height: 28 * s),
                          Text(
                            getTranslated('please_enter_your_name_to_continue', context) ??
                                'Please enter your name to continue',
                            style: loewMedium.copyWith(fontSize: 44 * s, height: 1.1, color: _kErrorRed),
                          ),
                        ],
                        SizedBox(height: 100 * s),
                      ],
                    ),
                  ),
                ),
                _NextButton(s: s, onTap: _next),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Back button + the NAME / EMAIL / PAYMENT progress stepper.
class _CheckoutHeader extends StatelessWidget {
  final double s;
  final int activeStep;
  const _CheckoutHeader({required this.s, required this.activeStep});

  static const List<String> _steps = ['NAME', 'EMAIL', 'PAYMENT'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(107 * s, 121 * s, 107 * s, 20 * s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button.
          Material(
            color: Colors.transparent,
            shape: CircleBorder(side: BorderSide(color: Colors.black, width: (4 * s).clamp(2.0, 6.0))),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.pop(),
              child: SizedBox(
                width: 141 * s,
                height: 141 * s,
                child: Icon(Icons.arrow_back_ios_new, size: 56 * s, color: Colors.black),
              ),
            ),
          ),
          SizedBox(width: 60 * s),
          // Stepper, centred in the remaining space.
          Expanded(child: _CheckoutStepper(s: s, steps: _steps, activeStep: activeStep)),
          SizedBox(width: 141 * s), // balance the back button so the stepper stays centred.
        ],
      ),
    );
  }
}

class _CheckoutStepper extends StatelessWidget {
  final double s;
  final List<String> steps;
  final int activeStep;
  const _CheckoutStepper({required this.s, required this.steps, required this.activeStep});

  @override
  Widget build(BuildContext context) {
    final List<Widget> row = [];
    for (int i = 0; i < steps.length; i++) {
      row.add(_StepNode(s: s, label: steps[i], state: _stateOf(i)));
      if (i < steps.length - 1) row.add(Expanded(child: _Connector(s: s)));
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: row);
  }

  _StepState _stateOf(int i) {
    if (i < activeStep) return _StepState.completed;
    if (i == activeStep) return _StepState.active;
    return _StepState.upcoming;
  }
}

enum _StepState { completed, active, upcoming }

class _StepNode extends StatelessWidget {
  final double s;
  final String label;
  final _StepState state;
  const _StepNode({required this.s, required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    final double d = 165 * s;
    final bool filled = state != _StepState.upcoming;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: d,
          height: d,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? Colors.black : Colors.transparent,
            border: Border.all(color: Colors.black, width: (4 * s).clamp(2.0, 6.0)),
          ),
          child: state == _StepState.active
              // Active: a page-bg dot inside the filled black circle.
              ? Container(width: 79 * s, height: 79 * s, decoration: const BoxDecoration(shape: BoxShape.circle, color: _kPageBg))
              : state == _StepState.completed
                  ? Icon(Icons.check, size: 90 * s, color: Colors.white)
                  : null,
        ),
        SizedBox(height: 24 * s),
        Text(label, style: loewExtraBold.copyWith(fontSize: 46 * s, color: Colors.black)),
      ],
    );
  }
}

class _Connector extends StatelessWidget {
  final double s;
  const _Connector({required this.s});

  @override
  Widget build(BuildContext context) {
    // Sit on the circle's vertical centre (circle is 165px tall).
    return Padding(
      padding: EdgeInsets.only(top: 82 * s, left: 20 * s, right: 20 * s),
      child: Container(height: (4 * s).clamp(2.0, 6.0), color: Colors.black),
    );
  }
}

/// Rounded "ENTER YOUR NAME" field; the border turns red on validation error.
class _NameField extends StatelessWidget {
  final double s;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  const _NameField({
    required this.s,
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 252 * s),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 64 * s),
      decoration: BoxDecoration(
        color: _kFieldBg,
        borderRadius: BorderRadius.circular(30 * s),
        border: Border.all(
          color: hasError ? _kErrorRed : _kHintColor,
          width: hasError ? (4 * s).clamp(2.0, 6.0) : (2 * s).clamp(1.0, 4.0),
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textCapitalization: TextCapitalization.words,
        textAlign: TextAlign.center,
        cursorColor: Colors.black,
        style: loewRegular.copyWith(fontSize: 64 * s, color: Colors.black),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: getTranslated('enter_your_name', context)?.toUpperCase() ?? 'ENTER YOUR NAME',
          hintStyle: loewRegular.copyWith(fontSize: 64 * s, color: _kHintColor),
        ),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
    );
  }
}

/// Pinned full-width black "Next" button.
class _NextButton extends StatelessWidget {
  final double s;
  final VoidCallback onTap;
  const _NextButton({required this.s, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(107 * s, 16 * s, 107 * s, 24 * s),
      child: Material(
        color: Colors.black,
        borderRadius: BorderRadius.circular(30 * s),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 252 * s,
            alignment: Alignment.center,
            child: Text(
              getTranslated('next', context) ?? 'Next',
              style: loewExtraBold.copyWith(fontSize: 64 * s, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
