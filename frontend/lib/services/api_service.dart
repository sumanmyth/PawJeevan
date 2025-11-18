import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';
import '../models/group_model.dart';

class ApiService {
  static Future<List<Group>> fetchGroups() async {
    final dio = Dio();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.groups}',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    final data = response.data;
    if (data is List) {
      return data.map<Group>((g) => Group.fromJson(g)).toList();
    } else if (data is Map && data['results'] is List) {
      return (data['results'] as List).map<Group>((g) => Group.fromJson(g)).toList();
    }
    return [];
  }
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  static Future<Map<String, dynamic>> createGroup(Map<String, dynamic> groupData) async {
    try {
      final dio = Dio();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final formData = FormData();
      formData.fields.add(MapEntry('name', groupData['name']));
      formData.fields.add(MapEntry('description', groupData['description']));
      formData.fields.add(MapEntry('group_type', groupData['group_type']));
      formData.fields.add(MapEntry('is_private', groupData['is_private'].toString()));
      formData.fields.add(MapEntry('slug', groupData['slug']));
      
      if (groupData['join_key'] != null && groupData['join_key'].toString().isNotEmpty) {
        formData.fields.add(MapEntry('join_key', groupData['join_key']));
      }

      if (groupData['cover_image'] != null && groupData['cover_image'] is XFile) {
        final XFile imageFile = groupData['cover_image'];
        final bytes = await imageFile.readAsBytes();
        formData.files.add(
          MapEntry(
            'cover_image',
            MultipartFile.fromBytes(
              bytes,
              filename: imageFile.name,
            ),
          ),
        );
      }

      final response = await dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.groups}',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to create group: ${e.response?.data ?? e.message}');
    }
  }

  static Future<void> deleteGroup(String slug) async {
    final dio = Dio();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    await dio.delete(
      '${ApiConstants.baseUrl}${ApiConstants.groups}$slug/',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
  }

  static Future<Map<String, dynamic>> updateGroup(String slug, Map<String, dynamic> groupData) async {
    try {
      final dio = Dio();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final formData = FormData();
      formData.fields.add(MapEntry('name', groupData['name']));
      formData.fields.add(MapEntry('description', groupData['description']));
      formData.fields.add(MapEntry('group_type', groupData['group_type']));
      formData.fields.add(MapEntry('is_private', groupData['is_private'].toString()));
      formData.fields.add(MapEntry('is_active', groupData['is_active'].toString()));
      
      if (groupData['join_key'] != null && groupData['join_key'].toString().isNotEmpty) {
        formData.fields.add(MapEntry('join_key', groupData['join_key']));
      }

      if (groupData['cover_image'] != null && groupData['cover_image'] is XFile) {
        final XFile imageFile = groupData['cover_image'];
        final bytes = await imageFile.readAsBytes();
        formData.files.add(
          MapEntry(
            'cover_image',
            MultipartFile.fromBytes(
              bytes,
              filename: imageFile.name,
            ),
          ),
        );
      }

      final response = await dio.put(
        '${ApiConstants.baseUrl}${ApiConstants.groups}$slug/',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to update group: ${e.response?.data ?? e.message}');
    }
  }

  static Future<void> joinGroup(String slug, {String? joinKey}) async {
    final dio = Dio();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final data = <String, dynamic>{};
    if (joinKey != null && joinKey.isNotEmpty) {
      data['join_key'] = joinKey;
    }

    await dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.groups}$slug/join/',
      data: data,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
  }

  static Future<void> leaveGroup(String slug) async {
    final dio = Dio();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    await dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.groups}$slug/leave/',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
  }

  late String? _refreshToken;
  bool _isRefreshing = false;

  Future<bool> _refreshAuthToken() async {
    if (_isRefreshing) return false;
    
    try {
      _isRefreshing = true;
      final prefs = await SharedPreferences.getInstance();
      _refreshToken = prefs.getString('refresh_token');
      
      if (_refreshToken == null) {
        print('No refresh token available');
        return false;
      }

      final response = await Dio().post(
        '${ApiConstants.baseUrl}/api/users/token/refresh/',
        data: {'refresh': _refreshToken},
      );

      if (response.statusCode == 200) {
        final newToken = response.data['access'];
        await saveToken(newToken, refreshToken: _refreshToken);
        return true;
      }
      return false;
    } catch (e) {
      print('Token refresh failed: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

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
      onRequest: (options, handler) async {
        print('API Request: ${options.method} ${options.uri}');
        final prefs = await SharedPreferences.getInstance();
        _token = prefs.getString('token');
        
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
      onError: (error, handler) async {
        print('API Error: ${error.message}');
        print('API: Error details: ${error.response?.data}');
        
        // Check if error is due to token expiration
        if (error.response?.statusCode == 401 &&
            error.response?.data is Map &&
            error.response?.data['code'] == 'token_not_valid') {
          
          // Try to refresh the token
          final refreshed = await _refreshAuthToken();
          if (refreshed) {
            // Retry the original request with new token
            final prefs = await SharedPreferences.getInstance();
            _token = prefs.getString('token');
            
            if (_token != null) {
              error.requestOptions.headers['Authorization'] = 'Bearer $_token';
              final opts = Options(
                method: error.requestOptions.method,
                headers: error.requestOptions.headers,
              );
              
              try {
                final response = await _dio.request(
                  error.requestOptions.path,
                  options: opts,
                  data: error.requestOptions.data,
                  queryParameters: error.requestOptions.queryParameters,
                );
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }
          }
        }
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



  // Load persisted token at app start
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  // Set token in memory
  void setToken(String? token) {
    _token = token;
  }

  // Persist token(s)
  Future<void> saveToken(String token, {String? refreshToken}) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    if (refreshToken != null) {
      _refreshToken = refreshToken;
      await prefs.setString('refresh_token', refreshToken);
    }
  }

  Future<void> clearTokens() async {
    _token = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refresh_token');
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