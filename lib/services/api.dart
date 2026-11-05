import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// An error with a message that is safe to show to the user.
class ApiException implements Exception {
  final String message;
  final int? status; // null = the server could not be reached
  final int? retryAfterSeconds;

  const ApiException(this.message, {this.status, this.retryAfterSeconds});

  bool get unreachable => status == null;

  @override
  String toString() => message;
}

/// Thin JSON client for the AgriMind server.
class ApiClient {
  ApiClient({required String baseUrl, this.token, http.Client? client})
      : baseUrl = _clean(baseUrl),
        _http = client ?? http.Client();

  final String baseUrl;
  final String? token;
  final http.Client _http;

  /// Called when the server rejects the session token (expired / signed out elsewhere).
  void Function()? onUnauthorized;

  static const _timeout = Duration(seconds: 12);

  static String _clean(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  /// Returns null when [url] is fine, otherwise a message.
  static String? validateUrl(String url) {
    final u = Uri.tryParse(_clean(url));
    if (u == null || !(u.scheme == 'http' || u.scheme == 'https') || u.host.isEmpty) {
      return 'Enter a full address such as https://your-domain.com';
    }
    return null;
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) => _send('GET', path, query: query);
  Future<dynamic> post(String path, [Object? body]) => _send('POST', path, body: body ?? const {});
  Future<dynamic> put(String path, Object body) => _send('PUT', path, body: body);
  Future<dynamic> patch(String path, Object body) => _send('PATCH', path, body: body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path, {Object? body, Map<String, String>? query}) async {
    var uri = Uri.parse('$baseUrl$path');
    if (query != null && query.isNotEmpty) uri = uri.replace(queryParameters: query);

    final request = http.Request(method, uri)
      ..headers['accept'] = 'application/json'
      ..headers['content-type'] = 'application/json';
    if (token != null) request.headers['authorization'] = 'Bearer $token';
    if (body != null) request.body = jsonEncode(body);

    http.Response response;
    try {
      response = await http.Response.fromStream(await _http.send(request).timeout(_timeout));
    } on TimeoutException {
      throw const ApiException('The server did not answer in time. Check the address and your connection.');
    } catch (_) {
      throw const ApiException('Cannot reach the server. Check the address and your connection.');
    }

    dynamic data;
    try {
      data = response.body.isEmpty ? null : jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      data = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return data;

    if (response.statusCode == 401 && token != null) onUnauthorized?.call();

    var message = 'Request failed (${response.statusCode}).';
    int? retry;
    if (data is Map) {
      if (data['error'] is String) message = data['error'] as String;
      if (data['retryAfterSeconds'] is num) retry = (data['retryAfterSeconds'] as num).toInt();
    }
    throw ApiException(message, status: response.statusCode, retryAfterSeconds: retry);
  }

  void close() => _http.close();
}
