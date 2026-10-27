import 'package:voxora/core/network/api_client.dart';
import 'package:voxora/core/constants/api_constants.dart';
import 'package:voxora/data/models/user_model.dart';

class AuthProvider {
  final ApiClient _apiClient;

  AuthProvider(this._apiClient);

  /// Authenticates a user and returns the response data (tokens + user).
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    final body = response.data ?? {};
    if ((response.statusCode != null && response.statusCode! >= 400) ||
        body['success'] == false) {
      final msg = body['message']?.toString() ?? 'Invalid email or password';
      throw Exception(msg);
    }
    if (body['data'] is Map<String, dynamic>) {
      return {...body, ...body['data'] as Map<String, dynamic>};
    }
    return body;
  }

  /// Creates a new account and returns the response data.
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    String? phone,
    required String password,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.register,
      data: {
        'name': name,
        'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'password': password,
      },
    );
    final body = response.data ?? {};
    if ((response.statusCode != null && response.statusCode! >= 400) ||
        body['success'] == false) {
      final msg = body['message']?.toString() ?? 'Registration failed';
      throw Exception(msg);
    }
    if (body['data'] is Map<String, dynamic>) {
      return {...body, ...body['data'] as Map<String, dynamic>};
    }
    return body;
  }

  /// Authenticates a user with Google and returns tokens + user data.
  Future<Map<String, dynamic>> loginWithGoogle({
    required String email,
    required String name,
    String? googleId,
    String? avatarUrl,
    String? idToken,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.googleAuth,
      data: {
        'email': email,
        'name': name,
        if (googleId != null && googleId.isNotEmpty) 'googleId': googleId,
        if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatarUrl': avatarUrl,
        if (idToken != null && idToken.isNotEmpty) 'idToken': idToken,
      },
    );
    final body = response.data ?? {};
    if ((response.statusCode != null && response.statusCode! >= 400) ||
        body['success'] == false) {
      final msg = body['message']?.toString() ?? 'Google authentication failed';
      throw Exception(msg);
    }
    if (body['data'] is Map<String, dynamic>) {
      return {...body, ...body['data'] as Map<String, dynamic>};
    }
    return body;
  }

  /// Invalidates the current session on the server.
  Future<void> logout() async {
    await _apiClient.post<void>(ApiConstants.logout);
  }

  /// Exchanges a refresh token for a new access token.
  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.refresh,
      data: {'refresh_token': refreshToken},
    );
    return response.data ?? {};
  }

  /// Sends a password-reset email.
  Future<void> forgotPassword({required String email}) async {
    await _apiClient.post<void>(
      ApiConstants.forgotPassword,
      data: {'email': email},
    );
  }

  /// Fetches the authenticated user's profile.
  Future<UserModel> getMe() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.userMe,
    );
    return UserModel.fromJson(response.data ?? {});
  }

  /// Updates the authenticated user's profile.
  Future<UserModel> updateProfile({
    String? name,
    String? level,
    String? avatarUrl,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (level != null) payload['level'] = level;
    if (avatarUrl != null) payload['avatar_url'] = avatarUrl;

    final response = await _apiClient.patch<Map<String, dynamic>>(
      ApiConstants.userUpdate,
      data: payload,
    );
    final data = response.data ?? {};
    final userJson = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;
    return UserModel.fromJson(userJson);
  }
}
