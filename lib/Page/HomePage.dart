import 'dart:convert';

import 'package:dbys/module/YsImg.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List tuiJianYs = [];
  List dyList = [];
  List dsjList = [];
  List zyList = [];
  List dmList = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  fetchData() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    String syData = _prefs.getString("syData");
    var data;
    if (syData != null) {
      data = await jsonDecode(syData);
      _prefs.remove("syData");
    } else {
      // 请求接口
      var response = await http.get("https://dbys.vip/sy");
      data = await jsonDecode(response.body);
    }
    // 将接口返回数据转成json
    tuiJianYs = data['tj'];
    dyList = data['dy'];
    dsjList = data['dsj'];
    zyList = data['zy'];
    dmList = data['dm'];
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          child: AppBar(
              actions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.search),
                  // 如果有抽屉的话的就打开
                  onPressed: () {
                    Navigator.of(context).pushNamed("/SearchPage"); //执行跳转代码
                  },
                  // 显示描述信息
                  tooltip: "打开搜索",
                )
              ],
              centerTitle: true,
              title: Text("淡白影视"),
              // leading: ,
              // 现在标题前面的Widget，一般为一个图标按钮，也可以是任意Widget
              leading: Builder(
                builder: (BuildContext context) {
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    // 如果有抽屉的话的就打开
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    // 显示描述信息
                    tooltip: "打开菜单",
                  );
                },
              )),
          preferredSize:
              Size.fromHeight(MediaQuery.of(context).size.height * 0.05)),
      body: SingleChildScrollView(
          child: Column(
        children: <Widget>[
          Text("推荐影视",
              style: TextStyle(
                fontSize: 18,
              )),
          Container(
              height: 180,
              child: ListView(
                  // This next line does the trick.
                  scrollDirection: Axis.horizontal,
                  children: tuiJianYs
                      .map((ys) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 2.0),
                          child: YsImg(
                            url: ys['tp'],
                            pm: ys['pm'],
                            id: ys['id'],
                            zt: ys['zt'],
                          )))
                      .toList())),
          Text("最新电影",
              style: TextStyle(
                fontSize: 18,
              )),
          Container(
              height: 180,
              child: ListView(
                  // This next line does the trick.
                  scrollDirection: Axis.horizontal,
                  children: dyList
                      .map((ys) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 2.0),
                          child: YsImg(
                            url: ys['tp'],
                            pm: ys['pm'],
                            id: ys['id'],
                            zt: ys['zt'],
                          )))
                      .toList())),
          Text("最新电视剧",
              style: TextStyle(
                fontSize: 18,
              )),
          Container(
              height: 180,
              child: ListView(
                  // This next line does the trick.
                  scrollDirection: Axis.horizontal,
                  children: dsjList
                      .map((ys) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 2.0),
                          child: YsImg(
                            url: ys['tp'],
                            pm: ys['pm'],
                            id: ys['id'],
                            zt: ys['zt'],
                          )))
                      .toList())),
          Text("最新综艺",
              style: TextStyle(
                fontSize: 18,
              )),
          Container(
              height: 180,
              child: ListView(
                  // This next line does the trick.
                  scrollDirection: Axis.horizontal,
                  children: zyList
                      .map((ys) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 2.0),
                          child: YsImg(
                            url: ys['tp'],
                            pm: ys['pm'],
                            id: ys['id'],
                            zt: ys['zt'],
                          )))
                      .toList())),
          Text("最新动漫",
              style: TextStyle(
                fontSize: 18,
              )),
          Container(
              height: 180,
              child: ListView(
                  // This next line does the trick.
                  scrollDirection: Axis.horizontal,
                  children: dmList
                      .map((ys) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 2.0),
                          child: YsImg(
                            url: ys['tp'],
                            pm: ys['pm'],
                            id: ys['id'],
                            zt: ys['zt'],
                          )))
                      .toList())),
        ],
      )),
    );
  }
}
