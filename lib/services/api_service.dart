import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static const Duration _timeoutDuration = Duration(seconds: 15);

  static Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // GET Request
  static Future<dynamic> get(String url, {bool requiresAuth = true}) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(_timeoutDuration);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Error de conexión. Verifica que el servidor esté activo.');
    } on http.ClientException {
      throw ApiException('Error de comunicación con el backend.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Ocurrió un error inesperado: ${e.toString()}');
    }
  }

  // POST Request
  static Future<dynamic> post(
    String url, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeoutDuration);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Error de conexión. Verifica que el servidor esté activo.');
    } on http.ClientException {
      throw ApiException('Error de comunicación con el backend.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Ocurrió un error inesperado: ${e.toString()}');
    }
  }

  // PATCH Request
  static Future<dynamic> patch(
    String url, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http
          .patch(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeoutDuration);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Error de conexión. Verifica que el servidor esté activo.');
    } on http.ClientException {
      throw ApiException('Error de comunicación con el backend.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Ocurrió un error inesperado: ${e.toString()}');
    }
  }

  // PUT Request
  static Future<dynamic> put(
    String url, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http
          .put(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeoutDuration);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Error de conexión. Verifica que el servidor esté activo.');
    } on http.ClientException {
      throw ApiException('Error de comunicación con el backend.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Ocurrió un error inesperado: ${e.toString()}');
    }
  }

  // DELETE Request
  static Future<dynamic> delete(
    String url, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http
          .delete(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeoutDuration);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Error de conexión. Verifica que el servidor esté activo.');
    } on http.ClientException {
      throw ApiException('Error de comunicación con el backend.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Ocurrió un error inesperado: ${e.toString()}');
    }
  }

  // Process HTTP response & parse NestJS errors
  static dynamic _handleResponse(http.Response response) {
    dynamic responseBody;
    if (response.body.isNotEmpty) {
      try {
        responseBody = jsonDecode(response.body);
      } catch (_) {
        responseBody = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    }

    String errorMessage = 'Error en el servidor (${response.statusCode})';

    if (responseBody is Map<String, dynamic>) {
      final message = responseBody['message'];
      if (message != null) {
        if (message is List) {
          errorMessage = message.join(', ');
        } else {
          errorMessage = message.toString();
        }
      } else if (responseBody['error'] != null) {
        errorMessage = responseBody['error'].toString();
      }
    }

    throw ApiException(errorMessage, statusCode: response.statusCode);
  }
}
