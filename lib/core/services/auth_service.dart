import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isGuest = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isGuest => _isGuest;

  AuthService() {
    _initAuthListener();
  }

  void _initAuthListener() {
    final client = SupabaseConfig.client;
    if (client != null) {
      _currentUser = client.auth.currentUser;
      client.auth.onAuthStateChange.listen((data) {
        _currentUser = data.session?.user;
        if (_currentUser != null) {
          _isGuest = false;
        }
        notifyListeners();
      });
    }
  }

  void continueAsGuest() {
    _isGuest = true;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser?.authentication;

      if (googleAuth?.idToken != null) {
        final client = SupabaseConfig.client;
        if (client != null) {
          final res = await client.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: googleAuth!.idToken!,
            accessToken: googleAuth.accessToken,
          );
          _currentUser = res.user;
          _isGuest = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('[AuthService] Google Sign In Exception: $e');
    }
    return false;
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await SupabaseConfig.client?.auth.signOut();
      _currentUser = null;
      _isGuest = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[AuthService] Sign out error: $e');
    }
  }
}
