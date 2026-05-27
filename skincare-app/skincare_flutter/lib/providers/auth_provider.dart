import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

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
        _token = data['token'];
        _userName = data['user']['name'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('userName', _userName!);
        notifyListeners();
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
        _token = data['token'];
        _userName = data['user']['name'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('userName', _userName!);
        notifyListeners();
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

  Future<void> logout() async {
    _token = null;
    _userName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}