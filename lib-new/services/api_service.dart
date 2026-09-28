
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // static const String baseUrl = 'https://premerp.in/dvms/api';
  static const String baseUrl = 'http://103.168.210.85:4001/api';

  Future<dynamic> request(String method, String path, {Map<String,String>? query, dynamic body}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final headers = <String,String>{'Content-Type':'application/json','Accept':'application/json'};
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    late http.Response r;
    if (method == 'GET') r = await http.get(uri, headers: headers);
    else if (method == 'POST') r = await http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
    else if (method == 'PUT') r = await http.put(uri, headers: headers, body: jsonEncode(body ?? {}));
    else if (method == 'DELETE') r = await http.delete(uri, headers: headers);
    else throw Exception('Unsupported method');
    dynamic data;
    try { data = jsonDecode(r.body); } catch (_) { data = r.body; }
    if (r.statusCode < 200 || r.statusCode >= 300) {
      final msg = data is Map ? (data['error'] ?? data['message'] ?? 'Request failed') : 'Request failed';
      throw Exception('$msg (${r.statusCode})');
    }
    return data;
  }

  Future<dynamic> get(String path, {Map<String,String>? query}) => request('GET',path,query:query);
  Future<dynamic> post(String path, dynamic body) => request('POST',path,body:body);
  Future<dynamic> put(String path, dynamic body) => request('PUT',path,body:body);
  Future<dynamic> delete(String path) => request('DELETE',path);
}
