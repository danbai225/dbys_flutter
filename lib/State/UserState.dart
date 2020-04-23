import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class UserState {
  static String username;
  static String headUrl;
  static String token;
  static String email;
  static int userType;
  static bool ifLogin = false;
  static SharedPreferences prefs;

  static init() async {
    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    prefs = await _prefs;
    username = prefs.getString("UserNmae");
    token = prefs.getString("Token");
    var response = await http
        .get("https://dbys.vip/api/v1/user?token=$token&username=$username");
    var data = await jsonDecode(response.body);
    if (data['data'] == null) {
      prefs.remove("Token");
      prefs.remove("UserNmae");
      ifLogin = false;
    } else {
      email = data['data']['email'];
      headUrl = data['data']['headurl'];
      userType = data['data']['userType'];
      ifLogin = true;
    }
  }

  static exitLogin() {
    prefs.remove("Token");
    prefs.remove("UserNmae");
    ifLogin = false;
    username = null;
    headUrl = null;
    token = null;
    http.delete(
        "https://dbys.vip/api/v1/token?username=$username&=token=$token");
  }
}
