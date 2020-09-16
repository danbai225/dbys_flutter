import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cdnbye/cdnbye.dart';
import 'package:chewie/chewie.dart';
import 'package:dbys/Socket/YiQiKanSocket.dart';
import 'package:dbys/module/CustomControls.dart';
import 'package:dbys/module/Ysb.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'Download/DownloadManagement.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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
  Duration startTime;
  YYDialog jiDialog;
  List downloadList = [];
  bool nextJi=false;
  bool loadOk=false;
  //与原生交互的通道
  static const platform = const MethodChannel('cn.p00q.dbys/tp');

  getList() async {
    print("获取列表");
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
  }

  @override
  dispose() {
    super.dispose();
    if(_videoPlayerController!=null){
      _videoPlayerController.dispose();
      _chewieController.dispose();
      _videoPlayerController = null;
      _chewieController = null;
    }
    postTimer.cancel();
    postTimer = null;
  }

  init() async {
    //获取投屏设备
    getList();
    username = SpUtil.getString("UserNmae");
    token = SpUtil.getString("Token");
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
      startTime = Duration(seconds: json['data']['time'].toInt());
      _loadVideo(json['data']['gkls']['url']);
    } else {
      pNAME = playList[0]['name'];
      _loadVideo(playList[0]['url']);
    }
    //定时器 定时发送观看时间
    postTimer = TimerUtil();
    postTimer.setInterval(500);
    postTimer.setOnTimerTickCallback((int tick) {
      //有视频正在播放
      if (_videoPlayerController != null &&
          _videoPlayerController.value.isPlaying) {
        Duration d = _videoPlayerController.value.position;
        if (username != null) {
          YiQiKanSocket.send(jsonEncode({
            "type":"postTime",
            "ysid": widget.id.toString(),
            "username": username,
            "ysjiname": pNAME,
            "time": d.inSeconds.toString(),
            "token": token
          }));
          /*http.post("https://dbys.vip/api/v1/ys/time", body: {
            "ysid": widget.id.toString(),
            "username": username,
            "ysjiname": pNAME,
            "time": d.inSeconds.toString(),
            "token": token
          });*/
        }
        if(SpUtil.getBool("AoutPlayerNext")&&(_videoPlayerController.value.position.inSeconds+7)>_videoPlayerController.value.duration.inSeconds){
          if(_chewieController.isFullScreen){
            _chewieController.toggleFullScreen();
            nextJi=true;
          }
        }
        if(SpUtil.getBool("AoutPlayerNext")&&(_videoPlayerController.value.position.inSeconds+3)>_videoPlayerController.value.duration.inSeconds){
          if(playList.length>1){
            for(int i=0;i<playList.length;i++){
              if(playList[i]['name']==pNAME){
                if(i!=playList.length-1){
                  startTime = null;
                  pNAME=playList[i+1]['name'];
                  _loadVideo(playList[i+1]['url']);
                  break;
                }
              }
            }
          }
        }
      }
    });
    postTimer.startTimer();
    loadOk=true;
    setState(() {});
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
            looping: true,
            startAt: startTime);
        setState(() {});
        const timeout = const Duration(seconds: 1);
        Timer(timeout, () {
          full();
        });
      });
  }

  getStartTime() async {
    if (username != "" && startTime == null) {
      var response = await http.post("https://dbys.vip/ys/gettime", body: {
        "ysid": widget.id.toString(),
        "username": username,
        "ysjiname": pNAME
      });
      startTime = Duration(seconds: double.parse(response.body).toInt());
      //初始化已经完成则更新
      if (_videoPlayerController.value.isPlaying) {
        _chewieController = ChewieController(
            customControls: CustomControls(),
            allowedScreenSleep: false,
            videoPlayerController: _videoPlayerController,
            aspectRatio: _videoPlayerController.value.aspectRatio,
            autoPlay: true,
            looping: true,
            startAt: startTime);
        setState(() {});
        const timeout = const Duration(seconds: 1);
        Timer(timeout, () {
          full();
        });
      }
    }
  }
  full(){
    if (!_chewieController.isFullScreen&&nextJi) {
      //下一集后全屏
      _chewieController.enterFullScreen();
      nextJi=false;
    }
  }
  //加载视频
  _loadVideo(String url) async {
    getStartTime();
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

  void showMyDialogWithStateBuilder(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return new AlertDialog(
            actions: <Widget>[
              new FlatButton(
                onPressed: () async {
                  Permission.storage.request();
                  List downloads = SpUtil.getObjectList("downloads");
                  if (downloads == null) {
                    downloads = new List();
                  }
                  downloadList.forEach((ys) =>
                      {DownloadManagement.add(ys['url'], ysb.pm, ys['name'])});
                  Fluttertoast.showToast(
                      msg: "已经添加到下载列表:共${downloadList.length}集",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: Theme.of(context).accentColor,
                      textColor: Colors.white,
                      fontSize: 16.0);
                  Navigator.of(context, rootNavigator: true).pop();
                },
                child: new Text("确定"),
              ),
            ],
            title: new Text("选择需要缓存的集:"),
            content: Container(
                height: 400,
                child:
                    StatefulBuilder(builder: (context, StateSetter setState) {
                  return SingleChildScrollView(
                      child: Center(
                    child: Wrap(
                        children: playList
                            .map((ys) =>  MaterialButton(
                          height: 40,
                          elevation: 5,
                          color: downloadList.contains(ys)
                              ? Colors.red
                              : Theme.of(context).accentColor,
                          textColor: Colors.white,
                          child: Text(ys['name']),
                          onPressed: () {
                            if (downloadList.contains(ys)) {
                              downloadList.remove(ys);
                            } else {
                              downloadList.add(ys);
                            }
                            setState(() {});
                          },
                        ),)
                            .toList()),
                  ));
                })),
          );
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
                actions: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.save_alt),
                    // 如果有抽屉的话的就打开
                    onPressed: () {
                      showMyDialogWithStateBuilder(context);
                    },
                    // 显示描述信息
                    tooltip: "缓存",
                  )
                ],
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
        body: loadOk?Column(
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
                            ))),Container(width: 70,child:MaterialButton(
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
                        ) ,)
                        ,Container(
                          width: 70,child: Padding(padding:EdgeInsets.fromLTRB(5, 0, 0, 0),child:MaterialButton(
                          elevation: 5,
                          color: Theme.of(context).accentColor,
                          textColor: Colors.white,
                          child: Text("刷新"),
                          onPressed: () {
                            tvs=[];
                            getList();
                            setState(() {});
                          },
                        )),
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
                            ),Container(
                              width: (MediaQuery.of(context).size.width - 100),
                              child: RichText(
                                  text: TextSpan(
                                      text: "评分:",
                                      style: labStyle,
                                      children: [
                                        TextSpan(
                                            text: qNull(ysb.pf.toString()),
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

                          ],
                        )
                      ],
                    ),Container(
                      width: (MediaQuery.of(context).size.width),
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
                    ),
                    Container(
                      child: Text(qNull(ysb.js)),
                    ),
                    Wrap(
                        children: playList
                            .map((ys) => Padding(padding:EdgeInsets.fromLTRB(2, 0, 2, 0),child:MaterialButton(
                                  height: 40,
                                  elevation: 5,
                                  color: ys['name'] == pNAME
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context).accentColor,
                                  textColor: Colors.white,
                                  child: Text(ys['name']),
                                  onPressed: () => {
                                    startTime = null,
                                    pNAME = ys['name'],
                                    _loadVideo(ys['url']),
                                    setState(() {})
                                  },
                                )))
                            .toList()),
                  ],
                ),
              ),
            )
          ],
        ):SpinKitPulse(
          itemBuilder: (BuildContext context, int index) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color:Colors.grey
              ),
            );
          },
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
