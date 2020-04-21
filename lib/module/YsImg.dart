import 'package:cached_network_image/cached_network_image.dart';
import 'package:dbys/Page/YsPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class YsImg extends StatefulWidget {
  YsImg({Key key, this.id, this.pm, this.url, this.zt}) : super(key: key);
  String url;
  String pm;
  int id;
  String zt;

  @override
  _YsImgState createState() => new _YsImgState();
}

class _YsImgState extends State<YsImg> {
  void onClick() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YsPage(
          id: widget.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        GestureDetector(
            onTap: onClick,
            child: Column(
              children: <Widget>[
                Container(
                  height: 142.5,
                  width: 100,
                  child: ClipRRect(
                      child: CachedNetworkImage(
                          fit: BoxFit.cover,
                          imageUrl: widget.url,
                          placeholder: (context, url) =>
                              Image.asset("assets/img/zw.png"),
                          errorWidget: (context, url, error) =>
                              Image.asset("assets/img/zw.png")),
                      borderRadius: BorderRadius.circular(8)),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            offset: Offset(0.0, 5.0), //阴影xy轴偏移量
                            blurRadius: 2.0, //阴影模糊程度
                            spreadRadius: 1.0 //阴影扩散程度
                            )
                      ]),
                ),
                Container(
                  width: 100,
                  child: Text(
                    widget.pm,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.blue),
                  ),
                )
              ],
            )),
        Positioned(
          left: 0,
          top: 120,
          child: Container(
            width: 110,
            color: Colors.green,
            child: Text(
              widget.zt,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        )
      ],
    );
  }
}
