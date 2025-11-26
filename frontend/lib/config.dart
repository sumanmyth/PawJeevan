// Runtime configuration loader. Fetches non-secret values from the backend
// so they don't need to be checked into source control.
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'utils/constants.dart';

class ConfigService {
    static String? _googleClientId;

    /// Initialize the config service by fetching values from the backend.
    /// Uses `ApiConstants.baseUrl` to locate the API.
    static Future<void> init() async {
        try {
            final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
            final resp = await dio.get('/api/config/google/');
            final data = resp.data;
            if (data is Map && data['google_client_id'] != null) {
                _googleClientId = data['google_client_id'] as String;
            } else {
                _googleClientId = null;
            }
            // Log for dev visibility
            if (!kIsWeb) print('ConfigService: loaded google client id: ${_googleClientId != null}');
        } catch (e) {
            // Non-fatal: leave value null and allow app to handle missing config
            print('ConfigService.init() failed: $e');
            _googleClientId = null;
        }
    }

    /// Returns the Google OAuth client id or null if not loaded.
    static String? get googleClientId => _googleClientId;
}
