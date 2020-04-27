import 'dart:async';
import 'dart:convert';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:dbys/module/CustomControls.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cdnbye/cdnbye.dart';
import 'package:chewie/chewie.dart';
import 'package:dbys/Socket/YiQiKanSocket.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

class RoomPage extends StatefulWidget {
  RoomPage({Key key, this.id, this.uid, this.channel, this.name, this.token})
      : super(key: key);
  final int id; //房间id
  final int uid; //用户语音uid
  final String channel; //语音频道
  final String name; //房间名字
  final String token; //语音token
  @override
  _RoomState createState() => _RoomState();
}

class _RoomState extends State<RoomPage> with SingleTickerProviderStateMixin {
  int online = 0;
  String author = "";
  List users = [];
  String url;
  double time;
  TimerUtil t; //房间定时器
  String username;
  VideoPlayerController _videoPlayerController;
  ChewieController _chewieController;
  final tabs = ['聊天', '在线用户', '选择影视', '语音设置'];
  TabController _tabController;
  List chatList = []; //聊天消息列表
  TextEditingController _chatController = new TextEditingController(); //聊天控制
  ScrollController _chatListController = ScrollController();
  TextEditingController _searchController = new TextEditingController(); //搜索控制
  List userList = [];
  List ySList = [];
  List playList = [];
  YYDialog jiDialog;
  static final _usersYuYin = <int>[];
  bool muted = false;
  String agora_APP_ID = "02e8df44f24e4da5b2e17ef1d8b755bd";
  int playbackSignalVolume = 200; //语音接收
  int recordingSignalVolume = 50; //麦克风音量
  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: tabs.length);
    init();
  }

  _initController(String link) {
    _videoPlayerController = VideoPlayerController.network(link)
      ..initialize().then((_) {
        _chewieController = ChewieController(
            customControls: CustomControls(),
            allowedScreenSleep: false,
            videoPlayerController: _videoPlayerController,
            aspectRatio: _videoPlayerController.value.aspectRatio,
            autoPlay: true,
            looping: true);
        setState(() {});
      });
  }

  //加载视频
  _loadVideo(String url) async {
    Fluttertoast.showToast(
        msg: "视频加载中请稍后",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Theme.of(context).accentColor,
        textColor: Colors.white,
        fontSize: 16.0);
    url = await Cdnbye.parseStreamURL(url);
    if (_videoPlayerController == null) {
      // If there was no controller, just create a new one
      _initController(url);
    } else {
      // If there was a controller, we need to dispose of the old one first
      final oldController = _videoPlayerController;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await oldController.dispose();
      });
      // Making sure that controller is not used by setting it to null
      setState(() {
        _videoPlayerController = null;
        _initController(url);
      });
    }
    setState(() {});
  }

  init() async {
    //设置webSocket回调
    YiQiKanSocket.setRoomInfoCallBack(roomInfo);
    YiQiKanSocket.setSendChatCallBack(sendChat);
    username = SpUtil.getString("UserNmae");
    //定时获取房间信息
    t = new TimerUtil();
    t.setInterval(1000);
    t.setOnTimerTickCallback((int tick) {
      YiQiKanSocket.send(jsonEncode({'type': 'roomInfo'}));
      if (_videoPlayerController != null &&
          _videoPlayerController.value.isPlaying &&
          author == username) {
        YiQiKanSocket.send(jsonEncode({
          "type": "sendTime",
          "time": (_videoPlayerController.value.position.inMilliseconds / 1000)
              .toDouble()
        }));
      }
    });
    t.startTimer();
    setState(() {});
  }

  sendChat(var data) {
    chatList.add(data);
    setState(() {});
    Timer(
        Duration(milliseconds: 500),
        () => _chatListController
            .jumpTo(_chatListController.position.maxScrollExtent));
  }

  roomInfo(var data) {
    online = data['online'];
    author = data['author'];
    users = data['users'];
    time = data['time'];
    userList = data['users'];
    if (data['url'] != url) {
      url = data['url'];
      _loadVideo(url);
    }
    if (username != author &&
        _videoPlayerController != null &&
        _videoPlayerController.value.isPlaying) {
      if ((time - _videoPlayerController.value.position.inSeconds).abs() >
          1.5) {
        if (_chewieController.seekTo != null) {
          _chewieController
              .seekTo(Duration(milliseconds: (time * 1000).toInt()));
        }
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    _usersYuYin.clear();
    AgoraRtcEngine.leaveChannel();
    AgoraRtcEngine.destroy();
    YiQiKanSocket.setRoomInfoCallBack(null);
    YiQiKanSocket.setSendChatCallBack(null);
    _tabController.dispose();
    t.cancel();
    if (_videoPlayerController != null) {
      _videoPlayerController.dispose();
      _chewieController.dispose();
      _videoPlayerController = null;
      _chewieController = null;
    }
    YiQiKanSocket.send(jsonEncode({"type": "exitRoom"}));
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
      body: Column(
        children: <Widget>[
          Container(
            child: _videoPlayerController != null &&
                    _chewieController != null &&
                    _videoPlayerController.value.initialized
                ? Chewie(
                    controller: _chewieController,
                  )
                : null,
          ),
          _tabController == null ? null : _buildTabBar(),
          _tabController == null ? null : Expanded(child: _buildTableBarView())
        ],
      ),
    );
  }

  Widget _buildTabBar() => TabBar(
        onTap: (index) => print(index),
        labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: 16),
        isScrollable: true,
        controller: _tabController,
        indicatorWeight: 3,
        indicatorPadding: EdgeInsets.symmetric(horizontal: 10),
        tabs: tabs.map((e) => Tab(text: e)).toList(),
      );

  Widget _buildTableBarView() =>
      TabBarView(controller: _tabController, children: <Widget>[
        new Column(//modified
            children: <Widget>[
          //new
          new Flexible(
              //new
              child: ListView(
            controller: _chatListController,
            children: chatList
                .map((chat) => Container(
                        child: Row(
                      children: <Widget>[
                        Text(chat['username'] + ":"),
                        Container(
                            constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.8),
                            child: Text(
                              chat['msg'],
                              style: TextStyle(color: Colors.black87),
                            ),
                            margin: EdgeInsets.all(2.0),
                            padding: EdgeInsets.all(2.0),
                            decoration: new BoxDecoration(
                                color: Colors.white,
                                //设置四周边框
                                borderRadius: BorderRadius.circular(8.0),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black38,
                                      offset: Offset(3.0, 5.0),
                                      //阴影xy轴偏移量
                                      blurRadius: 1.2,
                                      //阴影模糊程度
                                      spreadRadius: 1.5 //阴影扩散程度
                                      )
                                ]))
                      ],
                    )))
                .toList(),
          ) //new
              ), //new
          new Divider(height: 1.0), //new
          new Container(
            //new
            decoration:
                new BoxDecoration(color: Theme.of(context).cardColor), //new
            child: TextField(
              controller: _chatController,
              decoration: InputDecoration(
                  hintText: '请输入发送内容',
                  suffixIcon: FlatButton(
                    color: Theme.of(context).primaryColor,
                    child: Text("发送"),
                    onPressed: () {
                      if (_chatController.text != "") {
                        YiQiKanSocket.send(jsonEncode(
                            {"type": "sendChat", "msg": _chatController.text}));
                        _chatController.text = "";
                      }
                    },
                  )), //modified
            ), //new
          )
        ] //new
            ),
        Container(
            child: ListView(
                children: userList
                    .map((user) => Container(
                          child: Row(
                            children: <Widget>[
                              Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.7,
                                  child: Text(
                                      user['username'] +
                                          (author == user['username']
                                              ? "👑"
                                              : ""),
                                      overflow: TextOverflow.ellipsis)),
                              (author == username) &&
                                      (user['username'] != username)
                                  ? RaisedButton(
                                      elevation: 5,
                                      child: Text("转让房主"),
                                      onPressed: () {
                                        YiQiKanSocket.send(jsonEncode({
                                          "type": "transfer",
                                          "id": user['id']
                                        }));
                                      },
                                    )
                                  : Text("")
                            ],
                          ),
                        ))
                    .toList())),
        Container(
            child: author == username
                ? SingleChildScrollView(
                    child: Column(children: <Widget>[
                    new Container(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                            hintText: '请输入片名、导演、演员',
                            suffixIcon: IconButton(
                              color: Theme.of(context).primaryColor,
                              icon: Icon(Icons.search),
                              onPressed: () {
                                FocusScope.of(context)
                                    .requestFocus(FocusNode());
                                sou();
                              },
                            )), //modified
                      ), //new
                    ),
                    Center(
                      child: Wrap(
                          children: ySList
                              .map((ys) => GestureDetector(
                                    onTap: () => showYsJiDialog(ys['id']),
                                    child: Column(children: <Widget>[
                                      Container(
                                        width: 100,
                                        margin: EdgeInsets.all(5.0),
                                        child: CachedNetworkImage(
                                            imageUrl: ys['tp'],
                                            placeholder: (context, url) =>
                                                Image.asset(
                                                    "assets/img/zw.png"),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Image.asset(
                                                        "assets/img/zw.png")),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            boxShadow: [
                                              BoxShadow(
                                                  color: Colors.black12,
                                                  offset: Offset(
                                                      0.0, 5.0), //阴影xy轴偏移量
                                                  blurRadius: 2.0, //阴影模糊程度
                                                  spreadRadius: 1.0 //阴影扩散程度
                                                  )
                                            ]),
                                      ),
                                      Container(
                                        width: 100,
                                        child: Text(
                                          ys['pm'],
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 13, color: Colors.blue),
                                        ),
                                      )
                                    ]),
                                  ))
                              .toList()),
                    )
                  ]))
                : Center(child: Text("房主才能更换影视", textScaleFactor: 1.5))),
        Container(
            child: Column(
          children: <Widget>[
            RaisedButton(
              elevation: 5,
              child: Text(muted ? "离开语音" : "加入语音"),
              onPressed: () {
                if (muted) {
                  muted = !muted;
                  AgoraRtcEngine.leaveChannel();
                } else {
                  muted = !muted;
                  initYuYin();
                }
                setState(() {});
              },
            ),
            Text("通话接收音量:"),
            Slider(
              value: playbackSignalVolume.toDouble(),
              //实际进度的位置
              inactiveColor: Colors.black12,
              //进度中不活动部分的颜色
              label: '$playbackSignalVolume',
              min: 0,
              max: 400,
              divisions: 1000,
              activeColor: Colors.blue,
              onChanged: (double) {
                setState(() {
                  playbackSignalVolume = double.toInt();
                  //语音接收
                  AgoraRtcEngine.adjustPlaybackSignalVolume(
                      playbackSignalVolume);
                });
              },
            ),
            Text("麦克风音量:"),
            Slider(
              value: recordingSignalVolume.toDouble(),
              //实际进度的位置
              inactiveColor: Colors.black12,
              //进度中不活动部分的颜色
              label: '$recordingSignalVolume',
              min: 0,
              max: 100,
              divisions: 1000,
              activeColor: Colors.blue,
              onChanged: (double) {
                setState(() {
                  recordingSignalVolume = double.toInt();
                  //麦克风
                  AgoraRtcEngine.adjustRecordingSignalVolume(
                      recordingSignalVolume);
                });
              },
            )
          ],
        ))
      ]);

  sou() async {
    if (_searchController.text != "") {
      var response = await http
          .get("https://dbys.vip/api/v1/ys/search/" + _searchController.text);
      var data = await jsonDecode(response.body);
      ySList = data['data'];
      setState(() {});
    }
  }

  showYsJiDialog(int id) async {
    var response =
        await http.get("https://dbys.vip/api/v1/ys/" + id.toString());
    var json = await jsonDecode(response.body);
    playList = jsonDecode(json['data']['gkdz']);
    jiDialog = YYDialog().build(context)
      ..width = MediaQuery.of(context).size.width * 0.8
      ..borderRadius = 4.0
      ..text(
        padding: EdgeInsets.all(18.0),
        text: "请选择你要播放的集:",
        color: Colors.grey[700],
      )
      ..widget(
        Container(
            height: 300,
            child: SingleChildScrollView(
                child: Wrap(
                    children: playList
                        .map((ys) => MaterialButton(
                              height: 40,
                              elevation: 5,
                              color: Theme.of(context).accentColor,
                              textColor: Colors.white,
                              child: Text(ys['name']),
                              onPressed: () => {
                                YiQiKanSocket.send(jsonEncode(
                                    {"type": "sendUrl", "url": ys['url']})),
                                jiDialog?.dismiss()
                              },
                            ))
                        .toList()))),
      )
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
        onTap2: () {},
      )
      ..show();
  }

  initYuYin() async {
    //获取麦克风权限
    await Permission.microphone.request();

    /// 创建agora sdk实例并初始化
    await _initAgoraRtcEngine();

    /// 添加agora事件处理程序
    _addAgoraEventHandlers();
    await AgoraRtcEngine.enableWebSdkInteroperability(true);
    await AgoraRtcEngine.joinChannel(
        widget.token, widget.channel, null, widget.uid);
    AgoraRtcEngine.enableLocalAudio(true);
    //语音接收
    AgoraRtcEngine.adjustPlaybackSignalVolume(playbackSignalVolume);
    //麦克风音量
    AgoraRtcEngine.adjustRecordingSignalVolume(recordingSignalVolume);
  }

  Future<void> _initAgoraRtcEngine() async {
    await AgoraRtcEngine.create(agora_APP_ID);
    await AgoraRtcEngine.enableVideo();
  }

  /// 添加agora事件处理程序
  void _addAgoraEventHandlers() {
    AgoraRtcEngine.onError = (dynamic code) {
      print("YuYin-Err" + code);
    };

    AgoraRtcEngine.onJoinChannelSuccess = (
      String channel,
      int uid,
      int elapsed,
    ) {
      setState(() {
        final info = 'onJoinChannel: $channel, uid: $uid';
        print("YuYin-" + info);
      });
    };

    AgoraRtcEngine.onLeaveChannel = () {
      setState(() {
        print("YuYin-onLeaveChannel");
        _usersYuYin.clear();
      });
    };

    AgoraRtcEngine.onUserJoined = (int uid, int elapsed) {
      setState(() {
        final info = 'userJoined: $uid';
        print("YuYin-" + info);
        _usersYuYin.add(uid);
      });
    };

    AgoraRtcEngine.onUserOffline = (int uid, int reason) {
      setState(() {
        final info = 'userOffline: $uid';
        print("YuYin-" + info);
        _usersYuYin.remove(uid);
      });
    };
  }
}
