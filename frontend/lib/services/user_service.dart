import '../models/user_model.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class UserService {
  final _api = ApiService();

  Future<List<User>> searchUsers(String query) async {
    final resp = await _api.get('${ApiConstants.users}?search=$query');
    if (resp.statusCode == 200) {
      final List data = resp.data is Map ? resp.data['results'] ?? [] : resp.data;
      return data.map((json) => User.fromJson(json)).toList();
    }
    throw Exception('Failed to search users');
  }
}