import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cdnbye/cdnbye.dart';
import 'package:chewie/chewie.dart';
import 'package:dbys/module/Ysb.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
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
  Timer blTime;
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
    blTime.cancel();
    UmengAnalyticsPlugin.pageEnd("YsPage");
    super.dispose();
  }

  init() async {
    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    SharedPreferences prefs = await _prefs;
    username = prefs.getString("UserNmae");
    token = prefs.getString("Token");
    var response =
        await http.get("https://dbys.vip/api/v1/ys/" + widget.id.toString());
    var json = await jsonDecode(response.body);
    Map ysbMap = json['data'];
    ysb = new Ysb.fromJson(ysbMap);
    playList = jsonDecode(ysb.gkdz);
    pNAME = playList[0]['name'];
    _loadVideo(playList[0]['url']);
    setState(() {});
  }

  _loadVideo(String url) async {
    if (_videoPlayerController != null) {
      _videoPlayerController.pause();
    }
    var response;
    if(username!=null){
      response =
      await http.post("https://dbys.vip/ys/gettime",body: {"ysid":widget.id.toString(),"username":username,"ysjiname":pNAME});
      //定时器 定时发送观看时间
      TimerUtil postTimer=TimerUtil();
      postTimer.setInterval(2000);
      postTimer.setOnTimerTickCallback((int tick)  {
        if(_videoPlayerController!=null&&_videoPlayerController.value.isPlaying){
          Duration d= _videoPlayerController.value.position;
          http.post("https://dbys.vip/api/v1/ys/time",body: {"ysid":widget.id.toString(),"username":username,"ysjiname":pNAME,"time":d.inSeconds.toString(),"token":token});
        }
        });
      postTimer.startTimer();
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
      startAt: response!=null?Duration(seconds: double.parse(response.body).toInt()):null
    );
    setState(() {});
    //5秒后获取视频长宽比并设置
    var timeout = const Duration(seconds: 5);
    blTime=Timer(timeout, () async {
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
    });
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
            preferredSize:
                Size.fromHeight(MediaQuery.of(context).size.height * 0.06)),
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
                                    _loadVideo(ys['url'])
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
