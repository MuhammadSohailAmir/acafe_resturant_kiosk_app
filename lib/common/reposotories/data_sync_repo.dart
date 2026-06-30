import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:acafe_customer/common/enums/data_source_enum.dart';
import 'package:acafe_customer/common/models/api_response_model.dart';
import 'package:acafe_customer/data/datasource/local/cache_response.dart';
import 'package:acafe_customer/data/datasource/remote/dio/dio_client.dart';
import 'package:acafe_customer/data/datasource/remote/exception/api_error_handler.dart';
import 'package:acafe_customer/helper/db_helper.dart';
import 'package:acafe_customer/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataSyncRepo {
  final DioClient dioClient;
  final SharedPreferences? sharedPreferences;

  DataSyncRepo({required this.dioClient, required this.sharedPreferences});

  Future<ApiResponseModel<T>> fetchData<T>(String uri, DataSourceEnum source) async {
    if (kDebugMode) {
      debugPrint('DataSyncRepo [$source] → $uri (base: ${dioClient.baseUrl})');
    }
    try {
      return source == DataSourceEnum.client ? await _fetchFromClient<T>(uri) : await _fetchFromLocalCache<T>(uri);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DataSyncRepo [$source] ✗ FAILED $uri → $e');
      }

      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<T>> _fetchFromClient<T>(String uri) async {
    const maxAttempts = 3;
    Object? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await dioClient.get(uri);
        if (kDebugMode) {
          debugPrint('DataSyncRepo [client] ✓ $uri → ${response.statusCode}');
        }

        final cacheData = CacheResponseCompanion(
          endPoint: Value(uri),
          header: Value(jsonEncode(dioClient.dio?.options.headers)),
          response: Value(jsonEncode(response.data)),
        );

        if (kIsWeb) {
          _cacheResponseWeb(uri, cacheData);
        } else {
          await DbHelper.insertOrUpdate(id: uri, data: cacheData);
        }

        return ApiResponseModel.withSuccess(response as T);
      } catch (e) {
        lastError = e;
        if (attempt < maxAttempts && _isRetryableNetworkError(e)) {
          if (kDebugMode) {
            debugPrint('DataSyncRepo [client] retry $attempt/$maxAttempts for $uri → $e');
          }
          await Future.delayed(Duration(milliseconds: 400 * attempt));
          continue;
        }
        rethrow;
      }
    }

    throw lastError ?? Exception('Failed to fetch $uri');
  }

  bool _isRetryableNetworkError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('handshake')
        || message.contains('connection terminated')
        || message.contains('connection reset')
        || message.contains('connection closed')
        || message.contains('socketexception');
  }

  void _cacheResponseWeb(String uri, CacheResponseCompanion cacheData) {
    final cacheJson = CacheResponseData(
      id: 0,
      endPoint: cacheData.endPoint.value,
      header: cacheData.header.value,
      response: cacheData.response.value,
    ).toJson();
    sharedPreferences?.setString(uri, jsonEncode(cacheJson));
  }

  Future<ApiResponseModel<T>> _fetchFromLocalCache<T>(String uri) async {
    CacheResponseData? cacheData;

    if (kIsWeb) {
      final cachedJson = sharedPreferences?.getString(uri);
      if (cachedJson != null) {
        cacheData = CacheResponseData.fromJson(jsonDecode(cachedJson));
      }
    } else {
      cacheData = await database.getCacheResponseById(uri);
    }

    if (cacheData != null) {
      if (kDebugMode) {
        debugPrint('DataSyncRepo [local] ✓ $uri → cache hit');
      }
      return ApiResponseModel.withSuccess(cacheData as T);
    } else {
      if (kDebugMode) {
        debugPrint('DataSyncRepo [local] ✗ $uri → no cache');
      }
      return ApiResponseModel.withError("No local data found for $uri");
    }
  }
}
