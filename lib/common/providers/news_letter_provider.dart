import 'package:flutter/material.dart';
import 'package:acafe_kiosk/common/models/api_response_model.dart';
import 'package:acafe_kiosk/common/reposotories/news_letter_repo.dart';
import 'package:acafe_kiosk/localization/language_constrants.dart';
import 'package:acafe_kiosk/main.dart';
import 'package:acafe_kiosk/helper/custom_snackbar_helper.dart';

class NewsLetterProvider extends ChangeNotifier {
  final NewsLetterRepo? newsLetterRepo;
  NewsLetterProvider({required this.newsLetterRepo});


  Future<void> addToNewsLetter(String email) async {
    ApiResponseModel apiResponse = await newsLetterRepo!.addToNewsLetter(email);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      showCustomSnackBarHelper(getTranslated('successfully_subscribe', Get.context!),isError: false);
      notifyListeners();
    } else {
      showCustomSnackBarHelper(getTranslated('mail_already_exist', Get.context!));
    }
  }
}
