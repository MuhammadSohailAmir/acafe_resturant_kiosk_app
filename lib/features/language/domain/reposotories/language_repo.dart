import 'package:flutter/material.dart';
import 'package:acafe_kiosk/common/models/language_model.dart';
import 'package:acafe_kiosk/utill/app_constants.dart';

class LanguageRepo {
  List<LanguageModel> getAllLanguages({BuildContext? context}) {
    return AppConstants.languages;
  }
}
