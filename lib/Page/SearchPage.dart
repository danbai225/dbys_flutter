
import 'dart:convert';

import 'package:dbys/module/YsImg.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SearchPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController textController = TextEditingController();
  ScrollController scrollController = ScrollController();
  List ySList = [];
  String tip = "";
  double barHeight = 45;
  double barOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      setState(() {
        if (scrollController.offset > 200 && scrollController.offset <= 250) {
          barOpacity = ((250 - scrollController.offset) / 50);
          if (barOpacity < 0.1) {
            barHeight = 0;
          } else {
            barHeight = 45;
          }
        }
      });
    });

    textController.addListener(() {
      setState(() {
        barOpacity = 1;
      });
    });
  }

  sou() async {
    var response = await http
        .get("https://dbys.vip/api/v1/ys/search/" + textController.text);
    var data = await jsonDecode(response.body);
    ySList = data['data'];
    if(ySList!=null){
      tip = '找到关于"' +
          textController.text +
          '"的影视一共' +
          ySList.length.toString() +
          '部';
    }
    setState(() {});
  }

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          child: Opacity(
            opacity: barOpacity,
            child: AppBar(
                actions: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.search),
                    // 如果有抽屉的话的就打开
                    onPressed: () {
                      sou();
                    },
                    // 显示描述信息
                    tooltip: "搜索",
                  )
                ],
                centerTitle: true,
                title: TextField(
                  controller: textController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (s) => {sou()},
                  autofocus: true,
                  style: TextStyle(fontSize: 20),
                  decoration: new InputDecoration(
                    hintText: '输入片名/演员/导演',
                    border: InputBorder.none,
                    suffix: textController.text == ""
                        ? null
                        : IconButton(
                            icon: Icon(Icons.cancel, size: 15),
                            onPressed: () {
                              textController.text = "";
                            },
                          ),
                  ),
                ),
                // leading: ,
                // 现在标题前面的Widget，一般为一个图标按钮，也可以是任意Widget
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
          ),
          preferredSize: Size.fromHeight(barHeight)),
      body: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          children: <Widget>[
            Text(tip),
            Center(
              child: Wrap(
                  children: ySList
                      .map((ys) => Container(
                          margin: EdgeInsets.all(2.0),
                          child: YsImg(
                            url: ys['tp'],
                            pm: ys['pm'],
                            id: ys['id'],
                            zt: ys['zt'],
                          )))
                      .toList()),
            )
          ],
        ),
      ),
    );
  }
}
