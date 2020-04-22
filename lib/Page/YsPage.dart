import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cdnbye/cdnbye.dart';
import 'package:chewie/chewie.dart';
import 'package:dbys/module/Ysb.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umeng_analytics_plugin/umeng_analytics_plugin.dart';
import 'package:video_player/video_player.dart';

class YsPage extends StatefulWidget {
  YsPage({this.id});

  final int id;

  @override
  State<StatefulWidget> createState() => new _YsPageState();
}

class _YsPageState extends State<YsPage> {
  VideoPlayerController _videoPlayerController;
  ChewieController _chewieController;
  Ysb ysb = new Ysb();
  List playList = [];
  String pNAME;
  String username;
  String token;
  TimerUtil postTimer;
  List tvs = [];
  int tpIndex;

  //与原生交互的通道
  static const platform = const MethodChannel('cn.p00q.dbys/tp');

  getList() async {
    try {
      tvs = await platform.invokeMethod('getList');
    } on PlatformException catch (e) {
      print("错误:$e");
    }
  }

  tp(String url, int index) {
    platform.invokeMethod('tp', jsonEncode({"url": url, "index": index}));
  }

  @override
  void initState() {
    super.initState();
    init();
    UmengAnalyticsPlugin.pageStart("YsPage");
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    postTimer.cancel();
    UmengAnalyticsPlugin.pageEnd("YsPage");
    super.dispose();
  }

  init() async {
    //获取投屏设备
    getList();
    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    SharedPreferences prefs = await _prefs;
    username = prefs.getString("UserNmae");
    token = prefs.getString("Token");
    //获取影视数据
    var response = await http.get(
        "https://dbys.vip/api/v1/ysAndLs?id=${widget.id.toString()}&username=$username&token=$token");
    var json = await jsonDecode(response.body);
    //转对象
    Map ysbMap = json['data']['ys'];
    ysb = new Ysb.fromJson(ysbMap);
    playList = jsonDecode(ysb.gkdz);
    //是否有观看历史
    if (json['data']['time'] != null) {
      pNAME = json['data']['gkls']['jiname'];

      _loadVideo(json['data']['gkls']['url'],
          Duration(seconds: json['data']['time'].toInt()));
    } else {
      pNAME = playList[0]['name'];
      _loadVideo(playList[0]['url'], null);
    }
    //定时器 定时发送观看时间
    postTimer = TimerUtil();
    postTimer.setInterval(2000);
    postTimer.setOnTimerTickCallback((int tick) {
      //有视频正在播放
      if (_videoPlayerController != null &&
          _videoPlayerController.value.isPlaying) {
        Duration d = _videoPlayerController.value.position;
        if (username != null) {
          http.post("https://dbys.vip/api/v1/ys/time", body: {
            "ysid": widget.id.toString(),
            "username": username,
            "ysjiname": pNAME,
            "time": d.inSeconds.toString(),
            "token": token
          });
        }
        //更新长宽比
        if (_videoPlayerController.value.aspectRatio !=
            _chewieController.aspectRatio) {
          print("长宽");
          _chewieController = ChewieController(
            allowedScreenSleep: false,
            videoPlayerController: _videoPlayerController,
            aspectRatio: _videoPlayerController.value.aspectRatio == 1.0
                ? 16 / 9
                : _videoPlayerController.value.aspectRatio,
            autoPlay: true,
            looping: true,
          );
          setState(() {});
        }
      }
    });
    postTimer.startTimer();
    setState(() {});
  }

  //加载视频
  _loadVideo(String url, Duration startTime) async {
    //是否有视频有就释放
    if (_videoPlayerController != null) {
      _videoPlayerController.pause();
    }
    if (username != null && startTime == null) {
      var response = await http.post("https://dbys.vip/ys/gettime", body: {
        "ysid": widget.id.toString(),
        "username": username,
        "ysjiname": pNAME
      });
      startTime = Duration(seconds: double.parse(response.body).toInt());
    }
    //初始化视频播放
    url = await Cdnbye.parseStreamURL(url);
    _videoPlayerController = VideoPlayerController.network(url);
    _chewieController = ChewieController(
        allowedScreenSleep: false,
        videoPlayerController: _videoPlayerController,
        aspectRatio: 16 / 9,
        autoPlay: true,
        looping: true,
        startAt: startTime);
    setState(() {});
  }

