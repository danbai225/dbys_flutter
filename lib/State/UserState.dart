import 'dart:convert';

import 'package:dbys/Socket/YiQiKanSocket.dart';
import 'package:flustars/flustars.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserState {
  static String username;
  static String headUrl;
  static String token;
  static String email;
  static int userType;
  static bool ifLogin = false;

  static init() async {
    if(SpUtil.isInitialized()){
      username = SpUtil.getString("UserNmae");
      token = SpUtil.getString("Token");
    }else{
      Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
      SharedPreferences prefs = await _prefs;
      username = prefs.getString("UserNmae");
      token = prefs.getString("Token");
    }

    var response = await http
        .get("https://dbys.vip/api/v1/user?token=$token&username=$username");
    var data = await jsonDecode(response.body);
    if (data['data'] == null) {
      SpUtil.remove("Token");
      SpUtil.remove("UserNmae");
      ifLogin = false;
    } else {
      email = data['data']['email'];
      headUrl = data['data']['headurl'];
      userType = data['data']['userType'];
      ifLogin = true;
    }
  }

  static exitLogin() {
    YiQiKanSocket.close();
    SpUtil.remove("Token");
    SpUtil.remove("UserNmae");
    ifLogin = false;
    username = null;
    headUrl = null;
    token = null;
    http.delete(
        "https://dbys.vip/api/v1/token?username=$username&=token=$token");
  }
}
