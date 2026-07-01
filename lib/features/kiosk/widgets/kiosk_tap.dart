import 'package:flutter/material.dart';

/// Kiosk tap target — no ink splash, hover tint, or Material overlay on press.
class KioskTap extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const KioskTap({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return child;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: child,
      ),
    );
  }
}
