import 'package:dbys/Page/HomePage.dart';
import 'package:dbys/Page/MePage.dart';
import 'package:dbys/Page/YiQiKanPage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:titled_navigation_bar/titled_navigation_bar.dart';
import 'ClassificationPage.dart';

class MainPage extends StatefulWidget {
  static int index = 0;

  MainPage({Key key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  List<Widget> _controllerList;

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
    return Scaffold(
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
            TitledNavigationBarItem(title: '首页', icon: Icons.home),
            TitledNavigationBarItem(title: '分类', icon: Icons.blur_on),
            TitledNavigationBarItem(title: '一起看', icon: Icons.add_to_queue),
            TitledNavigationBarItem(title: '我的', icon: Icons.account_circle),
          ]),
    );
  }
}
