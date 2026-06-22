import 'package:flutter/foundation.dart';

class CountryConfig {
  CountryConfig._();

  static const String defaultCountryCode = 'GB';

  /// UK only in production; UK + Pakistan when debugging.
  static List<String> get allowedCountryCodes {
    if (kDebugMode) {
      return ['GB', 'PK'];
    }
    return ['GB'];
  }

  static bool get showCountryPicker => kDebugMode;
}
