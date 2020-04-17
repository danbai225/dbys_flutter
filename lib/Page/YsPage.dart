import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cdnbye/cdnbye.dart';
import 'package:dbys/module/Ysb.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/material.dart';
class YsPage extends StatefulWidget {
  YsPage({this.id});

  int id;

  @override
  State<StatefulWidget> createState() => new _YsPageState();
}

class _YsPageState extends State<YsPage> {
  final FijkPlayer player = FijkPlayer();
  Ysb ysb=new Ysb();
  String pm = "";
  List playList = [];
  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    player.release();
    super.dispose();
  }

  init() async {
    await Cdnbye.init("_WJjufJZR", config: P2pConfig.byDefault());
    var response =
        await http.get("http://dbys.vip/api/v1/ys/" + widget.id.toString());
    var json = await jsonDecode(response.body);
    Map ysbMap = json['data'];
    ysb=new Ysb.fromJson(ysbMap);
    setState(() {
      pm = ysb.tp;
      playList = jsonDecode(ysb.gkdz);
      _loadVideo(playList[0]['url']);
    });
  }

  _loadVideo(String url) async {
    url = await Cdnbye.parseStreamURL(url);
    player.reset();
    player.setDataSource(url,autoPlay: true);
  }

  Widget build(BuildContext context) {
    TextStyle labStyle=TextStyle(
    fontWeight: FontWeight.w900,fontSize: 13,color: Colors.green
    );
    TextStyle textStyle=TextStyle(
        fontWeight: FontWeight.w400,fontSize: 12,color: Colors.grey
    );
    return Scaffold(
        appBar: PreferredSize(
            child: AppBar(
                centerTitle: true,
                title: Text(ysb.pm==null?"":ysb.pm),
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
              child: FijkView(
                height: 160,
                color: Colors.black,
                player: player,

              ),
            ),
            Expanded(
              child:SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 100,
                          child: CachedNetworkImage(imageUrl: qNull(ysb.tp),  placeholder: (context, url) => Image.asset("assets/img/zw.png"),
                            errorWidget: (context, url, error) => Image.asset("assets/img/zw.png"),),
                        ),
                        Column(
                          children: <Widget>[
                            Container(
                              width:(MediaQuery.of(context).size.width-100),
                              child:RichText(
                                text: TextSpan(
                                  text: "片名:",
                                  style: labStyle,
                                  children: [
                                    TextSpan(text: qNull(ysb.pm), style: textStyle),
                                    
                                  ]
                                ),
                                  overflow: TextOverflow.ellipsis,textAlign: TextAlign.left,maxLines: 2
                              ),
                            ),Container(
                              width:(MediaQuery.of(context).size.width-100),
                              child:RichText(
                                  text: TextSpan(
                                      text: "类型:",
                                      style: labStyle,
                                      children: [
                                        TextSpan(text: qNull(ysb.lx), style: textStyle),
                                      ]
                                  ),
                                  overflow: TextOverflow.ellipsis,textAlign: TextAlign.left,maxLines: 2
                              ),
                            ),Container(
                              width:(MediaQuery.of(context).size.width-100),
                              child:RichText(
                                  text: TextSpan(
                                      text: "状态:",
                                      style: labStyle,
                                      children: [
                                        TextSpan(text: qNull(ysb.zt), style: textStyle),
                                      ]
                                  ),
                                  overflow: TextOverflow.ellipsis,textAlign: TextAlign.left,maxLines: 2
                              ),
                            ),Container(
                              width:(MediaQuery.of(context).size.width-100),
                              child:RichText(
                                  text: TextSpan(
                                      text: "地区:",
                                      style: labStyle,
                                      children: [
                                        TextSpan(text: qNull(ysb.dq), style: textStyle),
                                      ]
                                  ),
                                  overflow: TextOverflow.ellipsis,textAlign: TextAlign.left,maxLines: 2
                              ),
                            ),Container(
                              width:(MediaQuery.of(context).size.width-100),
                              child:RichText(
                                  text: TextSpan(
                                      text: "主演:",
                                      style: labStyle,
                                      children: [
                                        TextSpan(text: qNull(ysb.zy), style: textStyle),
                                      ]
                                  ),
                                  overflow: TextOverflow.ellipsis,textAlign: TextAlign.left,maxLines: 2
                              ),
                            ),Container(
                              width:(MediaQuery.of(context).size.width-100),
                              child:RichText(
                                  text: TextSpan(
                                      text: "导演:",
                                      style: labStyle,
                                      children: [
                                        TextSpan(text: qNull(ysb.dy), style: textStyle),
                                      ]
                                  ),
                                  overflow: TextOverflow.ellipsis,textAlign: TextAlign.left,maxLines: 2
                              ),
                            ),Container(
                              width:(MediaQuery.of(context).size.width-100),
                              child:RichText(
                                  text: TextSpan(
                                      text: "上映时间:",
                                      style: labStyle,
                                      children: [
                                        TextSpan(text: qNull(ysb.sytime), style: textStyle),
                                      ]
                                  ),
                                  overflow: TextOverflow.ellipsis,textAlign: TextAlign.left,maxLines: 2
                              ),
                            ),Container(
                              width:(MediaQuery.of(context).size.width-100),
                              child:RichText(
                                  text: TextSpan(
                                      text: "更新时间:",
                                      style: labStyle,
                                      children: [
                                        TextSpan(text: qNull(ysb.gxtime), style: textStyle),
                                      ]
                                  ),
                                  overflow: TextOverflow.ellipsis,textAlign: TextAlign.left,maxLines: 2
                              ),
                            )
                          ],
                        )
                      ],
                    ),Container(
                      child:Text(qNull(ysb.js)),
                    ),Wrap(
                        children:
                    playList
                        .map((ys) => MaterialButton(
                      height: 40,
                      elevation: 5,
                        color: Colors.orangeAccent,
                      padding: EdgeInsets.all(8),
                      textColor: Colors.white,
                      child: Text(ys['name']),
                      onPressed: ()=>{
                        _loadVideo(ys['url'])},
                    )).toList()
                    ),
                  ],
                ),
              ) ,
            )

          ],
        ));
  }
  qNull(String str){
    if(str==null){
      return "";
    }else{
      return str;
    }
  }
}