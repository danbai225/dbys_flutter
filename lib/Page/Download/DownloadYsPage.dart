import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:chewie/chewie.dart';
import 'package:dbys/Page/Download/DownloadManagement.dart';
import 'package:dbys/module/CustomControls.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

class DownloadYsPage extends StatefulWidget {
  DownloadYsPage({Key key}) : super(key: key);

  @override
  _DownloadYsState createState() => _DownloadYsState();
}

class _DownloadYsState extends State<DownloadYsPage> {
  VideoPlayerController _videoPlayerController;
  ChewieController _chewieController;
  RawDatagramSocket rawDgramSocket;
  String xzPm;
  String xzJi;
  String xzJinDu;
  String xzSuDu;
  bool isCancel = false;
  List yss = [];
  bool delete = false;
  String palyerUrl;
  String sDCardDir;
  @override
  void initState() {
    super.initState();
    Permission.storage.request();
    init();
  }

  addYS() async {
    sDCardDir = (await getExternalStorageDirectory()).path;
    yss = [];
    List<FileSystemEntity> files = [];
    Directory directory = Directory(sDCardDir + "/下载");
    if (await (directory.exists())) {
      files = directory.listSync();
      files.forEach((f) {
        String pm = f.path.substring(f.path.lastIndexOf('/') + 1);
        Directory ys = Directory(f.path);
        List<FileSystemEntity> jisFiles = ys.listSync();
        List jis = [];
        jisFiles.forEach((y) {
          if(y.path.indexOf(".xy")<0){
            //添加集
            jis.add({
              "name": y.path
                  .substring(y.path.lastIndexOf('/') + 1, y.path.length - 4),
              "path": y.path
            });
          }
        });
        jis.sort((a, b) => a["name"].compareTo(b["name"]));
        jis.sort((left,right)=>0);
        if(jis.length>0){
          yss.add({"pm": pm, "jis": jis});
        }
      });
      setState(() {});
    }
  }
  bool equalsIgnoreCase(String string1, String string2) {
    return string1?.toLowerCase() == string2?.toLowerCase();
  }
  init() async {
    addYS();
    rawDgramSocket = await RawDatagramSocket.bind('127.0.0.1', 2256);
    //监听套接字事件
    await for (RawSocketEvent event in rawDgramSocket) {
      if (event == RawSocketEvent.read) {
        // 接收数据
        var data = jsonDecode(utf8.decode(rawDgramSocket.receive().data));
        if (!isCancel) {
          switch (data['type']) {
            case "onDownloading":
              xzPm = data['pm'];
              xzJinDu = (data['schedule']).toInt().toString() + "%";
              xzJi = data['JiName'];
              break;
            case "onProgress":
              xzSuDu = data['speed'];
              break;
            case "onSuccess":
              xzPm = null;
              addYS();
              break;
          }
          setState(() {});
        }
      }
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    if (_videoPlayerController != null) {
      _videoPlayerController.dispose();
      _chewieController.dispose();
      _videoPlayerController = null;
      _chewieController = null;
    }
  }

  void _initController(String link) {
    _videoPlayerController = VideoPlayerController.network(link)
      ..initialize().then((_) {
        _chewieController = ChewieController(
          customControls: CustomControls(),
          allowedScreenSleep: false,
          videoPlayerController: _videoPlayerController,
          aspectRatio: _videoPlayerController.value.aspectRatio,
          autoPlay: true,
          looping: true,
        );
        setState(() {});
      });
  }

  //加载视频
  _loadVideo(String url) async {
    if (_videoPlayerController == null) {
      // If there was no controller, just create a new one
      _initController(url);
    } else {
      // If there was a controller, we need to dispose of the old one first
      final oldController = _videoPlayerController;
      // Registering a callback for the end of next frame
      // to dispose of an old controller
      // (which won't be used anymore after calling setState)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
            child: AppBar(
              centerTitle: true,
              title: Text("下载管理"),
              actions: <Widget>[
                IconButton(
                  color: delete ? Colors.red : Colors.black,
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    delete = !delete;
                    if (delete) {
                      Fluttertoast.showToast(
                          msg: "点击需要删除的集",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Theme.of(context).accentColor,
                          textColor: Colors.red,
                          fontSize: 16.0);
                    }
                    setState(() {});
                  },
                  // 显示描述信息
                  tooltip: "删除",
                )
              ],
            ),
            preferredSize: Size.fromHeight(40)),
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
            xzPm != null
                ? Container(
                    child: Text(
                      "下载中",
                      textAlign: TextAlign.right,
                    ),
                  )
                : Container(),
            xzPm != null
                ? Container(
                    child: Container(
                        margin: EdgeInsets.all(2.0),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: (MediaQuery.of(context).size.width * 0.4),
                              child: Text("片名:$xzPm",
                                  style: TextStyle(fontSize: 18),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Expanded(
                                child: Text("集数:$xzJi 速度:$xzSuDu 进度:$xzJinDu",
                                    style: TextStyle(fontSize: 14))),
                            MaterialButton(
                                child: Text(
                                  "取消",
                                  style: TextStyle(color: Colors.blue),
                                ),
                                onPressed: () {
                                  DownloadManagement.cancel();
                                  xzPm = null;
                                  isCancel = true;
                                  const timeout = const Duration(seconds: 1);
                                  Timer(timeout, () {
                                    isCancel = false;
                                  });
                                  setState(() {});
                                }),
                          ],
                        )))
                : Container(),
            Expanded(
              child: ListView(
                children: yss
                    .map((ys) => Card(
                          child: Column(
                            children: <Widget>[
                              Text(ys['pm']),
                              Wrap(
                                children: fenJi(ys['jis']),
                              )
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),sDCardDir!=null?Text("存储位置:"+sDCardDir + "/下载"):Text("")
          ],
        ));
  }

  List<Widget> fenJi(List jis) {
    return jis
        .map((j) => MaterialButton(
            color: delete
                ? Colors.red
                : palyerUrl == j['path'] ? Colors.blue : Colors.blueGrey,
            child: Text(
              j['name'],
            ),
            onPressed: () {
              if (delete) {
                deleteYs(j['path']);
                addYS();
              } else {
                palyerUrl = j['path'];
                _loadVideo(j['path']);
              }
              setState(() {});
            }))
        .toList();
  }

  deleteYs(String path) {
    print(path);
    String dpath = path.substring(0, path.lastIndexOf('/'));
    Directory directory = new Directory(dpath);
    if (directory.existsSync()) {
      List<FileSystemEntity> files = directory.listSync();
      if (files.length > 0) {
        files.forEach((file) {
          print(file.path);
          if (path == file.path) {
            file.deleteSync();
          }
        });
      }
      files = directory.listSync();
      if (files.length == 0) {
        directory.deleteSync();
      }
    }
  }
}
