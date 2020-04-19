import 'dart:convert';

import 'package:dbys/Socket/YiQiKanSocket.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

class RoomPage extends StatefulWidget{
  RoomPage({Key key,this.id,this.uid,this.channel,this.name,this.token}) : super(key: key);
  final int id;//房间id
  final int uid;//用户语音uid
  final String channel;//语音频道
  final String name;//房间名字
  final String token;//语音token
  @override
  _RoomState createState() => _RoomState();
}

class _RoomState extends State<RoomPage>{
  int online=0;
  String author="";
  List users=[];
  TimerUtil t; //房间定时器
  @override
  void initState() {
    super.initState();
    init();
  }
  init(){
    YiQiKanSocket.setRoomInfoCallBack(roomInfo);
    t=new TimerUtil();
    t.setInterval(1000);
    t.setOnTimerTickCallback((int tick) {
        YiQiKanSocket.send(jsonEncode({'type': 'roomInfo'}));
    });
    setState(() {
    });
    t.startTimer();
  }
  roomInfo(var data){
    setState(() {
      online=data['online'];
      author=data['author'];
      users=data['users'];
    });
  }
  @override
  void dispose() {
    super.dispose();
    t.cancel();
    YiQiKanSocket.send(jsonEncode({"type":"exitRoom"}));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          child: AppBar(
            title: Text("${widget.name}($online)"),
            centerTitle: true,
          ),
          preferredSize:
          Size.fromHeight(MediaQuery.of(context).size.height * 0.05),
        ),
        body: Center(
          child: Text(widget.name),
        )
    );
  }
}

