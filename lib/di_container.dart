import 'package:dio/dio.dart';
import 'package:acafe_kiosk/common/providers/data_sync_provider.dart';
import 'package:acafe_kiosk/common/reposotories/data_sync_repo.dart';
import 'package:acafe_kiosk/common/reposotories/product_repo.dart';
import 'package:acafe_kiosk/features/auth/domain/reposotories/auth_repo.dart';
import 'package:acafe_kiosk/features/kiosk/domain/kiosk_auth_repo.dart';
import 'package:acafe_kiosk/features/kiosk/domain/kiosk_order_repo.dart';
import 'package:acafe_kiosk/features/kiosk/providers/kiosk_auth_provider.dart';
import 'package:acafe_kiosk/features/checkout/providers/checkout_provider.dart';
import 'package:acafe_kiosk/features/cart/domain/reposotories/cart_repo.dart';
import 'package:acafe_kiosk/features/category/domain/reposotories/category_repo.dart';
import 'package:acafe_kiosk/features/chat/domain/reposotories/chat_repo.dart';
import 'package:acafe_kiosk/features/coupon/domain/reposotories/coupon_repo.dart';
import 'package:acafe_kiosk/features/address/domain/reposotories/location_repo.dart';
import 'package:acafe_kiosk/features/home/providers/sorting_provider.dart';
import 'package:acafe_kiosk/features/notification/domain/reposotories/notification_repo.dart';
import 'package:acafe_kiosk/features/order/domain/reposotories/order_repo.dart';
import 'package:acafe_kiosk/features/language/domain/reposotories/language_repo.dart';
import 'package:acafe_kiosk/features/onboarding/domain/reposotories/onboarding_repo.dart';
import 'package:acafe_kiosk/features/search/domain/reposotories/search_repo.dart';
import 'package:acafe_kiosk/features/profile/domain/reposotories/profile_repo.dart';
import 'package:acafe_kiosk/features/splash/domain/reposotories/splash_repo.dart';
import 'package:acafe_kiosk/features/wallet/domain/reposotories/wallet_repo.dart';
import 'package:acafe_kiosk/features/wallet/providers/wallet_provider.dart';
import 'package:acafe_kiosk/features/wishlist/domain/reposotories/wishlist_repo.dart';
import 'package:acafe_kiosk/features/auth/providers/auth_provider.dart';
import 'package:acafe_kiosk/features/branch/providers/branch_provider.dart';
import 'package:acafe_kiosk/features/cart/providers/cart_provider.dart';
import 'package:acafe_kiosk/features/category/providers/category_provider.dart';
import 'package:acafe_kiosk/features/chat/providers/chat_provider.dart';
import 'package:acafe_kiosk/features/coupon/providers/coupon_provider.dart';
import 'package:acafe_kiosk/features/language/providers/localization_provider.dart';
import 'package:acafe_kiosk/features/notification/providers/notification_provider.dart';
import 'package:acafe_kiosk/features/order/providers/order_provider.dart';
import 'package:acafe_kiosk/features/address/providers/location_provider.dart';
import 'package:acafe_kiosk/common/providers/product_provider.dart';
import 'package:acafe_kiosk/features/language/providers/language_provider.dart';
import 'package:acafe_kiosk/features/onboarding/providers/onboarding_provider.dart';
import 'package:acafe_kiosk/features/search/providers/search_provider.dart';
import 'package:acafe_kiosk/features/profile/providers/profile_provider.dart';
import 'package:acafe_kiosk/features/splash/providers/splash_provider.dart';
import 'package:acafe_kiosk/common/providers/theme_provider.dart';
import 'package:acafe_kiosk/features/wishlist/providers/wishlist_provider.dart';
import 'package:acafe_kiosk/utill/app_constants.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/datasource/remote/dio/dio_client.dart';
import 'data/datasource/remote/dio/logging_interceptor.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core
  sl.registerLazySingleton(() => DioClient(AppConstants.baseUrl, sl(), loggingInterceptor: sl(), sharedPreferences: sl()));

  // Repository
  sl.registerLazySingleton(() => DataSyncRepo(dioClient: sl(), sharedPreferences: sl()));
  sl.registerLazySingleton(() => SplashRepo(sharedPreferences: sl(), dioClient: sl()));
  sl.registerLazySingleton(() => CategoryRepo(dioClient: sl(), sharedPreferences: sl()));
  sl.registerLazySingleton(() => ProductRepo(dioClient: sl(), sharedPreferences: sl()));
  sl.registerLazySingleton(() => LanguageRepo());
  sl.registerLazySingleton(() => OnBoardingRepo(dioClient: sl()));
  sl.registerLazySingleton(() => CartRepo(sharedPreferences: sl()));
  sl.registerLazySingleton(() => OrderRepo(dioClient: sl(), sharedPreferences: sl()));
  sl.registerLazySingleton(() => ChatRepo(dioClient: sl(), sharedPreferences: sl()));
  sl.registerLazySingleton(() => AuthRepo(dioClient: sl(), sharedPreferences: sl()));
  sl.registerLazySingleton(() => LocationRepo(dioClient: sl(), sharedPreferences: sl()));
  sl.registerLazySingleton(() => ProfileRepo(dioClient: sl(), sharedPreferences: sl()));
  sl.registerLazySingleton(() => SearchRepo(dioClient: sl(), sharedPreferences: sl()));
  sl.registerLazySingleton(() => NotificationRepo(dioClient: sl()));
  sl.registerLazySingleton(() => CouponRepo(dioClient: sl()));
  sl.registerLazySingleton(() => WishListRepo(dioClient: sl()));
  sl.registerLazySingleton(() => WalletRepo(dioClient: sl(), sharedPreferences: sl()));
  sl.registerLazySingleton(() => KioskAuthRepo(dioClient: sl(), sharedPreferences: sl()));
  sl.registerLazySingleton(() => KioskOrderRepo(dioClient: sl()));

  // Provider
  sl.registerLazySingleton(() => DataSyncProvider());
  sl.registerLazySingleton(() => ThemeProvider(sharedPreferences: sl()));
  sl.registerLazySingleton(() => SplashProvider(splashRepo: sl()));
  sl.registerLazySingleton(() => LocalizationProvider(sharedPreferences: sl(), dioClient: sl()));
  sl.registerLazySingleton(() => LanguageProvider(languageRepo: sl()));
  sl.registerLazySingleton(() => OnBoardingProvider(onboardingRepo: sl(), sharedPreferences: sl()));
  sl.registerLazySingleton(() => CategoryProvider(categoryRepo: sl()));
  sl.registerLazySingleton(() => ProductProvider(productRepo: sl()));
  sl.registerLazySingleton(() => CartProvider(cartRepo: sl()));
  sl.registerLazySingleton(() => OrderProvider(orderRepo: sl(), sharedPreferences: sl()));
  sl.registerLazySingleton(() => ChatProvider(chatRepo: sl(), notificationRepo: sl()));
  sl.registerLazySingleton(() => AuthProvider(authRepo: sl()));
  sl.registerLazySingleton(() => LocationProvider(sharedPreferences: sl(), locationRepo: sl()));
  sl.registerLazySingleton(() => ProfileProvider(profileRepo: sl()));
  sl.registerLazySingleton(() => NotificationProvider(notificationRepo: sl()));
  sl.registerLazySingleton(() => WishListProvider(wishListRepo: sl()));
  sl.registerLazySingleton(() => CouponProvider(couponRepo: sl()));
  sl.registerLazySingleton(() => SearchProvider(searchRepo: sl()));
  sl.registerLazySingleton(() => BranchProvider(splashRepo: sl()));
  sl.registerLazySingleton(() => ProductSortProvider());
  sl.registerLazySingleton(() => CheckoutProvider(orderRepo: sl()));
  sl.registerLazySingleton(() => WalletProvider(walletRepo: sl()));
  sl.registerLazySingleton(() => KioskAuthProvider(kioskAuthRepo: sl()));


  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => LoggingInterceptor());
}
