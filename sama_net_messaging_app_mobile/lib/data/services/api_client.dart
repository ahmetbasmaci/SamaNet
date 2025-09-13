import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// HTTP client wrapper for API communication
class ApiClient {
  final String baseUrl;
  final Map<String, String> _defaultHeaders;
  String? _authToken;
  String? _userId;

  ApiClient({required this.baseUrl, Map<String, String>? defaultHeaders})
    : _defaultHeaders = {'Content-Type': 'application/json', 'Accept': 'application/json', ...?defaultHeaders};

  /// Set authentication token
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Set user ID for X-User-Id header
  void setUserId(String? userId) {
    _userId = userId;
  }

  /// Create configured HttpClient with SSL handling
  HttpClient _createHttpClient() {
    final client = HttpClient();

    // Allow bad certificates in debug and profile modes for localhost development
    if (kDebugMode || kProfileMode) {
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Allow bad certificates for localhost or development servers
        return host == '10.0.2.2' || host == 'localhost' || host == '127.0.0.1' || host.contains('192.168.');
      };
    }

    return client;
  }

  /// Get headers with authentication token and user ID if available
  Map<String, String> get _headers {
    final headers = Map<String, String>.from(_defaultHeaders);
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (_userId != null) {
      headers['X-User-Id'] = _userId!;
    }
    return headers;
  }

  /// Perform GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final client = _createHttpClient();
      final uri = _buildUri(endpoint, queryParams);
      final request = await client.getUrl(uri);

      _headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      final response = await request.close();
      final responseBody = await _readResponse(response);
      client.close();

      return _handleResponse<T>(response.statusCode, responseBody, fromJson);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Perform POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Object? body,
    Map<String, String>? queryParams,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final client = _createHttpClient();
      final uri = _buildUri(endpoint, queryParams);
      final request = await client.postUrl(uri);

      _headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      if (body != null) {
        final bodyBytes = utf8.encode(json.encode(body));
        request.add(bodyBytes);
      }

      final response = await request.close();
      final responseBody = await _readResponse(response);
      client.close();

      return _handleResponse<T>(response.statusCode, responseBody, fromJson);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Perform PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Object? body,
    Map<String, String>? queryParams,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final client = _createHttpClient();
      final uri = _buildUri(endpoint, queryParams);
      final request = await client.putUrl(uri);

      _headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      if (body != null) {
        final bodyBytes = utf8.encode(json.encode(body));
        request.add(bodyBytes);
      }

      final response = await request.close();
      final responseBody = await _readResponse(response);
      client.close();

      return _handleResponse<T>(response.statusCode, responseBody, fromJson);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Perform multipart POST request for file uploads
  Future<ApiResponse<T>> postMultipart<T>(
    String endpoint, {
    required Map<String, String> fields,
    required String filePath,
    required String fileFieldName,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final client = _createHttpClient();
      final uri = _buildUri(endpoint, null);
      final request = await client.postUrl(uri);

      // Generate boundary for multipart data
      const boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW';
      request.headers.set('Content-Type', 'multipart/form-data; boundary=$boundary');

      // Add other headers except Content-Type
      final headers = Map<String, String>.from(_headers);
      headers.remove('Content-Type');
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      // Read file
      final file = File(filePath);
      final fileBytes = await file.readAsBytes();
      final fileName = file.path.split('/').last;

      // Build multipart body
      final List<int> body = [];

      // Add form fields
      for (final entry in fields.entries) {
        body.addAll(utf8.encode('--$boundary\r\n'));
        body.addAll(utf8.encode('Content-Disposition: form-data; name="${entry.key}"\r\n\r\n'));
        body.addAll(utf8.encode('${entry.value}\r\n'));
      }

      // Add file
      body.addAll(utf8.encode('--$boundary\r\n'));
      body.addAll(utf8.encode('Content-Disposition: form-data; name="$fileFieldName"; filename="$fileName"\r\n'));
      body.addAll(utf8.encode('Content-Type: application/octet-stream\r\n\r\n'));
      body.addAll(fileBytes);
      body.addAll(utf8.encode('\r\n'));

      // End boundary
      body.addAll(utf8.encode('--$boundary--\r\n'));

      request.add(body);

      final response = await request.close();
      final responseBody = await _readResponse(response);
      client.close();

      return _handleResponse<T>(response.statusCode, responseBody, fromJson);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Perform DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final client = _createHttpClient();
      final uri = _buildUri(endpoint, queryParams);
      final request = await client.deleteUrl(uri);

      _headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      final response = await request.close();
      final responseBody = await _readResponse(response);
      client.close();

      return _handleResponse<T>(response.statusCode, responseBody, fromJson);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Build URI with query parameters
  Uri _buildUri(String endpoint, Map<String, String>? queryParams) {
    final url = '$baseUrl$endpoint';
    final uri = Uri.parse(url);

    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }

    return uri;
  }

  /// Read response body
  Future<String> _readResponse(HttpClientResponse response) async {
    final contents = StringBuffer();
    await for (var data in response.transform(utf8.decoder)) {
      contents.write(data);
    }
    return contents.toString();
  }

  /// Handle HTTP response
  ApiResponse<T> _handleResponse<T>(int statusCode, String responseBody, T Function(dynamic)? fromJson) {
    try {
      final dynamic responseData = json.decode(responseBody);

      if (statusCode >= 200 && statusCode < 300) {
        // Success response
        if (fromJson != null) {
          final data = fromJson(responseData);
          return ApiResponse.success(data);
        } else {
          return ApiResponse.success(responseData as T);
        }
      } else {
        // Error response - handle both object and string responses
        String errorMessage;
        if (responseData is Map<String, dynamic>) {
          errorMessage = responseData['message'] ?? responseData['error'] ?? 'Request failed with status $statusCode';
        } else {
          errorMessage = responseData.toString();
        }
        return ApiResponse.error(errorMessage);
      }
    } catch (e) {
      return ApiResponse.error('Failed to parse response: ${e.toString()}');
    }
  }
}

/// API response wrapper
class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const ApiResponse._({this.data, this.error, required this.isSuccess});

  /// Create success response
  factory ApiResponse.success(T data) {
    return ApiResponse._(data: data, isSuccess: true);
  }

  /// Create error response
  factory ApiResponse.error(String error) {
    return ApiResponse._(error: error, isSuccess: false);
  }

  /// Check if response has data
  bool get hasData => isSuccess && data != null;

  /// Get data or throw exception
  T get requireData {
    if (!isSuccess || data == null) {
      throw Exception(error ?? 'No data available');
    }
    return data!;
  }
}
