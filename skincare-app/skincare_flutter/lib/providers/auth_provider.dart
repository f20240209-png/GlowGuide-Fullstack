import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _userName;
  bool _isLoading = false;

  String? get token => _token;
  String? get userName => _userName;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _userName = prefs.getString('userName');
    notifyListeners();
  }

  Future<String?> register(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await ApiService.register(name, email, password);
      if (data['token'] != null) {
        await _saveSession(data);
        return null;
      }
      return data['message'];
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await ApiService.login(email, password);
      if (data['token'] != null) {
        await _saveSession(data);
        return null;
      }
      return data['message'];
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

Future<String?> signInWithGoogle() async {
  _isLoading = true;
  notifyListeners();
  try {
    // Check if running on web
    if (kIsWeb) {
      // Web — use popup
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      UserCredential userCredential;
      try {
        userCredential = await FirebaseAuth.instance
            .signInWithPopup(googleProvider);
      } catch (e) {
        await FirebaseAuth.instance.signInWithRedirect(googleProvider);
        userCredential =
            await FirebaseAuth.instance.getRedirectResult();
      }

      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) return 'Failed to get ID token';

      final data = await ApiService.googleLogin(idToken);
      if (data['token'] != null) {
        await _saveSession(data);
        return null;
      }
      return data['message'] ?? 'Google login failed';

    } else {
      // Android/iOS — use google_sign_in package
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return 'Google sign in cancelled';

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) return 'Failed to get ID token';

      final data = await ApiService.googleLogin(idToken);
      if (data['token'] != null) {
        await _saveSession(data);
        return null;
      }
      return data['message'] ?? 'Google login failed';
    }
  } catch (e) {
    debugPrint('Google sign in error: $e');
    return e.toString();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  Future<void> _saveSession(Map<String, dynamic> data) async {
    _token = data['token'];
    _userName = data['user']['name'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    await prefs.setString('userName', _userName!);
    notifyListeners();
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    _token = null;
    _userName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
  Future<Map<String, dynamic>> phoneLoginWithToken(
    String idToken, {String? name}) async {
  _isLoading = true;
  notifyListeners();
  try {
    debugPrint('Calling phoneLogin API...');
    debugPrint('Base URL: ${ApiService.baseUrl}');
    final data = await ApiService.phoneLogin(idToken, name: name);
    debugPrint('API response: $data');
    if (data['token'] != null) {
      await _saveSession(data);
    }
    return data;
  } catch (e) {
    debugPrint('phoneLoginWithToken error: $e');
    return {'error': e.toString(), 'message': e.toString()};
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
}


