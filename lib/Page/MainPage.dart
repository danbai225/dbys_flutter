import 'dart:io';

import 'package:dbys/Page/HomePage.dart';
import 'package:dbys/Page/MePage.dart';
import 'package:dbys/Page/YiQiKanPage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:titled_navigation_bar/titled_navigation_bar.dart';
import 'ClassificationPage.dart';
import 'Download/DownloadManagement.dart';

class MainPage extends StatefulWidget {
  static int index = 0;

  MainPage({Key key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  List<Widget> _controllerList;
  DateTime lastPopTime;

  @override
  void initState() {
    super.initState();
    _controllerList = [
      new HomePage(),
      new ClassificationPage(),
      new YiQiKanPage(),
      new MePage()
    ];
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        body: IndexedStack(
          index: this._currentIndex,
          children: this._controllerList,
        ),
        bottomNavigationBar: TitledBottomNavigationBar(
            currentIndex: _currentIndex,
            // Use this to update the Bar giving a position
            onTap: (index) {
              setState(() {
                _currentIndex = index;
                MainPage.index = index;
              });
            },
            items: [
              TitledNavigationBarItem(title:Text('首页'), icon: Icons.home),
              TitledNavigationBarItem(title: Text('分类'), icon: Icons.blur_on),
              TitledNavigationBarItem(title: Text('一起看'), icon: Icons.add_to_queue),
              TitledNavigationBarItem(title: Text('我的'), icon: Icons.account_circle),
            ]),
        // ignore: missing_return
      ),
      onWillPop: () {
        // 点击返回键的操作
        if (lastPopTime == null ||
            DateTime.now().difference(lastPopTime) > Duration(seconds: 2)) {
          lastPopTime = DateTime.now();
          Fluttertoast.showToast(
              msg: "再按一次退出",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Theme.of(context).accentColor,
              textColor: Colors.black,
              fontSize: 16.0);
        } else {
          lastPopTime = DateTime.now();
          DownloadManagement.removeBind();
          // 退出app
          exit(0);
        }
      },
    );
  }
}
