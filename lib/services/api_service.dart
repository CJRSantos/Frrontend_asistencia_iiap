import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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

  // MULTIPART Request (Upload image/file)
  static Future<dynamic> uploadMultipart(
    String url, {
    required String fileField,
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse(url);
      final request = http.MultipartRequest('POST', uri);

      if (requiresAuth) {
        final token = await StorageService.getToken();
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      MediaType? mediaType;
      String? ext;
      if (filePath != null && filePath.contains('.')) {
        ext = filePath.split('.').last.toLowerCase();
      } else if (fileName != null && fileName.contains('.')) {
        ext = fileName.split('.').last.toLowerCase();
      }

      if (ext != null) {
        switch (ext) {
          case 'jpg':
          case 'jpeg':
            mediaType = MediaType('image', 'jpeg');
            break;
          case 'png':
            mediaType = MediaType('image', 'png');
            break;
          case 'webp':
            mediaType = MediaType('image', 'webp');
            break;
          case 'gif':
            mediaType = MediaType('image', 'gif');
            break;
          case 'bmp':
            mediaType = MediaType('image', 'bmp');
            break;
          case 'heic':
          case 'heif':
            mediaType = MediaType('image', 'heic');
            break;
          default:
            mediaType = MediaType('image', ext);
        }
      } else {
        mediaType = MediaType('image', 'jpeg');
      }

      if (filePath != null && filePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          fileField,
          filePath,
          contentType: mediaType,
        ));
      } else if (fileBytes != null && fileBytes.isNotEmpty) {
        request.files.add(http.MultipartFile.fromBytes(
          fileField,
          fileBytes,
          filename: fileName ?? 'profile.jpg',
          contentType: mediaType,
        ));
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Error de conexión al subir el archivo.');
    } on http.ClientException {
      throw ApiException('Error de comunicación con el backend.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Ocurrió un error inesperado al subir la imagen: ${e.toString()}');
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
