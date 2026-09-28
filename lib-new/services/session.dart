
import 'package:shared_preferences/shared_preferences.dart';
class Session { static Future<void> logout() async { final p=await SharedPreferences.getInstance(); await p.clear(); } }
