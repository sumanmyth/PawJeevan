import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    
      // Add interceptor to handle auth token and logging
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('API Request: ${options.method} ${options.uri}');
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
          print('API: Added auth token to request');
        } else {
          print('API: No auth token available');
        }
        print('API: Request headers: ${options.headers}');
        print('API: Request data: ${options.data}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('API Response: ${response.statusCode} for ${response.requestOptions.method} ${response.requestOptions.uri}');
        print('API: Response data: ${response.data}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('API Error: ${error.message}');
        print('API: Error details: ${error.response?.data}');
        return handler.next(error);
      },
    ));
    if (_debugLogging) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          responseHeader: false,
        ),
      );
    }
  }

  late Dio _dio;
  String? _token;
  final bool _debugLogging = true;

  static const String _kAccessToken = 'access_token';
  static const String _kRefreshToken = 'refresh_token';

  // Load persisted token at app start
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kAccessToken);
  }

  // Set token in memory
  void setToken(String? token) {
    _token = token;
  }

  // Persist token(s)
  Future<void> saveToken(String accessToken, {String? refreshToken}) async {
    _token = accessToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessToken, accessToken);
    if (refreshToken != null) {
      await prefs.setString(_kRefreshToken, refreshToken);
    }
  }

  // Clear tokens
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccessToken);
    await prefs.remove(_kRefreshToken);
  }

  // Helper to check if a token is currently present
  bool get hasToken => _token != null && _token!.isNotEmpty;

  Map<String, String> get _authHeaders => {
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Response> get(String endpoint, {Map<String, dynamic>? params}) async {
    try {
      return await _dio.get(
        endpoint,
        queryParameters: params,
        options: Options(headers: _authHeaders),
      );
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<Response> post(String endpoint, {dynamic data}) async {
    try {
      return await _dio.post(
        endpoint,
        data: data,
        options: Options(headers: _authHeaders),
      );
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<Response> put(String endpoint, {dynamic data}) async {
    try {
      return await _dio.put(
        endpoint,
        data: data,
        options: Options(headers: _authHeaders),
      );
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<Response> patch(String endpoint, {dynamic data}) async {
    try {
      return await _dio.patch(
        endpoint,
        data: data,
        options: Options(headers: _authHeaders),
      );
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<Response> delete(String endpoint) async {
    try {
      print('DELETE Request to: ${_dio.options.baseUrl}$endpoint');
      print('Headers: ${_authHeaders.toString()}');
      final response = await _dio.delete(
        endpoint,
        options: Options(headers: _authHeaders),
      );
      print('DELETE Response status: ${response.statusCode}');
      print('DELETE Response data: ${response.data}');
      return response;
    } catch (e) {
      print('DELETE Request failed with error: $e');
      if (e is DioException) {
        print('DioError type: ${e.type}');
        print('DioError message: ${e.message}');
        print('DioError response: ${e.response?.data}');
      }
      throw Exception(_handleError(e));
    }
  }

  String _handleError(dynamic error) {
    if (error is DioException) {
      final r = error.response;
      if (r != null) {
        final data = r.data;
        if (data is Map) {
          if (data['detail'] != null) return data['detail'].toString();
          final sb = StringBuffer();
          data.forEach((k, v) {
            if (v is List && v.isNotEmpty) {
              sb.writeln('$k: ${v.join(", ")}');
            } else {
              sb.writeln('$k: $v');
            }
          });
          final msg = sb.toString().trim();
          if (msg.isNotEmpty) return msg;
        }
        return 'Server error: ${r.statusCode}';
      }
      return 'Network error. Please check your connection.';
    }
    return 'Unexpected error';
  }
}