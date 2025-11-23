import 'package:google_sign_in/google_sign_in.dart';
import '../config.dart';

class SocialAuthService {
  // GoogleSignIn is created lazily.
  GoogleSignIn? _googleSignIn;

  void _ensureGoogleSignIn() {
    final clientId = ConfigService.googleClientId;
    if (clientId == null || clientId.isEmpty) {
      throw Exception('Google client id not loaded. Ensure ConfigService.init() ran.');
    }
    // Ensure we have an instance
    _googleSignIn ??= GoogleSignIn(
      serverClientId: clientId,
      scopes: ['email', 'profile'],
    );
  }

  /// Triggers Google Sign-In and returns the ID token if successful.
  Future<String> signInWithGoogle() async {
    try {
      _ensureGoogleSignIn();
      
      // This will now show the account chooser because we disconnect on logout
      final account = await _googleSignIn!.signIn();
      
      if (account == null) {
        throw Exception('Google sign-in aborted by user');
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      
      if (idToken == null || idToken.isEmpty) {
        throw Exception('No ID token returned by Google. Check OAuth client configuration.');
      }
      return idToken;
    } catch (e) {
      throw Exception('Google sign-in failed: ${e.toString()}');
    }
  }

  /// Logs out AND Disconnects to force account selection next time
  Future<void> signOut() async {
    try {
      _ensureGoogleSignIn();
      
      // 1. Disconnect revokes the access token on the device.
      // This ensures the next time the user clicks "Continue with Google",
      // they see the account picker dialog.
      await _googleSignIn!.disconnect();
      
      // 2. Clear local google session
      await _googleSignIn!.signOut();
    } catch (e) {
      // If the user was not signed in to Google (e.g. regular email login),
      // disconnect might throw an error. We ignore it safely here.
      print('Google sign-out/disconnect error (safe to ignore): $e');
    }
  }
}