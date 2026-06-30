import 'dart:async';
import 'dart:io';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:acafe_customer/common/enums/data_source_enum.dart';
import 'package:acafe_customer/data/datasource/local/cache_response.dart';
import 'package:acafe_customer/features/cart/providers/frequently_bought_provider.dart';
import 'package:acafe_customer/features/checkout/providers/checkout_provider.dart';
import 'package:acafe_customer/features/home/providers/sorting_provider.dart';
import 'package:acafe_customer/helper/notification_helper.dart';
import 'package:acafe_customer/helper/responsive_helper.dart';
import 'package:acafe_customer/helper/router_helper.dart';
import 'package:acafe_customer/localization/app_localization.dart';
import 'package:acafe_customer/features/auth/providers/auth_provider.dart';
import 'package:acafe_customer/features/kiosk/screens/kiosk_login_screen.dart';
import 'package:acafe_customer/features/kiosk/providers/kiosk_auth_provider.dart';
import 'package:acafe_customer/features/home/providers/banner_provider.dart';
import 'package:acafe_customer/features/branch/providers/branch_provider.dart';
import 'package:acafe_customer/features/cart/providers/cart_provider.dart';
import 'package:acafe_customer/features/category/providers/category_provider.dart';
import 'package:acafe_customer/features/chat/providers/chat_provider.dart';
import 'package:acafe_customer/features/coupon/providers/coupon_provider.dart';
import 'package:acafe_customer/features/language/providers/language_provider.dart';
import 'package:acafe_customer/features/language/providers/localization_provider.dart';
import 'package:acafe_customer/features/address/providers/location_provider.dart';
import 'package:acafe_customer/common/providers/news_letter_provider.dart';
import 'package:acafe_customer/features/notification/providers/notification_provider.dart';
import 'package:acafe_customer/features/onboarding/providers/onboarding_provider.dart';
import 'package:acafe_customer/features/order/providers/order_provider.dart';
import 'package:acafe_customer/common/providers/product_provider.dart';
import 'package:acafe_customer/features/profile/providers/profile_provider.dart';
import 'package:acafe_customer/features/rate_review/providers/review_provider.dart';
import 'package:acafe_customer/features/search/providers/search_provider.dart';
import 'package:acafe_customer/features/setmenu/providers/set_menu_provider.dart';
import 'package:acafe_customer/features/splash/providers/splash_provider.dart';
import 'package:acafe_customer/common/providers/theme_provider.dart';
import 'package:acafe_customer/features/wallet/providers/wallet_provider.dart';
import 'package:acafe_customer/features/wishlist/providers/wishlist_provider.dart';
import 'package:acafe_customer/theme/brand_colors.dart';
import 'package:acafe_customer/theme/dark_theme.dart';
import 'package:acafe_customer/theme/light_theme.dart';
import 'package:acafe_customer/utill/app_constants.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';
import 'di_container.dart' as di;
import 'package:universal_html/html.dart' as html;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

late AndroidNotificationChannel channel;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final database = AppDatabase();

PayloadModel? _pendingLaunchPayload;

Future<void> _ensureFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyAXGwobGlroK3Ex_3eDfU4_dQDm8iBk1To',
        authDomain: 'acafe-2d9df.firebaseapp.com',
        projectId: 'acafe-2d9df',
        storageBucket: 'acafe-2d9df.firebasestorage.app',
        messagingSenderId: '130585563604',
        appId: '1:130585563604:web:45d7256610ff3f061f0641',
      ),
    );
  }
}

Future<void> _initNotificationsAsync() async {
  try {
    final RemoteMessage? remoteMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (remoteMessage != null) {
      _pendingLaunchPayload = PayloadModel.fromJson(remoteMessage.data);
    }

    await NotificationHelper.initialize(flutterLocalNotificationsPlugin);
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    if (_pendingLaunchPayload != null) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        Provider.of<SplashProvider>(ctx, listen: false).setPayloadModel(
            payloadModel: _pendingLaunchPayload, isUpdate: false);
      }
    }
  } catch (e) {
    debugPrint('notification init error: $e');
  }
}

Future<void> main() async {
  if (ResponsiveHelper.isMobilePhone()) {
    HttpOverrides.global = MyHttpOverrides();
  }
  setPathUrlStrategy();
  final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }

  await Future.wait([
    di.init(),
    AppLocalization.preloadDefault(),
  ]);

  if (kIsWeb) {
    await _ensureFirebase();
  } else {
    await Firebase.initializeApp();
    channel = const AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.high,
    );
  }

  GoRouter.optionURLReflectsImperativeAPIs = true;

  String? path;
  if (!kIsWeb) {
    try {
      path = await initDynamicLinks();
    } catch (e) {
      debugPrint('initDynamicLinks: $e');
    }
  }

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => di.sl<ThemeProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<SplashProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<LanguageProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<OnBoardingProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<CategoryProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<BannerProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<ProductProvider>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<LocalizationProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<AuthProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<KioskAuthProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<LocationProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<CartProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<OrderProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<ChatProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<SetMenuProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<ProfileProvider>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<NotificationProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<CouponProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<WishListProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<SearchProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<NewsLetterProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<WalletProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<BranchProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<ReviewProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<ProductSortProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<CheckoutProvider>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<FrequentlyBoughtProvider>()),
    ],
    child: MyApp(
        orderId: null,
        isWeb: !kIsWeb,
        route: path,
        payloadModel: _pendingLaunchPayload),
  ));

  unawaited(_initNotificationsAsync());
}

