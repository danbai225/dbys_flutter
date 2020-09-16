import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dbys/Page/YiQIkan/RoomPage.dart';
import 'package:dbys/Socket/YiQiKanSocket.dart';
import 'package:dbys/State/UserState.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';
import 'package:flutter_page_tracker/flutter_page_tracker.dart';
import 'MainPage.dart';

class YiQiKanPage extends StatefulWidget {
  YiQiKanPage({Key key}) : super(key: key);

  @override
  _YiQiKanPageState createState() => _YiQiKanPageState();
}

class _YiQiKanPageState extends State<YiQiKanPage>
    with PageTrackerAware, TrackerPageMixin {
  String username;
  String token;
  TimerUtil t; //房间定时器
  int online = 0;
  List roomList = [];
  final columns = ['房间名', '房间人数', '密码', '加入'];
  String dUrl;
  TextEditingController _passController = new TextEditingController(); //密码输入
  TextEditingController _nameController = new TextEditingController(); //房间名输入
  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    t = TimerUtil();
    t.setInterval(1000);
    t.setOnTimerTickCallback((int tick) {
      if (UserState.ifLogin && !YiQiKanSocket.onConn) {
        conn();
      }
      if (MainPage.index == 2 && UserState.ifLogin && YiQiKanSocket.onConn) {
        YiQiKanSocket.send(jsonEncode({'type': 'info'}));
      }
      setState(() {});
    });
    //登录就连接
    if (UserState.ifLogin) {
      conn();
    }
  }

  void conn() {
    YiQiKanSocket.conn();
    YiQiKanSocket.setRoomListInfoCallBack(roomInfo);
    YiQiKanSocket.setJoinCallBack(join);
    t.startTimer();
  }

  roomInfo(data) {
    online = data['online'];
    roomList = data['rooms'];
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    YiQiKanSocket.close();
  }

  @override
  void didPageView() {
    super.didPageView();
    if (t != null && !t.isActive()) {
      t.startTimer();
    }
    // 发送页面露出事件
  }

  @override
  void didPageExit() {
    super.didPageExit();
    // 发送页面离开事件
    if (t != null && t.isActive()) {
      t.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          child: AppBar(
            title: Text("一起看($online)"),
            centerTitle: true,
          ),
          preferredSize: Size.fromHeight(40),
        ),
        body: !UserState.ifLogin
            ? Center(
                child: Container(
                    height: 200,
                    child: Column(children: <Widget>[
                      Text(
                        "请先登录哦!",
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
                    ])))
            : Column(children: [roomList.length>0?SingleChildScrollView(
          child: Container(
            alignment: Alignment.topCenter,
            child: DataTable(
              columnSpacing: 0,
              columns:
              columns.map((e) => DataColumn(label: Text(e))).toList(),
              rows: roomList
                  .map((room) => DataRow(cells: [
                DataCell(Text(
                  '${room['name'].toString().length > 15 ? room['name'].toString().substring(0, 15) : room['name']}',
                )),
                DataCell(Text('${room['online']}')),
                DataCell(room['needPass']
                    ? Icon(Icons.lock_outline)
                    : Icon(Icons.lock_open)),
                DataCell(RaisedButton(
                  child: Text('加入'),
                  onPressed: () {
                    if (room['needPass']) {
                      showInputPass(room['id']);
                    } else {
                      joinRoom(room['id'], "");
                    }
                  },
                ))
              ]))
                  .toList(),
            ),
          ),
        ):Center(child: Text("没有房间,快去创建房间,一起看!",textScaleFactor: 1.2,),),Container(width: 266,child: Image.asset("assets/img/Derwm.png"),)],),
        floatingActionButton: !UserState.ifLogin
            ? null
            : FloatingActionButton(
                heroTag: "yiqikan",
                elevation: 10,
                child: Icon(
                  Icons.add,
                ),
                onPressed: () {
                  newRoom();
                },
                tooltip: "新建房间",
              ));
  }

  join(data) {
    if (data['ok']) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoomPage(
            id: int.parse(data['id']),
            uid: data['uid'],
            channel: data['channel'],
            name: data['name'],
            token: data['token'],
          ),
        ),
      );
    } else {
      Dialog();
    }
  }

  joinRoom(int id, String pass) {
    YiQiKanSocket.send(
        jsonEncode({"type": "join", "roomId": id, "pass": pass}));
  }

  sendNewRoom(String name, String pass) {
    _nameController.text = "";
    _passController.text = "";
    YiQiKanSocket.send(
        jsonEncode({"type": "newRoom", "name": name, "pass": pass}));
  }

  newRoom() {
    YYDialog().build(context)
      ..width = 220
      ..borderRadius = 4.0
      ..widget(Column(
        children: <Widget>[
          Text("创建房间"),
          Container(
            height: 60,
            child: Padding(
              padding: EdgeInsets.all(10),
              child: TextField(
                controller: _nameController,
                style: TextStyle(color: Colors.blue),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '房间名',
                ),
                onEditingComplete: () {
                  sendNewRoom(_nameController.text, _passController.text);
                  _nameController.text = "";
                },
              ),
            ),
          ),
          Container(
            height: 60,
            child: Padding(
              padding: EdgeInsets.all(10),
              child: TextField(
                controller: _passController,
                style: TextStyle(color: Colors.blue),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '密码(不要可留空)',
                ),
                onEditingComplete: () {
                  sendNewRoom(_nameController.text, _passController.text);
                  _nameController.text = "";
                },
              ),
            ),
          )
        ],
      ))
      ..divider()
      ..doubleButton(
        padding: EdgeInsets.only(top: 10.0),
        gravity: Gravity.center,
        withDivider: true,
        text1: "取消",
        fontSize1: 14.0,
        fontWeight1: FontWeight.bold,
        text2: "确定",
        fontSize2: 14.0,
        fontWeight2: FontWeight.bold,
        onTap2: () {
          sendNewRoom(_nameController.text, _passController.text);
          _nameController.text = "";
        },
      )
      ..show();
  }

  void showInputPass(int id) {
    YYDialog().build(context)
      ..width = 220
      ..borderRadius = 4.0
      ..widget(Column(
        children: <Widget>[
          Text("加入此房间需要密码"),
          Container(
            height: 70,
            child: Padding(
              padding: EdgeInsets.all(10),
              child: TextField(
                controller: _passController,
                style: TextStyle(color: Colors.blue),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '密码',
                ),
                onEditingComplete: () {
                  joinRoom(id, _passController.text);
                  _passController.text = "";
                },
              ),
            ),
          )
        ],
      ))
      ..divider()
      ..doubleButton(
        padding: EdgeInsets.only(top: 10.0),
        gravity: Gravity.center,
        withDivider: true,
        text1: "取消",
        fontSize1: 14.0,
        fontWeight1: FontWeight.bold,
        text2: "确定",
        fontSize2: 14.0,
        fontWeight2: FontWeight.bold,
        onTap2: () {
          joinRoom(id, _passController.text);
          _passController.text = "";
        },
      )
      ..show();
  }

  showPassErrDialog() {
    YYDialog().build(context)
      ..width = 120
      ..height = 110
      ..backgroundColor = Colors.black.withOpacity(0.5)
      ..borderRadius = 10.0
      ..widget(Padding(
        padding: EdgeInsets.only(top: 21),
        child: Image.asset(
          "assets/img/err.gif",
          width: 40,
          height: 40,
        ),
      ))
      ..widget(Padding(
        padding: EdgeInsets.only(top: 10),
        child: Text(
          "房间密码错误",
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ))
      ..animatedFunc = (child, animation) {
        return ScaleTransition(
          child: child,
          scale: Tween(begin: 0.0, end: 1.0).animate(animation),
        );
      }
      ..show();
  }
}
