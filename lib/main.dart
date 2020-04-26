import 'dart:convert';
import 'dart:io';

import 'package:cdnbye/cdnbye.dart';
import 'package:dbys/Page/LoginPage.dart';
import 'package:dbys/Page/RegPage.dart';
import 'package:dbys/Page/SearchPage.dart';
import 'package:dbys/State/UserState.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_page_tracker/flutter_page_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:volume/volume.dart';
import 'Page/Download/DownloadManagement.dart';
import 'Page/MainPage.dart';
import 'package:flutter_xupdate/flutter_xupdate.dart';

void main() => runApp(TrackerRouteObserverProvider(
      child: MyApp(),
    ));

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '淡白影视',
      theme: ThemeData(
        primaryColor: Color(0xFF93b1c6),
        accentColor: Color(0xFFc7d0d5),
        buttonColor: Color(0xFFc7d0d5),
      ),
      home: BootAnimation(),
      // 添加路由事件监听
      navigatorObservers: [TrackerRouteObserverProvider.of(context)],
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
  initState() {
    super.initState();
    //更新初始化
    initXUpdate();
    FlutterXUpdate.checkUpdate(
        url: 'https://dbys.vip/api/v1/update-flutter',
        supportBackgroundUpdate: true);
    //首页数据
    getSyData();
    //音量修改选择
    Volume.controlVolume(AudioManager.STREAM_MUSIC);
    //P2P初始化
    Cdnbye.init("_WJjufJZR", config: P2pConfig.byDefault());
    //登录初始化
    UserState.init();
    //下载器初始化
    DownloadManagement.init();
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
    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    SharedPreferences prefs = await _prefs;
    var response = await http.get("https://dbys.vip/sy");
    prefs.setString("syData", response.body);
    //获取公告
    response = await http.get("https://dbys.vip/api/v1/gg");
    var data = await jsonDecode(response.body);
    prefs.setString("gg", data['data']);
  }

  ///更新初始化
  void initXUpdate() {
    if (Platform.isAndroid) {
      FlutterXUpdate.init(

              ///是否输出日志
              debug: false,

              ///是否使用post请求
              isPost: false,

              ///post请求是否是上传json
              isPostJson: false,

              ///是否开启WIFI
              isWifiOnly: false,

              ///是否开启自动模式
              isAutoMode: false,

              ///需要设置的公共参数
              supportSilentInstall: false,

              ///在下载过程中，如果点击了取消的话，是否弹出切换下载方式的重试提示弹窗
              enableRetry: false)
          .then((value) {
        print("初始化成功: $value");
      }).catchError((error) {
        print(error);
      });
    } else {
      print("ios暂不支持XUpdate更新");
    }
  }
}
