import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class YiQiKanPage extends StatefulWidget{
  YiQiKanPage({Key key}) : super(key: key);
  @override
  _YiQiKanPageState createState() => _YiQiKanPageState();
}

class _YiQiKanPageState extends State<YiQiKanPage>{
  bool iflogin=false;
  @override
  void initState() {
    super.initState();
    init();
  }
  init() async {
    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    SharedPreferences prefs = await _prefs;
    String user = prefs.getString("User");
    if(user!=null){
      iflogin=true;
      setState(() {
      });
    }
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          child: AppBar(
            title: Text("分类"),
            centerTitle: true,
          ),
          preferredSize:
          Size.fromHeight(MediaQuery.of(context).size.height * 0.05),
        ),
        body: !iflogin?Center(
            child: Container(height:200,child:Column(children: <Widget>[
              Text("请先登录哦!",textScaleFactor: 1.5,),
              RaisedButton(
                elevation: 5,
                child: Text("登录"),
                onPressed: (){
                  Navigator.of(this.context).pushNamed("/LoginPage"); //执行跳转代码
                },
              ),RaisedButton(
                elevation: 5,
                child: Text("注册"),
                onPressed: (){
                  Navigator.of(this.context).pushNamed("/RegPage"); //执行跳转代码
                },
              )
            ]))
        ):Center(
          child: Text("已登录"),
        )
    );
  }
}