  Widget build(BuildContext context) {
    TextStyle labStyle = TextStyle(
        fontWeight: FontWeight.w900, fontSize: 13, color: Colors.green);
    TextStyle textStyle = TextStyle(
        fontWeight: FontWeight.w400, fontSize: 12, color: Colors.grey);
    return Scaffold(
        appBar: PreferredSize(
            child: AppBar(
                centerTitle: true,
                title: Text(ysb.pm == null ? "" : ysb.pm),
                leading: Builder(
                  builder: (BuildContext context) {
                    return IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.of(context).pop(); //返回
                      },
                      tooltip: "返回",
                    );
                  },
                )),
            preferredSize: Size.fromHeight(40)),
        body: Column(
          children: <Widget>[
            Container(
              child: _chewieController == null
                  ? null
                  : Chewie(
                      controller: _chewieController,
                    ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                            width: 200,
                            child: SingleChildScrollView(
                                child: ExpansionTile(
                              title: Text("选择投屏设备"),
                              children: tvs
                                  .map((tv) => MaterialButton(
                                        elevation: 5,
                                        child: Text(tv),
                                        onPressed: () {
                                          for (int i = 0; i < tvs.length; i++) {
                                            if (tvs[i] == tv) {
                                              tpIndex = i;
                                              Fluttertoast.showToast(
                                                  msg: "选中投屏设备:$tv",
                                                  toastLength:
                                                      Toast.LENGTH_SHORT,
                                                  gravity: ToastGravity.BOTTOM,
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .accentColor,
                                                  textColor: Colors.white,
                                                  fontSize: 16.0);
                                            }
                                          }
                                        },
                                      ))
                                  .toList(),
                            ))),
                        MaterialButton(
                          elevation: 5,
                          color: Theme.of(context).accentColor,
                          textColor: Colors.white,
                          child: Text("投屏"),
                          onPressed: () {
                            if (tpIndex == null) {
                              Fluttertoast.showToast(
                                  msg: "没有选择设备",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                  fontSize: 16.0);
                            } else {
                              for (int i = 0; i < playList.length; i++) {
                                if (playList[i]['name'] == pNAME) {
                                  tp(playList[i]['url'], tpIndex);
                                  Fluttertoast.showToast(
                                      msg: "投屏中",
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.CENTER,
                                      backgroundColor:
                                          Theme.of(context).accentColor,
                                      textColor: Colors.white,
                                      fontSize: 16.0);
                                }
                              }
                            }
                          },
                        )
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Container(
                          width: 100,
                          child: CachedNetworkImage(
                            imageUrl: qNull(ysb.tp),
                            placeholder: (context, url) =>
                                Image.asset("assets/img/zw.png"),
                            errorWidget: (context, url, error) =>
                                Image.asset("assets/img/zw.png"),
                          ),
                        ),
                        Column(
                          children: <Widget>[
                            Container(
                              width: (MediaQuery.of(context).size.width - 100),
                              child: RichText(
                                  text: TextSpan(
                                      text: "片名:",
                                      style: labStyle,
                                      children: [
                                        TextSpan(
                                            text: qNull(ysb.pm),
                                            style: textStyle),
                                      ]),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                  maxLines: 2),
                            ),
                            Container(
                              width: (MediaQuery.of(context).size.width - 100),
                              child: RichText(
                                  text: TextSpan(
                                      text: "类型:",
                                      style: labStyle,
                                      children: [
                                        TextSpan(
                                            text: qNull(ysb.lx),
                                            style: textStyle),
                                      ]),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                  maxLines: 2),
                            ),
                            Container(
                              width: (MediaQuery.of(context).size.width - 100),
                              child: RichText(
                                  text: TextSpan(
                                      text: "状态:",
                                      style: labStyle,
                                      children: [
                                        TextSpan(
                                            text: qNull(ysb.zt),
                                            style: textStyle),
                                      ]),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                  maxLines: 2),
                            ),
                            Container(
                              width: (MediaQuery.of(context).size.width - 100),
                              child: RichText(
                                  text: TextSpan(
                                      text: "地区:",
                                      style: labStyle,
                                      children: [
                                        TextSpan(
                                            text: qNull(ysb.dq),
                                            style: textStyle),
                                      ]),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                  maxLines: 2),
                            ),
                            Container(
                              width: (MediaQuery.of(context).size.width - 100),
                              child: RichText(
                                  text: TextSpan(
                                      text: "主演:",
                                      style: labStyle,
                                      children: [
                                        TextSpan(
                                            text: qNull(ysb.zy),
                                            style: textStyle),
                                      ]),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                  maxLines: 2),
                            ),
                            Container(
                              width: (MediaQuery.of(context).size.width - 100),
                              child: RichText(
                                  text: TextSpan(
                                      text: "导演:",
                                      style: labStyle,
                                      children: [
                                        TextSpan(
                                            text: qNull(ysb.dy),
                                            style: textStyle),
                                      ]),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                  maxLines: 2),
                            ),
                            Container(
                              width: (MediaQuery.of(context).size.width - 100),
                              child: RichText(
                                  text: TextSpan(
                                      text: "上映时间:",
                                      style: labStyle,
                                      children: [
                                        TextSpan(
                                            text: qNull(ysb.sytime),
                                            style: textStyle),
                                      ]),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                  maxLines: 2),
                            ),
                            Container(
                              width: (MediaQuery.of(context).size.width - 100),
                              child: RichText(
                                  text: TextSpan(
                                      text: "更新时间:",
                                      style: labStyle,
                                      children: [
                                        TextSpan(
                                            text: qNull(ysb.gxtime),
                                            style: textStyle),
                                      ]),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                  maxLines: 2),
                            )
                          ],
                        )
                      ],
                    ),
                    Container(
                      child: Text(qNull(ysb.js)),
                    ),
                    Wrap(
                        children: playList
                            .map((ys) => MaterialButton(
                                  height: 40,
                                  elevation: 5,
                                  color: ys['name'] == pNAME
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context).accentColor,
                                  textColor: Colors.white,
                                  child: Text(ys['name']),
                                  onPressed: () => {
                                    pNAME = ys['name'],
                                    _loadVideo(ys['url'], null)
                                  },
                                ))
                            .toList()),
                  ],
                ),
              ),
            )
          ],
        ));
  }

  qNull(String str) {
    if (str == null) {
      return "";
    } else {
      return str;
    }
  }
}
