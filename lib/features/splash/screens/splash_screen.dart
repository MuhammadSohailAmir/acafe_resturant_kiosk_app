import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:acafe_customer/common/enums/data_source_enum.dart';
import 'package:acafe_customer/common/enums/notificaion_type_enum.dart';
import 'package:acafe_customer/common/models/config_model.dart';
import 'package:acafe_customer/features/auth/providers/auth_provider.dart';
import 'package:acafe_customer/features/branch/providers/branch_provider.dart';
import 'package:acafe_customer/features/cart/providers/cart_provider.dart';
import 'package:acafe_customer/features/onboarding/providers/onboarding_provider.dart';
import 'package:acafe_customer/features/splash/providers/splash_provider.dart';
import 'package:acafe_customer/helper/custom_snackbar_helper.dart';
import 'package:acafe_customer/helper/notification_helper.dart';
import 'package:acafe_customer/helper/responsive_helper.dart';
import 'package:acafe_customer/helper/router_helper.dart';
import 'package:acafe_customer/helper/version_helper.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/main.dart';
import 'package:acafe_customer/theme/brand_colors.dart';
import 'package:acafe_customer/utill/app_constants.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  final String? routeTo;
  const SplashScreen({super.key, this.routeTo});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final GlobalKey<ScaffoldMessengerState> _globalKey = GlobalKey();
  StreamSubscription<List<ConnectivityResult>>? subscription;

  bool isNotLoaded = true;

  String? notificationType;
  PayloadModel? payloadModel;

  @override
  void initState() {
    super.initState();

    _checkConnectivity();

    final SplashProvider splashProvider =
        Provider.of<SplashProvider>(context, listen: false);
    splashProvider.initSharedData();
    payloadModel = splashProvider.payloadModel;
    Provider.of<CartProvider>(context, listen: false).getCartData(context);

    if (payloadModel?.type?.isNotEmpty ?? false) {
      notificationType = splashProvider.payloadModel?.type ?? '';
    }

    _route();
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  void _route() {
    final SplashProvider splashProvider =
        Provider.of<SplashProvider>(context, listen: false);

    splashProvider
        .initConfig(context, DataSourceEnum.local)
        .then((value) async {
      _onConfigAction(value, splashProvider, Get.context!);
    });
  }

  void _onConfigAction(
      ConfigModel? value, SplashProvider splashProvider, BuildContext context) {
    if (value != null) {
      final BranchProvider branchProvider =
          Provider.of<BranchProvider>(context, listen: false);

      final config = splashProvider.configModel!;
      double? minimumVersion;

      if (defaultTargetPlatform == TargetPlatform.android &&
          config.playStoreConfig != null) {
        minimumVersion = config.playStoreConfig!.minVersion;
      } else if (defaultTargetPlatform == TargetPlatform.iOS &&
          config.appStoreConfig != null) {
        minimumVersion = config.appStoreConfig!.minVersion;
      }

      if (config.maintenanceMode?.maintenanceStatus == 1 &&
          config.maintenanceMode?.selectedMaintenanceSystem?.customerApp == 1) {
        RouterHelper.getMaintainRoute(
            action: RouteAction.pushNamedAndRemoveUntil);
      } else if (VersionHelper.parse('$minimumVersion') >
          VersionHelper.parse(AppConstants.appVersion)) {
        RouterHelper.getUpdateRoute(
            action: RouteAction.pushNamedAndRemoveUntil);
      } else if (notificationType?.isNotEmpty ?? false) {
        notificationRoute();
      } else {
        if (widget.routeTo != null) {
          Get.context!.pushReplacement(widget.routeTo!);
        } else if (Provider.of<AuthProvider>(Get.context!, listen: false)
            .isLoggedIn()) {
          Provider.of<AuthProvider>(Get.context!, listen: false).updateToken();
          RouterHelper.getMainRoute(
              action: RouteAction.pushNamedAndRemoveUntil);
        } else {
          Future.delayed(const Duration(milliseconds: 10)).then((v) {
            ResponsiveHelper.isMobile() &&
                    Provider.of<OnBoardingProvider>(Get.context!, listen: false)
                        .showOnBoardingStatus
                ? RouterHelper.getLanguageRoute(false,
                    action: RouteAction.pushNamedAndRemoveUntil)
                : RouterHelper.getMainRoute(
                    action: RouteAction.pushNamedAndRemoveUntil);
          });
        }
      }
    }
    // Remove native splash AFTER navigation is queued so the destination
    // screen is already building when the ~300 ms fade completes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  void notificationRoute() {
    NotificationType? notificationTypeEnum =
        getNotificationTypeEnum(notificationType);

    switch (notificationTypeEnum) {
      case NotificationType.order:
        RouterHelper.getOrderDetailsRoute(payloadModel?.orderId,
            fromSplash: true, action: RouteAction.pushNamedAndRemoveUntil);
        break;
      case NotificationType.message:
        RouterHelper.getChatRoute(
            fromSplash: true, action: RouteAction.pushNamedAndRemoveUntil);
        break;
      case NotificationType.general:
        RouterHelper.getNotificationRoute(
            fromSplash: true, action: RouteAction.pushNamedAndRemoveUntil);
        break;
      case null:
        debugPrint(
            '================Notification type does not exist=================$notificationType');
        RouterHelper.getMainRoute(action: RouteAction.pushNamedAndRemoveUntil);
        break;
      case NotificationType.referral:
        RouterHelper.getWalletRoute(
            action: RouteAction.pushNamedAndRemoveUntil);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SplashProvider>(
      builder: (context, splashProvider, _) {
        if (splashProvider.configModel != null && isNotLoaded) {
          isNotLoaded = false;
          _onConfigAction(splashProvider.configModel, splashProvider, context);
        }

        return Scaffold(
          key: _globalKey,
          backgroundColor: BrandColors.primary,
        );
      },
    );
  }

  void _checkConnectivity() {
    bool isFirst = true;
    subscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      bool isConnected = result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.mobile);

      if (((isFirst && !isConnected) || !isFirst) && mounted) {
        FlutterNativeSplash.remove();
        showCustomSnackBarHelper(
            getTranslated(
                isConnected ? 'connected' : 'no_internet_connection', context),
            isError: !isConnected);

        if (isConnected &&
            ModalRoute.of(context)?.settings.name ==
                RouterHelper.splashScreen) {
          _route();
        }
      }
      isFirst = false;
    });
  }
}
