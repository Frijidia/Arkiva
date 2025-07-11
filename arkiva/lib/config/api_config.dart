import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    // Temporairement, utiliser l'IP pour tous les cas
    // return 'http://192.168.100.112:3000';
    return 'http://localhost:3000';
    // Code original (à remettre plus tard)
    // if (Platform.isAndroid || Platform.isIOS) {
    //   return 'http://192.168.100.112:3000';
    // } else {
    //   return 'http://localhost:3000';
    // }
  }

  static Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
} 