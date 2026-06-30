import 'package:flutter/material.dart';
import 'package:acafe_customer/utill/styles.dart';
import 'package:go_router/go_router.dart';

// ===========================================================================
// Shared building blocks for the kiosk checkout flow (NAME / EMAIL / PAYMENT),
// ported from the Figma designs (nodes 655:2924, 655:3002, …). All sizes come
// from the 2572px-wide artboard and are scaled by `s = screenWidth / kCheckoutDesignWidth`.
// ===========================================================================
const double kCheckoutDesignWidth = 2572;
const Color kCheckoutPageBg = Color(0xFFF7F1DE);
const Color kCheckoutFieldBg = Color(0xFFFBF8EF);
const Color kCheckoutErrorRed = Color(0xFFEF4444);
const Color kCheckoutHintColor = Color(0xFFB9B5A6);
const Color kCheckoutButtonText = Color(0xFFFAF9F5);

double checkoutScale(double w) => w / kCheckoutDesignWidth;

/// Page layout shared by every checkout step: back button + stepper, a centered
/// title/subtitle prompt, a scrollable field area and a pinned bottom bar.
class KioskCheckoutScaffold extends StatelessWidget {
  final int activeStep; // 0 = NAME, 1 = EMAIL, 2 = PAYMENT
  final String title;
  final String subtitle;
  final double subtitleFontSize;

  /// Builds the label + field + error block (needs the resolved scale).
  final Widget Function(double s) fieldBuilder;

  /// Builds the bottom button bar (one or more [KioskCheckoutButton]s).
  final Widget Function(double s) bottomBuilder;

  const KioskCheckoutScaffold({
    super.key,
    required this.activeStep,
    required this.title,
    required this.subtitle,
    required this.fieldBuilder,
    required this.bottomBuilder,
    this.subtitleFontSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCheckoutPageBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double s = checkoutScale(constraints.maxWidth);
            return Column(
              children: [
                KioskCheckoutHeader(s: s, activeStep: activeStep),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 107 * s),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 150 * s),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: loewExtraBold.copyWith(fontSize: 128 * s, height: 1, color: Colors.black),
                        ),
                        SizedBox(height: 30 * s),
                        Opacity(
                          opacity: 0.75,
                          child: Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: loewMedium.copyWith(fontSize: subtitleFontSize * s, height: 1.2, color: Colors.black),
                          ),
                        ),
                        SizedBox(height: 380 * s),
                        fieldBuilder(s),
                        SizedBox(height: 100 * s),
                      ],
                    ),
                  ),
                ),
                bottomBuilder(s),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Back button + the NAME / EMAIL / PAYMENT progress stepper.
class KioskCheckoutHeader extends StatelessWidget {
  final double s;
  final int activeStep;
  const KioskCheckoutHeader({super.key, required this.s, required this.activeStep});

  static const List<String> _steps = ['NAME', 'EMAIL', 'PAYMENT'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(107 * s, 121 * s, 107 * s, 20 * s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Expanded(child: _Stepper(s: s, steps: _steps, activeStep: activeStep)),
          SizedBox(width: 141 * s), // balance the back button so the stepper stays centred.
        ],
      ),
    );
  }
}

enum _StepState { completed, active, upcoming }

class _Stepper extends StatelessWidget {
  final double s;
  final List<String> steps;
  final int activeStep;
  const _Stepper({required this.s, required this.steps, required this.activeStep});

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
          child: switch (state) {
            // Active: a page-bg dot inside the filled black circle.
            _StepState.active =>
              Container(width: 79 * s, height: 79 * s, decoration: const BoxDecoration(shape: BoxShape.circle, color: kCheckoutPageBg)),
            _StepState.completed => Icon(Icons.check, size: 90 * s, color: Colors.white),
            _StepState.upcoming => null,
          },
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

/// Centered label + rounded input + optional inline error. The border turns red
/// when [hasError] is set.
class KioskCheckoutField extends StatelessWidget {
  final double s;
  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool hasError;
  final String? errorText;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  const KioskCheckoutField({
    super.key,
    required this.s,
    required this.label,
    required this.hint,
    required this.controller,
    this.focusNode,
    this.hasError = false,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: loewExtraBold.copyWith(fontSize: 72 * s, color: Colors.black),
        ),
        SizedBox(height: 30 * s),
        Container(
          constraints: BoxConstraints(minHeight: 252 * s),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 64 * s),
          decoration: BoxDecoration(
            color: kCheckoutFieldBg,
            borderRadius: BorderRadius.circular(30 * s),
            border: Border.all(
              color: hasError ? kCheckoutErrorRed : kCheckoutHintColor,
              width: hasError ? (4 * s).clamp(2.0, 6.0) : (2 * s).clamp(1.0, 4.0),
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            textAlign: TextAlign.center,
            cursorColor: Colors.black,
            style: loewRegular.copyWith(fontSize: 64 * s, color: Colors.black),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: hint,
              hintStyle: loewRegular.copyWith(fontSize: 64 * s, color: kCheckoutHintColor),
            ),
            onChanged: onChanged,
            onSubmitted: onSubmitted,
          ),
        ),
        if (hasError && errorText != null) ...[
          SizedBox(height: 28 * s),
          Text(
            errorText!,
            style: loewMedium.copyWith(fontSize: 44 * s, height: 1.1, color: kCheckoutErrorRed),
          ),
        ],
      ],
    );
  }
}

/// Reusable checkout action button — filled (black) or outlined.
class KioskCheckoutButton extends StatelessWidget {
  final double s;
  final String label;
  final bool filled;
  final double fontSize;
  final VoidCallback? onTap;
  const KioskCheckoutButton({
    super.key,
    required this.s,
    required this.label,
    required this.filled,
    required this.onTap,
    this.fontSize = 72,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: filled ? Colors.black : Colors.transparent,
        borderRadius: BorderRadius.circular(30 * s),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 252 * s,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30 * s),
              border: filled ? null : Border.all(color: Colors.black, width: (8 * s).clamp(2.0, 10.0)),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: (filled ? loewExtraBold : loewBold).copyWith(
                fontSize: fontSize * s,
                color: filled ? kCheckoutButtonText : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