class MyApp extends StatefulWidget {
  final int? orderId;
  final bool isWeb;
  final String? route;
  final PayloadModel? payloadModel;
  const MyApp(
      {super.key,
      required this.orderId,
      required this.isWeb,
      this.route,
      this.payloadModel});

  @override
  State<MyApp> createState() => _MyAppState();
}

Future<String?> initDynamicLinks() async {
  final appLinks = AppLinks();
  final uri = await appLinks.getInitialLink();
  String? path;
  if (uri != null) {
    path = uri.path;
  } else {
    path = null;
  }
  return path;
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.payloadModel != null) {
      Provider.of<SplashProvider>(context, listen: false)
          .setPayloadModel(payloadModel: widget.payloadModel, isUpdate: false);
    }

    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onRemoveLoader());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
      });
    }

    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // On web, FCM onMessage only fires while the tab is foreground. When the
    // customer returns to this tab, re-pull notifications so the bell badge
    // reflects any status changes that arrived while it was backgrounded.
    if (state == AppLifecycleState.resumed && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isLoggedIn()) {
        Provider.of<NotificationProvider>(context, listen: false)
            .getNotificationList(context);
      }
    }
  }

  void _loadData() async {
    final splashProvider =
        Provider.of<SplashProvider>(context, listen: false);
    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);

    splashProvider.initSharedData();
    Provider.of<CartProvider>(context, listen: false).getCartData(context);
    splashProvider.getPolicyPage();

    // Config in background — login screen renders immediately.
    _route();

    // Non-critical data after first paint.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      if (Provider.of<AuthProvider>(context, listen: false).isLoggedIn()) {
        await Provider.of<ProfileProvider>(context, listen: false)
            .getUserInfo(true);
      }
      if (categoryProvider.categoryList == null) {
        categoryProvider.getCategoryList(true);
      }
    });
  }

  void _route() {
    final SplashProvider splashProvider =
        Provider.of<SplashProvider>(context, listen: false);
    final AuthProvider authProvider =
        Provider.of<AuthProvider>(context, listen: false);

    splashProvider
        .initConfig(context, DataSourceEnum.local)
        .then((value) async {
      if (value != null) {
        if (authProvider.isLoggedIn()) {
          await authProvider.updateToken();
          // Seed the notification list so the bell's unread badge is accurate
          // from app launch (before the user opens the notification screen).
          if (mounted) {
            Provider.of<NotificationProvider>(context, listen: false)
                .getNotificationList(context);
          }
        }

        _onRemoveLoader();
      }
    });
  }

  void _onRemoveLoader() {
    for (final selector in [
      '#kiosk-boot-shell',
      '#splash',
      '#splash-branding',
      'flutter-loader',
      '.flutter-loader',
      '#flutter-loading',
      '.loading-progress',
      '.preloader',
      '.header',
      '#loading',
      'progress',
    ]) {
      html.document.querySelectorAll(selector).forEach((el) => el.remove());
    }
    html.document.getElementById('splash-screen-style')?.remove();
    html.document.body?.style.background = '#E8E6DF';
    html.document.body?.style.backgroundImage = 'none';
  }

  @override
  Widget build(BuildContext context) {
    List<Locale> locals = [];
    for (var language in AppConstants.languages) {
      locals.add(Locale(language.languageCode!, language.countryCode));
    }

    final splashProvider = Provider.of<SplashProvider>(context, listen: false);

    return MaterialApp.router(
                routerConfig: RouterHelper.goRoutes,
                title: splashProvider.configModel?.restaurantName ??
                    AppConstants.appName,
                debugShowCheckedModeBanner: false,
                theme: Provider.of<ThemeProvider>(context).darkTheme
                    ? dark.copyWith(
                        primaryColor: BrandColors.primary,
                        scaffoldBackgroundColor: BrandColors.backgroundDark,
                        canvasColor: BrandColors.backgroundDark,
                      )
                    : light.copyWith(
                        primaryColor: BrandColors.primary,
                        scaffoldBackgroundColor: BrandColors.background,
                        canvasColor: BrandColors.background,
                      ),
                locale: Provider.of<LocalizationProvider>(context).locale,
                localizationsDelegates: const [
                  AppLocalization.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: locals,
                scrollBehavior:
                    const MaterialScrollBehavior().copyWith(dragDevices: {
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.touch,
                  PointerDeviceKind.stylus,
                  PointerDeviceKind.unknown
                }),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(
                          MediaQuery.sizeOf(context).width < 380 ? 0.9 : 1)),
                  child: child ?? const KioskLoginScreen(),
                ),
              );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class Get {
  static BuildContext? get context => navigatorKey.currentContext;
  static NavigatorState? get navigator => navigatorKey.currentState;
}
