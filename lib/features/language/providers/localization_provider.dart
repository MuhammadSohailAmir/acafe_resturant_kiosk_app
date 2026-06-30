import 'package:flutter/material.dart';
import 'package:acafe_kiosk/data/datasource/remote/dio/dio_client.dart';
import 'package:acafe_kiosk/utill/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationProvider extends ChangeNotifier {
  DioClient? dioClient;
  final SharedPreferences? sharedPreferences;

  LocalizationProvider({required this.sharedPreferences, required this.dioClient}) {
    _loadCurrentLanguage();
  }

  Locale _locale = const Locale('en', 'US');
  bool _isLtr = true;
  Locale get locale => _locale;
  bool get isLtr => _isLtr;

  Future<void> setLanguage(Locale locale, {bool isDataUpdate = true}) async {
    _locale = locale;
    if(_locale.languageCode == 'ar') {
      _isLtr = false;
    }else {
      _isLtr = true;
    }
    _saveLanguage(_locale);

   await dioClient!.updateHeader(getToken: sharedPreferences!.getString(AppConstants.token)).then((value){
     // Language-specific data reload is handled by ChooseLanguageScreen for kiosk.
    });
    notifyListeners();
  }

  _loadCurrentLanguage() async {
    // Default to English on a fresh kiosk (no saved selection) regardless of
    // the order languages are listed in AppConstants.languages.
    _locale = Locale(sharedPreferences!.getString(AppConstants.languageCode) ?? 'en',
        sharedPreferences!.getString(AppConstants.countryCode) ?? 'US');
    _isLtr = _locale.languageCode != 'ar';
    notifyListeners();
  }

  _saveLanguage(Locale locale) async {
    sharedPreferences!.setString(AppConstants.languageCode, locale.languageCode);
    sharedPreferences!.setString(AppConstants.countryCode, locale.countryCode!);
  }
}