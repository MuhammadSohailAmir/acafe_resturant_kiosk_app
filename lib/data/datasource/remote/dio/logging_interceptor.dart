import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs every HTTP call: base URL, path, full URL, headers, body, status, errors.
class LoggingInterceptor extends InterceptorsWrapper {
  static const String _tag = '🌐 API';
  static const int _maxBodyLength = 800;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('''
$_tag ────────── REQUEST ──────────
  METHOD   : ${options.method}
  BASE URL : ${options.baseUrl}
  PATH     : ${options.path}
  FULL URL : ${options.uri}
  HEADERS  : ${_sanitizeHeaders(options.headers)}
  QUERY    : ${options.queryParameters.isEmpty ? 'null' : options.queryParameters}
  BODY     : ${_truncate(options.data)}
$_tag ───────────────────────────────''');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final req = response.requestOptions;
      debugPrint('''
$_tag ────────── SUCCESS ──────────
  API      : ${req.path}
  METHOD   : ${req.method}
  STATUS   : ${response.statusCode} ${response.statusMessage ?? ''}
  FULL URL : ${req.uri}
  DATA     : ${_truncate(response.data)}
$_tag ───────────────────────────────''');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final req = err.requestOptions;
      debugPrint('''
$_tag ────────── ERROR ──────────
  API      : ${req.path}
  METHOD   : ${req.method}
  BASE URL : ${req.baseUrl}
  FULL URL : ${req.uri}
  TYPE     : ${err.type}
  STATUS   : ${err.response?.statusCode ?? '—'}
  MESSAGE  : ${err.message}
  BODY     : ${_truncate(err.response?.data)}
$_tag ───────────────────────────────''');
    }
    handler.next(err);
  }

  static String _truncate(dynamic data) {
    if (data == null) return 'null';
    final String text = data is String ? data : data.toString();
    if (text.length <= _maxBodyLength) return text;
    return '${text.substring(0, _maxBodyLength)}... [truncated, ${text.length} chars total]';
  }

  static Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);
    final auth = sanitized['Authorization'];
    if (auth is String && auth.startsWith('Bearer ') && auth.length > 20) {
      sanitized['Authorization'] = 'Bearer ***';
    }
    return sanitized;
  }
}
