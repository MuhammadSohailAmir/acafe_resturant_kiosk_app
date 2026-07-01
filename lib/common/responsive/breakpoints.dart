import 'package:flutter/foundation.dart';

/// Width breakpoints + large-screen layout rules for the kiosk.
///
/// These govern the *large-format* behaviour only. Everything below
/// [Breakpoints.medium] (1200px) is deliberately left untouched so small
/// portrait tablets stay pixel-identical to the current design.
///
/// This complements [KioskResponsive] (kiosk_responsive.dart), which owns the
/// proportional Figma-pixel scaling. Breakpoints here decide *how many* product
/// columns to show and the max content width; the scaler decides the size of
/// everything inside them.
class Breakpoints {
  Breakpoints._();

  static const double small = 800;
  static const double medium = 1200;
  static const double large = 1600;
}

/// Max width the app content is centered within on large displays. Below this
/// the cap never binds, so small/medium screens are unaffected. The beige page
/// background still fills the screen edge-to-edge behind the cap.
const double kKioskContentMaxWidth = 1440;

/// Product-grid column count, driven by the **window** width (not the scaled
/// product-area width). Keying off the window makes large kiosk displays show
/// more, smaller cards instead of 3 stretched ones. Unchanged below 1200px.
///
///  <800 → 3 · <1200 → 3 (unchanged) · <1600 → 4 · ≥1600 → 5
int menuGridColumns(double width) {
  if (width < Breakpoints.small) return 3; // small portrait tablet — unchanged
  if (width < Breakpoints.medium) return 3; // standard kiosk — unchanged
  if (width < Breakpoints.large) return 4; // large display
  return 5; // very large / full-screen display
}

@visibleForTesting
Map<double, int> get debugColumnSamples => {
      800: menuGridColumns(800),
      1024: menuGridColumns(1024),
      1400: menuGridColumns(1400),
      1920: menuGridColumns(1920),
    };
