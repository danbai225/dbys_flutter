
import 'package:dbys/Page/LoginPage.dart';
import 'package:dbys/Page/RegPage.dart';
import 'package:dbys/Page/SearchPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'Page/MainPage.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '淡白影视',
      theme: ThemeData(
        primaryColor: Color(0xFF93b1c6),
        accentColor: Color(0xFFc7d0d5),
        buttonColor:Color(0xFFc7d0d5),
      ),
      home: BootAnimation(),
      routes: <String, WidgetBuilder>{
        '/MainPage': (BuildContext context) => new MainPage(),
        '/SearchPage': (BuildContext context) => new SearchPage(),
        '/LoginPage': (BuildContext context) => new LoginPage(),
        '/RegPage': (BuildContext context) => new RegPage(),
      },
    );
  }

}


class BootAnimation extends StatefulWidget {
  BootAnimation({Key key}) : super(key: key);
  @override
  _BootAnimation createState() => _BootAnimation();
}

class _BootAnimation extends State<BootAnimation>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Color xzColor = Colors.black;
  @override
  void initState() {
    super.initState();
    getSyData();
    var duration = new Duration(seconds: 3); //定义一个三秒种的时间
    new Future.delayed(duration, () {
      //设置定时执行
      goToHomePage();
    });
    _controller = new AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _controller.addListener(() {
      setState(() {
        print(_controller.value);
        if (_controller.value == 1) {
          xzColor = Colors.grey;
        }
      });
    });
    _controller.forward();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  // 重写build 方法，build 方法返回值为Widget类型，返回内容为屏幕上显示内容。
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          decoration: BoxDecoration(color: Colors.black),
          child: Center(
              child: Container(
            width: 200,
            height: 100,
            child: Column(
              children: <Widget>[
                Opacity(
                    opacity: _controller.value,
                    child: Text(
                      "淡白影视",
                      style: TextStyle(
                          fontSize: 36 * _controller.value,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    )),
                Text(
                  "看你想看",
                  style: TextStyle(fontSize: 16, color: xzColor),
                )
              ],
            ),
          ))),
    );
  }
  goToHomePage() {
    Navigator.of(context).pushReplacementNamed("/MainPage"); //执行跳转代码
  }

  //获取首页数据并存储
  getSyData() async {
    var response = await http.get("https://dbys.vip/sy");
    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    SharedPreferences prefs = await _prefs;
    prefs.setString("syData", response.body);
  }
}
