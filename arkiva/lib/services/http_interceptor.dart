import 'package:http/http.dart' as http;

class HttpInterceptor {
  static Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    print('🌐 [HTTP] GET $url');
    print('🌐 [HTTP] Headers: $headers');
    
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      print('🌐 [HTTP] Response Status: ${response.statusCode}');
      print('🌐 [HTTP] Response Headers: ${response.headers}');
      print('🌐 [HTTP] Response Body (first 200 chars): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      
      if (response.statusCode >= 400) {
        print('❌ [HTTP] Error Response: ${response.body}');
      }
      
      return response;
    } catch (e) {
      print('❌ [HTTP] Exception: $e');
      rethrow;
    }
  }

  static Future<http.Response> post(String url, {Map<String, String>? headers, Object? body}) async {
    print('🌐 [HTTP] POST $url');
    print('🌐 [HTTP] Headers: $headers');
    print('🌐 [HTTP] Body: $body');
    
    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: body);
      print('🌐 [HTTP] Response Status: ${response.statusCode}');
      print('🌐 [HTTP] Response Headers: ${response.headers}');
      print('🌐 [HTTP] Response Body (first 200 chars): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      
      if (response.statusCode >= 400) {
        print('❌ [HTTP] Error Response: ${response.body}');
      }
      
      return response;
    } catch (e) {
      print('❌ [HTTP] Exception: $e');
      rethrow;
    }
  }
} 