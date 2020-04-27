import 'dart:convert';

import 'package:cdnbye/cdnbye.dart';
import 'package:chewie/chewie.dart';
import 'package:dbys/module/CustomControls.dart';

import 'package:flutter/material.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

import 'package:video_player/video_player.dart';

class TvPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _TvPageState();
}

class _TvPageState extends State<TvPage> {
  VideoPlayerController _videoPlayerController;
  ChewieController _chewieController;
  List playList = [];
  String pNAME;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  dispose() {
    super.dispose();
    if (_videoPlayerController != null) {
      _videoPlayerController.dispose();
      _chewieController.dispose();
      _videoPlayerController = null;
      _chewieController = null;
    }
  }

  init() async {
    //获取影视数据
    var response = await http.get("https://dbys.vip/api/v1/ys/tv");
    var json = await jsonDecode(response.body);
    //转对象
    playList = json['data'];
    _loadVideo(playList[0]['url']);
    pNAME = playList[0]['name'];
    setState(() {});
  }

  _initController(String link) {
    _videoPlayerController = VideoPlayerController.network(link)
      ..initialize().then((_) {
        _chewieController = ChewieController(
            isLive: true,
            customControls: CustomControls(),
            allowedScreenSleep: false,
            videoPlayerController: _videoPlayerController,
            aspectRatio: _videoPlayerController.value.aspectRatio,
            autoPlay: true);
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
                title: Text("电视直播"),
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
        body: Column(children: <Widget>[
          Container(
            child: _videoPlayerController != null &&
                    _chewieController != null &&
                    _videoPlayerController.value.initialized
                ? Chewie(
                    controller: _chewieController,
                  )
                : null,
          ),
          Expanded(
              child: SingleChildScrollView(
            child: Wrap(
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
                            _loadVideo(ys['url']),
                            setState(() {})
                          },
                        ))
                    .toList()),
          ))
        ]));
  }
}
