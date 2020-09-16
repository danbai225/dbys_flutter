import 'dart:convert';

import 'package:dbys/Page/Download/DownloadYsPage.dart';
import 'package:dbys/Page/TvPage.dart';
import 'package:dbys/State/UserState.dart';
import 'package:dbys/module/YsImg.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';
import 'package:flutter_page_tracker/flutter_page_tracker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with PageTrackerAware, TrackerPageMixin {
  List tuiJianYs = [];
  List dyList = [];
  List dsjList = [];
  List zyList = [];
  List dmList = [];
  String gg = "";
  TextEditingController bugTextController = TextEditingController();
  TextEditingController qiuPianTextController = TextEditingController();
  bool autoPlayerNext=SpUtil.getBool("AoutPlayerNext");
  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  void didPageView() {
    super.didPageView();
    setState(() {});
    // 发送页面露出事件
  }

  @override
  void didPageExit() {
    super.didPageExit();
    // 发送页面离开事件
  }

  fetchData() async {
    String syData = SpUtil.getString("syData");
    gg = SpUtil.getString("gg");
    var data;
    if (syData != "") {
      data = await jsonDecode(syData);
      SpUtil.remove("syData");
    } else {
      // 请求接口
      var response = await http.get("https://dbys.vip/sy");
      data = await jsonDecode(response.body);
    }
    // 将接口返回数据转成json
    tuiJianYs = data['tj'];
    dyList = data['dy'];
    dsjList = data['dsj'];
    zyList = data['zy'];
    dmList = data['dm'];
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //添加侧滑菜单Widget
      drawer: Drawer(
          child: ListView(
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Center(
              child: SizedBox(
                width: 100.0,
                height: 80.0,
                child: Column(
                  children: <Widget>[
                    CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(UserState.headUrl == null
                            ? "http://danbai.oss-cn-chengdu.aliyuncs.com/img/2019/12/06/3027a00827e93.png"
                            : UserState.headUrl)),
                    Text(UserState.ifLogin ? UserState.username : "未登录")
                  ],
                ),
              ),
            ),
          ),
          Text("公告:$gg"),
          ListTile(
            leading: Switch(
              value: autoPlayerNext,
              onChanged: (v)=>{
                autoPlayerNext=!autoPlayerNext,
                SpUtil.putBool("AoutPlayerNext", autoPlayerNext),
                setState(() {})
              },
            ),
            title: Text("自动播放下一集"),
          ),
          ListTile(
            leading: Icon(Icons.bug_report),
            title: MaterialButton(
              child: Text("反馈bug"),
              onPressed: () {
                showFeedbackDialog(1);
              },
            ),
          ),
          ListTile(
            leading: Icon(Icons.assignment_turned_in),
            title: MaterialButton(
              child: Text("求片"),
              onPressed: () {
                showFeedbackDialog(2);
              },
            ),
          ),
          ListTile(
            leading: Icon(Icons.tv),
            title: MaterialButton(
              child: Text("电视直播"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TvPage(),
                  ),
                );
              },
            ),
          ),
          ListTile(
            leading: Icon(Icons.file_download),
            title: MaterialButton(
              child: Text("下载"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DownloadYsPage(),
                  ),
                );
              },
            ),
          ),
          UserState.ifLogin
              ? ListTile(
                  leading: Icon(Icons.exit_to_app),
                  title: MaterialButton(
                      child: Text("退出登录"),
                      onPressed: () {
                        UserState.exitLogin();
                        setState(() {});
                      }),
                )
              : ListTile(
                  leading: Icon(Icons.near_me),
                  title: MaterialButton(
                      child: Text("登录"),
                      onPressed: () {
                        Navigator.of(this.context).pushNamed("/LoginPage");
                      }),
                ),
          ListTile(
            leading: Icon(Icons.info),
            title: MaterialButton(
              child: Text("关于APP"),
              onPressed: () {
                showDialog(
                    context: context, builder: (ctx) => _buildAboutDialog());
              },
            ),
          )
        ],
      )),
      appBar: PreferredSize(
          child: AppBar(
              actions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.search),
                  // 如果有抽屉的话的就打开
                  onPressed: () {
                    Navigator.of(context).pushNamed("/SearchPage"); //执行跳转代码
                  },
                  // 显示描述信息
                  tooltip: "打开搜索",
                )
              ],
              centerTitle: true,
              title: Text("淡白影视"),
              // leading: ,
              // 现在标题前面的Widget，一般为一个图标按钮，也可以是任意Widget
              leading: Builder(
                builder: (BuildContext context) {
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    // 如果有抽屉的话的就打开
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    // 显示描述信息
                    tooltip: "打开菜单",
                  );
                },
              )),
          preferredSize: Size.fromHeight(40)),
      body: SingleChildScrollView(
          child: Column(
        children: <Widget>[
          Card(child: Text("公告:$gg"),),
          Text("推荐影视",
              style: TextStyle(
                fontSize: 18,
                color: Colors.green
              )),
          Container(
              height: 170,
              child: ListView(
                  // This next line does the trick.
                  scrollDirection: Axis.horizontal,
                  children: tuiJianYs
                      .map((ys) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 2.0),
                          child: YsImg(
                            url: ys['tp'],
                            pm: ys['pm'],
                            id: ys['id'],
                            zt: ys['zt'],
                          )))
                      .toList())),
          Text("最新电影",
              style: TextStyle(
                fontSize: 18,
              )),
          Container(
              height: 170,
              child: ListView(
                  // This next line does the trick.
                  scrollDirection: Axis.horizontal,
                  children: dyList
                      .map((ys) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 2.0),
                          child: YsImg(
                            url: ys['tp'],
                            pm: ys['pm'],
                            id: ys['id'],
                            zt: ys['zt'],
                          )))
                      .toList())),
          Text("最新电视剧",
              style: TextStyle(
                fontSize: 18,
              )),
          Container(
              height: 170,
              child: ListView(
                  // This next line does the trick.
                  scrollDirection: Axis.horizontal,
                  children: dsjList
                      .map((ys) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 2.0),
                          child: YsImg(
                            url: ys['tp'],
                            pm: ys['pm'],
                            id: ys['id'],
                            zt: ys['zt'],
                          )))
                      .toList())),
          Text("最新综艺",
              style: TextStyle(
                fontSize: 18,
              )),
          Container(
              height: 170,
              child: ListView(
                  // This next line does the trick.
                  scrollDirection: Axis.horizontal,
                  children: zyList
                      .map((ys) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 2.0),
                          child: YsImg(
                            url: ys['tp'],
                            pm: ys['pm'],
                            id: ys['id'],
                            zt: ys['zt'],
                          )))
                      .toList())),
          Text("最新动漫",
              style: TextStyle(
                fontSize: 18,
              )),
          Container(
              height: 170,
              child: ListView(
                  // This next line does the trick.
                  scrollDirection: Axis.horizontal,
                  children: dmList
                      .map((ys) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 2.0),
                          child: YsImg(
                            url: ys['tp'],
                            pm: ys['pm'],
                            id: ys['id'],
                            zt: ys['zt'],
                          )))
                      .toList())),
          Text("免责声明",style: TextStyle(
            fontSize: 14,
          )),
          Text('本应用所有内容都是靠程序在互联网上自动搜集而来,仅供测试和学习交流。',textAlign: TextAlign.center,),
          Text('目前正在逐步删除和规避程序自动搜索采集到的不提供分享的版权影视。',textAlign: TextAlign.center,),
          Text('若侵犯了您的权益，请即时发邮件通知站长 万分感谢！',textAlign: TextAlign.center,),
          Text('db225@qq.com ♥ 淡白影视 ',textAlign: TextAlign.center,)
        ],
      )),
    );
  }



  showFeedbackDialog(int type) {
    YYDialog().build(context)
      ..width = MediaQuery.of(context).size.width * 0.6
      ..borderRadius = 4.0
      ..text(
        padding: EdgeInsets.all(18.0),
        text: type == 1 ? "问题反馈:" : "求片反馈",
        color: Colors.grey[700],
      )
      ..widget(Container(
        margin: EdgeInsets.all(20.0),
        child: TextField(
            controller: type == 1 ? bugTextController : qiuPianTextController,
            keyboardType: TextInputType.multiline,
            maxLines: 10,
            minLines: 5,
            decoration: const InputDecoration(
              hintText: "内容描述请输入",
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              isDense: true,
              border: const OutlineInputBorder(
                gapPadding: 0,
                borderRadius: const BorderRadius.all(Radius.circular(4)),
                borderSide: BorderSide(
                  width: 1,
                  style: BorderStyle.none,
                ),
              ),
            )),
      ))
      ..divider()
      ..doubleButton(
        padding: EdgeInsets.only(top: 10.0),
        gravity: Gravity.center,
        withDivider: true,
        text1: "取消",
        fontSize1: 14.0,
        fontWeight1: FontWeight.bold,
        text2: "提交",
        fontSize2: 14.0,
        fontWeight2: FontWeight.bold,
        onTap2: () {
          String content;
          if(type==1){
            content=bugTextController.text;
            bugTextController.clear();
          }else{
            content=qiuPianTextController.text;
            qiuPianTextController.clear();
          }
          if (content != "") {
            http.post("https://dbys.vip/api/v1/feedback", body: {
              "type": type.toString(),
              "content": content
            });
            Fluttertoast.showToast(
                msg: "已提交",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: Theme.of(context).accentColor,
                textColor: Colors.white,
                fontSize: 16.0);
          }
        },
      )
      ..show();
  }

  AboutDialog _buildAboutDialog() {
    return AboutDialog(
      applicationIcon: FlutterLogo(),
      applicationVersion: 'v1.1.4',
      applicationName: '淡白影视',
      applicationLegalese: 'Copyright© 2020 淡白',
      children: <Widget>[
        Container(
            margin: EdgeInsets.only(top: 10),
            width: 60,
            height: 60,
            child: Image.asset('assets/img/ico.png')),
        Container(
            margin: EdgeInsets.only(top: 10),
            alignment: Alignment.center,
            child: Text(
              '看你想看',
              style: TextStyle(color: Colors.white, fontSize: 20, shadows: [
                Shadow(
                    color: Colors.blue, offset: Offset(.5, .5), blurRadius: 3)
              ]),
            )),
        MaterialButton(
            child: Text(
              "作者博客",
              style: TextStyle(color: Colors.blue),
            ),
            onPressed: () async {
              const url = 'https://p00q.cn';
              if (await canLaunch(url)) {
                await launch(url);
              } else {
                throw 'Could not launch $url';
              }
            }),
      ],
    );
  }
}
