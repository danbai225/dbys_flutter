import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'YsPage.dart';
class ClassificationPage extends StatefulWidget {
  ClassificationPage({Key key}) : super(key: key);

  @override
  _ClassificationPageState createState() => _ClassificationPageState();
}

class _ClassificationPageState extends State<ClassificationPage> {
  List type1List = ['电影', '电视剧', '动漫', '综艺'];
  List type2List = ['全部','动作', '喜剧', '爱情', '科幻','恐怖','剧情','战争'];
  List regionList = ['全部','国产', '美国', '印度', '澳大利亚','日本','法国','香港','韩国','加拿大','英国','西班牙','泰国','台湾',
    '俄罗斯','新加坡','意大利','爱尔兰','墨西哥','马来西亚','葡萄牙','荷兰','巴西','其他'];
  List yearList =['全部'];
  List sortList = ['更新', '评分'];
  String type1Index='电影';
  String type2Index='全部';
  String regionIndex='全部';
  String yearIndex='全部';
  String sortIndex='更新';
  var dataList=[];
  int page=1;
  ScrollController _scrollController;
  bool showToTopBtn=false;
  @override
  void initState() {
    super.initState();
    _scrollController = new ScrollController();
    var date = new DateTime.now();
    List.generate(40, (i)=>{
      yearList.add((date.year-i).toString())
    });
    swTag();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        swTag();
      }
      if (_scrollController.offset < 1000 && showToTopBtn) {
        setState(() {
          showToTopBtn = false;
        });
      } else if (_scrollController.offset >= 1000 && showToTopBtn == false) {
        setState(() {
          showToTopBtn = true;
        });
      }
    });
  }

  swTag() async{
    page++;
    if(page==1){
      dataList=[];
    }
    var response = await http.get("http://sg-na-cn2.sakurafrp.com:57914/api/v1/ys/type?type1="+type1Index+"&type2="+type2Index+"&region="+regionIndex+"&year="+yearIndex+"&sort="+sortIndex+"&page="+page.toString());
    var json = await jsonDecode(response.body);
    setState(() {
      dataList+=json['data'];
    });
  }
  @override
  void dispose() {
    _scrollController.dispose();
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
        body: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: <Widget>[
              Container(
                height: 30,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: <Widget>[
                    TagButtons(
                      list: type1List,
                      callback: (index) => {
                        type1Index = index,page=0,swTag()
                      },
                    )
                  ],
                ),
              ),Container(
                height:30,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: <Widget>[
                    TagButtons(
                      list: type2List,
                      callback: (index) => {type2Index = index,page=0,swTag()},
                    )
                  ],
                ),
              ),Container(
                height: 30,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: <Widget>[
                    TagButtons(
                      list: regionList,
                      callback: (index) => {regionIndex = index,page=0,swTag()},
                    )
                  ],
                ),
              ),Container(
                height: 30,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: <Widget>[
                    TagButtons(
                      list: yearList,
                      callback: (index) => {yearIndex = index,page=0,swTag()},
                    )
                  ],
                ),
              ),Container(
                height: 30,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: <Widget>[
                    TagButtons(
                      list: sortList,
                      callback: (index) => {sortIndex = index,page=0,swTag()},
                    )
                  ],
                ),
              ),
              Column(
                    children: dataList
                        .map((ys) => GestureDetector(
                      onTap: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => YsPage(
                              id: ys['id'],
                            ),
                          ),
                        );
                      },
                        child:
                        Container(
                        height: 100,
                        margin: EdgeInsets.all(2.0),
                        child:Row(
                          children: <Widget>[
                            CachedNetworkImage(imageUrl: ys['tp'],  placeholder: (context, url) => Image.asset("assets/img/zw.png"),
                              errorWidget: (context, url, error) => Image.asset("assets/img/zw.png"),),
                            Column(children: <Widget>[
                              Container(
                                width: (MediaQuery.of(context).size.width-100),
                                child: Text(ys['pm'],overflow:TextOverflow.ellipsis,style: TextStyle(
                                  fontWeight: FontWeight.w100,fontSize: 16,
                                ),textAlign: TextAlign.left),
                              )
                              ,
                              Container(
                                width: (MediaQuery.of(context).size.width-100),
                                child: Text('导演:'+ys['dy'],overflow:TextOverflow.ellipsis,style: TextStyle(
                                    fontSize: 13,color: Colors.grey
                                ),textAlign: TextAlign.left),
                              ),
                              Container(
                                width: (MediaQuery.of(context).size.width-100),
                                child: Text('主演:'+ys['zy'],overflow:TextOverflow.ellipsis,style: TextStyle(
                                    fontSize: 13,color: Colors.grey
                                ),textAlign: TextAlign.left),
                              ),Container(
                                  width: (MediaQuery.of(context).size.width-100) ,
                                  child: Text('介绍:'+ys['js'],overflow:TextOverflow.ellipsis,style: TextStyle(
                                      fontSize: 10,color: Colors.grey
                                  ),textAlign: TextAlign.left,maxLines: 2)
                              )
                            ],)

                          ],
                        )
                    ))).toList()
                ) ,
            ],
          ),
        ),
        floatingActionButton:!showToTopBtn?null:
     FloatingActionButton(
            elevation: 0,
            child: Icon(
              Icons.arrow_upward,
            ),
            onPressed: () {
        _scrollController.animateTo(.0,
    duration: Duration(milliseconds: 200),
    curve: Curves.ease
    );
            },
       mini: true,
       tooltip: "返回顶部",
          ),


      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class TagButtons extends StatefulWidget {
  TagButtons({Key key, this.list, this.callback}) : super(key: key);
  var callback;
  List list;
  @override
  _TagButtonsState createState() => _TagButtonsState();
}

class _TagButtonsState extends State<TagButtons> {
  var _isSelected=[true];
  String getIndexString() {
    for (int i = 0; i < _isSelected.length; i++) {
      if (_isSelected[i]) {
        return widget.list[i];
      }
    }
    return widget.list[0];
  }

  @override
  void initState() {
    super.initState();
    List.generate(widget.list.length-1, (i)=>{
      _isSelected.add(false)
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      children: widget.list.map((item) {
        return Text(item);
      }).toList(),
      borderWidth: 1,
      borderRadius: BorderRadius.circular(10),
      isSelected: _isSelected,
      onPressed: (value) => setState(() {
        _isSelected = _isSelected.map((e) => false).toList();
        _isSelected[value] = true;
        widget.callback(getIndexString());
      }),
    );
  }
}
