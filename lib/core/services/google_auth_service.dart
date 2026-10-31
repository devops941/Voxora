import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthResult {
  final String email;
  final String name;
  final String? googleId;
  final String? avatarUrl;
  final String? idToken;

  const GoogleAuthResult({
    required this.email,
    required this.name,
    this.googleId,
    this.avatarUrl,
    this.idToken,
  });
}

class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();

  GoogleSignIn? _googleSignIn;

  GoogleSignIn get _client {
    if (_googleSignIn != null) return _googleSignIn!;

    // Optional serverClientId (Web Client ID) from .env
    final serverClientId = dotenv.env['GOOGLE_CLIENT_ID'] ??
        dotenv.env['GOOGLE_WEB_CLIENT_ID'] ??
        dotenv.env['GOOGLE_SERVER_CLIENT_ID'];

    _googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: serverClientId?.isNotEmpty == true ? serverClientId : null,
    );
    return _googleSignIn!;
  }

  /// Triggers the native Google Account selection flow.
  /// Returns null if the user cancels or dismisses the account picker.
  Future<GoogleAuthResult?> signIn() async {
    try {
      // Disconnect or sign out first to ensure account picker opens fresh every time
      try {
        await _client.signOut();
      } catch (_) {}

      final GoogleSignInAccount? account = await _client.signIn();
      if (account == null) {
        // User cancelled the sign-in flow
        debugPrint('Google Sign-In was cancelled by the user.');
        return null;
      }

      final GoogleSignInAuthentication auth = await account.authentication;

      return GoogleAuthResult(
        email: account.email,
        name: account.displayName ?? account.email.split('@').first,
        googleId: account.id,
        avatarUrl: account.photoUrl,
        idToken: auth.idToken,
      );
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Signs out from Google
  Future<void> signOut() async {
    try {
      await _client.signOut();
    } catch (_) {}
  }
}
