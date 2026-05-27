import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  // Auth
  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  // Profile
  static Future<Map<String, dynamic>> createProfile(String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/profile'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateProfile(String token, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  // Product search
  static Future<Map<String, dynamic>> searchProducts(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile/search-products?query=$query'),
    );
    return jsonDecode(response.body);
  }

  // Recommendations
  static Future<Map<String, dynamic>> getRecommendations(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/recommendations'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> refreshRecommendations(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/recommendations/refresh'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  // Skincare logs
  static Future<Map<String, dynamic>> createSkincareLog(String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/logs'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getSkincareLogs(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/logs'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }
}