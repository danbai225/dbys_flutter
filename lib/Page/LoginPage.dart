import 'dart:convert';
import 'package:dbys/State/UserState.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController _unameController = new TextEditingController();
  TextEditingController _pwdController = new TextEditingController();
  bool pwdShow = false; //密码是否显示明文
  GlobalKey _formKey = new GlobalKey<FormState>();
  bool _nameAutoFocus = true;

  @override
  void initState() {
    ini();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  ini() async {
    // 自动填充上次登录的用户名，填充后将焦点定位到密码输入框
    String lastUsername = SpUtil.getString("LastUsername");
    _unameController.text = lastUsername;
    if (_unameController.text != null) {
      _nameAutoFocus = false;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("登录")),
        body: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            autovalidate: true,
            child: Column(
              children: <Widget>[
                TextFormField(
                    autofocus: _nameAutoFocus,
                    controller: _unameController,
                    decoration: InputDecoration(
                      labelText: '用户名',
                      hintText: '请输入用户名',
                      prefixIcon: Icon(Icons.person),
                    ),
                    // 校验用户名（不能为空）
                    validator: (v) {
                      return v.trim().isNotEmpty ? RegexUtil.matches("^[\u4e00-\u9fa5_a-zA-Z0-9]+\$",v)?null:"不能有符号" : '用户名不能为空';
                    }),
                TextFormField(
                  controller: _pwdController,
                  autofocus: !_nameAutoFocus,
                  decoration: InputDecoration(
                      labelText: '密码',
                      hintText: '请输入密码',
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                            pwdShow ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            pwdShow = !pwdShow;
                          });
                        },
                      )),
                  obscureText: !pwdShow,
                  //校验密码（不能为空）
                  validator: (v) {
                    return v.trim().isNotEmpty ? null : '密码不能为空';
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 25),
                  child: ConstrainedBox(
                    constraints: BoxConstraints.expand(height: 55.0),
                    child: RaisedButton(
                      color: Theme.of(context).primaryColor,
                      onPressed: _onLogin,
                      textColor: Colors.white,
                      child: Text('登录'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )));
  }

  void _onLogin() async {
    // 提交前，先验证各个表单字段是否合法
    if ((_formKey.currentState as FormState).validate()) {
      SpUtil.putString("LastUsername", _unameController.text);
      var response = await http.post("https://dbys.vip/api/v1/token", body: {
        'username': _unameController.text,
        'password': _pwdController.text
      });
      var data = await jsonDecode(response.body);
      if (data['data'] == null) {
        showDialog(false);
        var duration = new Duration(seconds: 2); //定义一个3秒种的时间
        new Future.delayed(duration, () {
          //设置定时执行
          //关闭弹窗
          yyDialog?.dismiss();
        });
      } else {
        //登陆成功
        SpUtil.putString("UserNmae", data['data']['username']);
        SpUtil.putString("Token", data['data']['token']);
        UserState.init();
        showDialog(true);
        var duration = new Duration(seconds: 1);
        new Future.delayed(duration, () {
          //设置定时执行
          //关闭弹窗
          yyDialog?.dismiss();
          Navigator.of(context).pop();
        });
      }
    }
  }

  var yyDialog;

  showDialog(bool B) {
    String gif;
    String msg;
    if (B) {
      gif = "assets/img/succeed.gif";
      msg = "登录成功!";
    } else {
      gif = "assets/img/err.gif";
      msg = "账号密码错误!";
    }
    yyDialog = YYDialog().build(context)
      ..width = 120
      ..height = 110
      ..backgroundColor = Colors.black.withOpacity(0.5)
      ..borderRadius = 10.0
      ..widget(Padding(
        padding: EdgeInsets.only(top: 21),
        child: Image.asset(
          gif,
          width: 40,
          height: 40,
        ),
      ))
      ..widget(Padding(
        padding: EdgeInsets.only(top: 10),
        child: Text(
          msg,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ))
      ..animatedFunc = (child, animation) {
        return ScaleTransition(
          child: child,
          scale: Tween(begin: 0.0, end: 1.0).animate(animation),
        );
      }
      ..show();
  }
}
