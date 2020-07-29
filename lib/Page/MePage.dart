import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dbys/State/UserState.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_page_tracker/flutter_page_tracker.dart';
import 'package:http/http.dart' as http;

import 'YsPage.dart';

class MePage extends StatefulWidget {
  MePage({Key key}) : super(key: key);

  @override
  _MeState createState() => _MeState();
}

class _MeState extends State<MePage> with PageTrackerAware, TrackerPageMixin {
  List gkls = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didPageView() {
    super.didPageView();
    ini();
    // 发送页面露出事件
  }

  @override
  void didPageExit() {
    super.didPageExit();
    // 发送页面离开事件
  }

  ini() async {
    if (UserState.ifLogin) {
      var response = await http.get(
          "https://dbys.vip/api/v1/user/gkls?username=${UserState.username}&token=${UserState.token}&sole=true");
      var data = await jsonDecode(response.body);
      gkls = data['data'];
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          child: AppBar(
            title: Text("关于我"),
            centerTitle: true,
          ),
          preferredSize: Size.fromHeight(40),
        ),
        body: Column(children: <Widget>[
          Card(
              elevation: 20,
              margin: EdgeInsets.all(20.0),
              child: Center(
                child: SizedBox(
                  width: 300.0,
                  height: 140.0,
                  child: Column(
                    children: <Widget>[
                      CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(UserState.headUrl ==
                                  null
                              ? "http://danbai.oss-cn-chengdu.aliyuncs.com/img/2019/12/06/3027a00827e93.png"
                              : UserState.headUrl)),
                      Text(
                        UserState.ifLogin ? UserState.username : "未登录",
                        style: TextStyle(fontSize: 20),
                      ),
                      Row(
                        children: UserState.ifLogin
                            ? <Widget>[
                                Text("账号类型:"),
                                Container(
                                    width: 80,
                                    child: Text(
                                      UserState.userType == 1 ? "普通用户" : "管理员",
                                      overflow: TextOverflow.ellipsis,
                                    )),
                                Container(
                                    height: 20,
                                    child: VerticalDivider(color: Colors.grey)),
                                Text("邮箱:"),
                                Container(
                                    width: 80,
                                    child: Text(
                                      UserState.email,
                                      overflow: TextOverflow.ellipsis,
                                    )),
                              ]
                            : [],
                      ),
                      Row(
                        children: <Widget>[Text("")],
                      )
                    ],
                  ),
                ),
              )),
          Text("观看历史"),
          Divider(height:10.0,indent:0.0,color: Colors.blue,),
          Expanded(
            child: UserState.ifLogin
                ? Card(
                    elevation: 20,
                    margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: ListView(
                        children: gkls
                            .map((ls) => GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => YsPage(
                                        id: ls['id'],
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                    margin: EdgeInsets.all(2.0),
                                    child: Row(
                                      children: <Widget>[
                                        Container(
                                          width: 80,
                                          child: CachedNetworkImage(
                                            imageUrl: ls['ysimg'],
                                            placeholder: (context, url) =>
                                                Image.asset(
                                                    "assets/img/zw.png"),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Image.asset(
                                                        "assets/img/zw.png"),
                                          ),
                                        ),
                                        Column(
                                          children: <Widget>[
                                            Container(
                                              width: 200,
                                              child: Text(ls['pm'],
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w100,
                                                    fontSize: 16,
                                                  ),
                                                  textAlign: TextAlign.left),
                                            ),
                                            Container(
                                              width: 200,
                                              child: Text('观看集数:' + ls['ji'],
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey),
                                                  textAlign: TextAlign.left),
                                            ),
                                            Container(
                                              width: 200,
                                              child: Text('时长:' + ls['time'],
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey),
                                                  textAlign: TextAlign.left),
                                            ),
                                            Container(
                                                width: 200,
                                                child: Text(
                                                    '观看时间:' + ls['gktime'],
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey),
                                                    textAlign: TextAlign.left,
                                                    maxLines: 2))
                                          ],
                                        ),
                                      ],
                                    ))))
                            .toList()),
                  )
                : Center(
                    child: Container(
                        height: 200,
                        child: Column(children: <Widget>[
                          Text(
                            "观看历史需要登录后才能正常使用!",
                            textScaleFactor: 1.5,
                          ),
                          RaisedButton(
                            elevation: 5,
                            child: Text("登录"),
                            onPressed: () {
                              Navigator.of(this.context)
                                  .pushNamed("/LoginPage"); //执行跳转代码
                            },
                          ),
                          RaisedButton(
                            elevation: 5,
                            child: Text("注册"),
                            onPressed: () {
                              Navigator.of(this.context)
                                  .pushNamed("/RegPage"); //执行跳转代码
                            },
                          ),
                          RaisedButton(
                            elevation: 5,
                            child: Text("找回密码"),
                            onPressed: () {
                              Navigator.of(this.context)
                                  .pushNamed("/RetrievePassPage"); //执行跳转代码
                            },
                          )
                        ]))),
          )
        ]));
  }
}
