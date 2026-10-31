import 'package:voxora/core/storage/local_storage.dart';
import 'package:voxora/data/models/user_model.dart';
import 'package:voxora/data/providers/auth_provider.dart';

class AuthRepository {
  final AuthProvider _authProvider;
  final LocalStorage _localStorage;

  AuthRepository(this._authProvider, this._localStorage);

  // ── Auth state ────────────────────────────────────

  /// Returns true if a valid access token is stored locally.
  Future<bool> get isLoggedIn async {
    final token = await _localStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  // ── Login ─────────────────────────────────────────

  /// Authenticates the user with [email] and [password].
  /// Persists tokens and user data on success.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final data = await _authProvider.login(email: email, password: password);

    final accessToken = data['access_token']?.toString() ?? '';
    final refreshToken = data['refresh_token']?.toString() ?? '';
    final userJson = data['user'] as Map<String, dynamic>?;

    if (accessToken.isEmpty) {
      throw Exception('Login failed: no access token returned.');
    }

    await _localStorage.saveToken(accessToken);
    if (refreshToken.isNotEmpty) {
      await _localStorage.saveRefreshToken(refreshToken);
    }

    final user = userJson != null
        ? UserModel.fromJson(userJson)
        : await _authProvider.getMe();

    await _localStorage.saveUser(user);
    return user;
  }

  // ── Register ──────────────────────────────────────

  /// Creates a new account and logs the user in.
  Future<UserModel> register({
    required String name,
    required String email,
    String? phone,
    required String password,
  }) async {
    final data = await _authProvider.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );

    final accessToken = data['access_token']?.toString() ?? '';
    final refreshToken = data['refresh_token']?.toString() ?? '';
    final userJson = data['user'] as Map<String, dynamic>?;

    if (accessToken.isEmpty) {
      throw Exception('Registration failed: no access token returned.');
    }

    await _localStorage.saveToken(accessToken);
    if (refreshToken.isNotEmpty) {
      await _localStorage.saveRefreshToken(refreshToken);
    }

    final user = userJson != null
        ? UserModel.fromJson(userJson)
        : await _authProvider.getMe();

    await _localStorage.saveUser(user);
    return user;
  }

  // ── Google Login ──────────────────────────────────

  /// Authenticates with Google and persists session tokens.
  Future<UserModel> loginWithGoogle({
    required String email,
    required String name,
    String? googleId,
    String? avatarUrl,
    String? idToken,
  }) async {
    final data = await _authProvider.loginWithGoogle(
      email: email,
      name: name,
      googleId: googleId,
      avatarUrl: avatarUrl,
      idToken: idToken,
    );

    final accessToken = data['access_token']?.toString() ?? '';
    final refreshToken = data['refresh_token']?.toString() ?? '';
    final userJson = data['user'] as Map<String, dynamic>?;

    if (accessToken.isEmpty) {
      throw Exception('Google login failed: no access token returned.');
    }

    await _localStorage.saveToken(accessToken);
    if (refreshToken.isNotEmpty) {
      await _localStorage.saveRefreshToken(refreshToken);
    }

    final user = userJson != null
        ? UserModel.fromJson(userJson)
        : await _authProvider.getMe();

    await _localStorage.saveUser(user);
    return user;
  }

  // ── Logout ────────────────────────────────────────

  /// Signs the user out, clearing all local session data.
  Future<void> logout() async {
    try {
      await _authProvider.logout();
    } catch (_) {
      // Best-effort server logout; always clear local state.
    }
    await _localStorage.clearAll();
  }

  // ── Forgot password & OTP verification ───────────────

  /// Sends a password-reset email with a 6-digit OTP to [email].
  Future<void> forgotPassword(String email) async {
    await _authProvider.forgotPassword(email: email);
  }

  /// Verifies the 6-digit OTP code sent to [email].
  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    return await _authProvider.verifyOtp(email: email, otp: otp);
  }

  /// Resets the user's password using the verified OTP.
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _authProvider.resetPassword(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );
  }

  // ── Cached user ───────────────────────────────────

  /// Returns the locally-cached [UserModel], or null if not available.
  Future<UserModel?> getCachedUser() async {
    return _localStorage.getUser();
  }

  /// Fetches the latest authenticated user profile from the backend.
  Future<UserModel> getMe() async {
    final user = await _authProvider.getMe();
    await _localStorage.saveUser(user);
    return user;
  }

  // ── Update Profile ─────────────────────────────────

  /// Updates user profile details in database and persists updated user locally.
  Future<UserModel> updateProfile({
    String? name,
    String? level,
    String? avatarUrl,
    String? bio,
    String? location,
  }) async {
    final user = await _authProvider.updateProfile(
      name: name,
      level: level,
      avatarUrl: avatarUrl,
      bio: bio,
      location: location,
    );
    await _localStorage.saveUser(user);
    return user;
  }

  // ── Update Level ───────────────────────────────────

  /// Updates user level in database and persists updated user locally.
  Future<UserModel> updateLevel(String level) async {
    final user = await _authProvider.updateProfile(level: level);
    await _localStorage.saveUser(user);
    return user;
  }
}
