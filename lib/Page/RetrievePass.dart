import 'dart:convert';

import 'package:dbys/State/UserState.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';
import 'package:http/http.dart' as http;

class RetrievePassPage extends StatefulWidget {
  @override
  _RetrievePassPageState createState() => _RetrievePassPageState();
}

class _RetrievePassPageState extends State<RetrievePassPage> {
  TextEditingController _unameController = new TextEditingController();
  TextEditingController _pwdController = new TextEditingController();
  TextEditingController _pwdController2 = new TextEditingController();
  TextEditingController _emailController = new TextEditingController();
  TextEditingController _verificationController = new TextEditingController();
  bool pwdShow = false; //密码是否显示明文
  GlobalKey _formKey = new GlobalKey<FormState>();
  bool isv = false; //发送过验证码
  TimerUtil t; //验证码定时器
  int yzmTimer = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("找回密码")),
        body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                autovalidate: true,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                        controller: _unameController,
                        decoration: InputDecoration(
                          labelText: '用户名',
                          hintText: '请输入用户名',
                          prefixIcon: Icon(Icons.person),
                        ),
                        // 校验用户名（不能为空）
                        validator: (v) {
                          return v.length < 3 ? '用户名长度小于3' : RegexUtil.matches("^[\u4e00-\u9fa5_a-zA-Z0-9]+\$",v)?null:"不能有符号";
                        }),
                    TextFormField(
                      controller: _pwdController,
                      decoration: InputDecoration(
                          labelText: '密码',
                          hintText: '请输入新密码',
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
                        return v.length < 6 ? '密码长度小于6' : null;
                      },
                    ),
                    TextFormField(
                      controller: _pwdController2,
                      decoration: InputDecoration(
                          labelText: '确认密码',
                          hintText: '请输入确认密码',
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
                        if (_pwdController.text == v) {
                          return v.trim().isNotEmpty ? null : '密码不能为空';
                        }
                        return "密码不一致";
                      },
                    ),
                    TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                      decoration: InputDecoration(
                          labelText: '邮箱',
                          hintText: '请输入电子邮箱',
                          prefixIcon: Icon(Icons.email),
                          suffixIcon: isv
                              ? Text(yzmTimer.toString())
                              : FlatButton(
                            color: Theme.of(context).primaryColor,
                            child: Text("获取验证码"),
                            onPressed: () {
                              print(RegexUtil.isEmail(_emailController.text));
                              if (RegexUtil.isEmail(_emailController.text) &
                              (_unameController.text.length >= 3) &
                              !isv) {
                                print('ok');
                                getYzm();
                              }
                            },
                          )),
                      //校验密码（不能为空）
                      validator: (v) {
                        return (RegexUtil.isEmail(v)) ? null : "邮箱格式不正确";
                      },
                    ),
                    TextFormField(
                      keyboardType: TextInputType.number,
                      controller: _verificationController,
                      decoration: InputDecoration(
                          labelText: '邮箱验证码(如果没收到，请检查垃圾邮箱)',
                          hintText: '请输入邮箱验证码',
                          prefixIcon: Icon(Icons.verified_user)),
                      //校验密码（不能为空）
                      validator: (v) {
                        return v.trim().isNotEmpty ? null : '验证码不能为空';
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 25),
                      child: ConstrainedBox(
                        constraints: BoxConstraints.expand(height: 55.0),
                        child: RaisedButton(
                          color: Theme.of(context).primaryColor,
                          onPressed: _onRegistert,
                          textColor: Colors.white,
                          child: Text('重新设置密码'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )));
  }

  _onRegistert() async {
    // 提交前，先验证各个表单字段是否合法
    if ((_formKey.currentState as FormState).validate()) {
      var response = await http.post("https://dbys.vip/api/v1/forgetPass", body: {
        'username': _unameController.text,
        'password': _pwdController.text,
        'email': _emailController.text,
        'yzm': _verificationController.text
      });
      var json = jsonDecode(response.body);
      print(json['msg']);
      showDialog(json['msg']);
      if (json['msg'] == "修改成功") {
        SpUtil.putString("LastUsername", _unameController.text);
        var response = await http.post("https://dbys.vip/api/v1/token", body: {
          'username': _unameController.text,
          'password': _pwdController.text
        });
        var data = await jsonDecode(response.body);
        if (data['data'] == null) {
        } else {
          //登陆成功
          SpUtil.putString("UserNmae", data['data']['username']);
          SpUtil.putString("Token", data['data']['token']);
          UserState.init();
        }
        var duration = new Duration(seconds: 1); //定义一个3秒种的时间
        new Future.delayed(duration, () {
          //设置定时执行
          //关闭弹窗
          yyDialog?.dismiss();
          t.cancel();
          Navigator.of(context).pop();
        });
      }
    }
  }

  getYzm() {
    isv = true;
    yzmTimer = 30;
    http.get("https://dbys.vip/getvalidate?email=" +
        _emailController.text +
        "&username=" +
        _unameController.text);
    t = TimerUtil();
    t.setInterval(1000);
    t.setTotalTime(30);
    t.setOnTimerTickCallback((int tick) {
      setState(() {
        yzmTimer = 30 - tick;
        if (yzmTimer == 0) {
          isv = false;
          t.cancel();
        }
      });
    });
    t.startTimer();
  }

  var yyDialog;

  showDialog(String msg) {
    yyDialog = YYDialog().build(context)
      ..width = 120
      ..height = 40
      ..backgroundColor = Colors.black.withOpacity(0.5)
      ..borderRadius = 10.0
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
