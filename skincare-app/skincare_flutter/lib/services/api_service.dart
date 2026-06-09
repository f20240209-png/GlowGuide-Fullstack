import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ingredient_conflict_model.dart';
import '../models/heatmap_day_model.dart';
import '../models/community_post_model.dart';

class ApiService {
  static const String baseUrl = 'https://glowguide-fullstack.onrender.com/api';

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

  // Ingredient conflict analysis
static Future<Map<String, dynamic>> analyzeIngredients(
    String token, List<String> ingredients) async {
  final response = await http.post(
    Uri.parse('$baseUrl/analyze-routine'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    },
    body: jsonEncode({'ingredients': ingredients}),
  );
  return jsonDecode(response.body);
}

/// Fetches the monthly heatmap data.
/// [month] is 1-based (1 = January … 12 = December).
static Future<Map<String, dynamic>> getMonthlyHeatmap(
  String token,
  int year,
  int month,
) async {
  final response = await http.get(
    Uri.parse('$baseUrl/logs/heatmap?year=$year&month=$month'),
    headers: {'Authorization': 'Bearer $token'},
  );

  final data = jsonDecode(response.body) as Map<String, dynamic>;

  if (response.statusCode == 200) {
    return {
      'heatmapData': (data['heatmapData'] as List)
          .map((d) => HeatmapDay.fromJson(d as Map<String, dynamic>))
          .toList(),
      'currentStreak': data['currentStreak'] as int,
    };
  }

  throw Exception(data['message'] ?? 'Failed to load heatmap');
}
static Future<Map<String, dynamic>> googleLogin(String idToken) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/google'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'idToken': idToken}),
  );
  return jsonDecode(response.body);
}

static Future<Map<String, dynamic>> firebaseLogin(
    String idToken, String email, String name) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/firebase-login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'idToken': idToken,
      'email': email,
      'name': name,
    }),
  );
  return jsonDecode(response.body);
}

static Future<Map<String, dynamic>> phoneLogin(
    String firebaseIdToken, {String? name}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/phone-login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'idToken': firebaseIdToken,
      if (name != null) 'name': name,
    }),
  );
  return jsonDecode(response.body);
}


  // ─── Community ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getCommunityPosts(
    String token, {
    int page = 1,
    String? category,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/community?page=$page${category != null ? '&category=$category' : ''}',
    );
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getMyPosts(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/community/my-posts'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getPostById(
    String token,
    int postId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/community/$postId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createPost(
    String token, {
    required String question,
    String? details,
    required String category,
    String? skinType,
    bool isAnonymous = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/community'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'question':    question,
        'details':     details,
        'category':    category,
        'skinType':    skinType,
        'isAnonymous': isAnonymous,
      }),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> answerPost(
    String token,
    int postId, {
    required String answer,
    bool isAnonymous = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/community/$postId/answer'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'answer': answer, 'isAnonymous': isAnonymous}),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<void> likePost(String token, int postId) async {
    await http.post(
      Uri.parse('$baseUrl/community/$postId/like'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<void> markAnswerHelpful(String token, int answerId) async {
    await http.post(
      Uri.parse('$baseUrl/community/answers/$answerId/helpful'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

}

