// To parse this JSON data, do
//
//     final searchRecommendModel = searchRecommendModelFromJson(jsonString);

import 'dart:convert';

import 'package:acafe_kiosk/features/category/domain/category_model.dart';

SearchRecommendModel searchRecommendModelFromJson(String str) => SearchRecommendModel.fromJson(json.decode(str));

String searchRecommendModelToJson(SearchRecommendModel data) => json.encode(data.toJson());

class SearchRecommendModel {
  List<CategoryModel> categories;

  SearchRecommendModel({
    required this.categories,
  });

  factory SearchRecommendModel.fromJson(Map<String, dynamic> json) => SearchRecommendModel(
    categories: List<CategoryModel>.from(json["categories"].map((x) => CategoryModel.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "categories": List<dynamic>.from(categories.map((x) => x.toJson())),
  };
}

