import 'package:flutter/material.dart';
import 'package:acafe_customer/common/enums/data_source_enum.dart';
import 'package:acafe_customer/features/kiosk/providers/kiosk_auth_provider.dart';
import 'package:acafe_customer/features/splash/providers/splash_provider.dart';
import 'package:acafe_customer/helper/router_helper.dart';
import 'package:acafe_customer/theme/brand_colors.dart';
import 'package:provider/provider.dart';

/// Boot gate that runs before the Intro screen.
///
///  * no token stored                 -> LoginScreen
///  * token stored & valid            -> hydrate branch -> Intro (welcome)
///  * token stored but revoked/inactive -> wipe creds   -> LoginScreen
///
/// Shows a flicker-free branded loader while config loads and the token is
/// validated, so the kiosk never flashes the login screen for a logged-in
/// device.
class KioskBootstrapScreen extends StatefulWidget {
  const KioskBootstrapScreen({super.key});

  @override
  State<KioskBootstrapScreen> createState() => _KioskBootstrapScreenState();
}

class _KioskBootstrapScreenState extends State<KioskBootstrapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final splashProvider = Provider.of<SplashProvider>(context, listen: false);
    final kioskAuth = Provider.of<KioskAuthProvider>(context, listen: false);

    // Make sure shared defaults + config are ready (on native the app's main
    // loader only runs for web/deep-link launches, so do it here too).
    await splashProvider.initSharedData();
    if (splashProvider.configModel == null) {
      if (!mounted) return;
      await splashProvider.initConfig(context, DataSourceEnum.local);
    }

    if (!mounted) return;

    if (!kioskAuth.isLoggedIn()) {
      RouterHelper.getKioskLoginRoute(action: RouteAction.pushReplacement);
      return;
    }

    final bool valid = await kioskAuth.validateSession();
    if (!mounted) return;

    if (valid) {
      RouterHelper.getKioskWelcomeRoute(action: RouteAction.pushReplacement);
    } else {
      RouterHelper.getKioskLoginRoute(action: RouteAction.pushReplacement);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: BrandColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'A/CAFÉ',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                letterSpacing: 5,
                color: BrandColors.primary,
              ),
            ),
            SizedBox(height: 28),
            SizedBox(
              height: 30,
              width: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(BrandColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
