import 'package:dbys/module/YsImg.dart';
import 'package:flutter/material.dart';

class TestPage extends StatefulWidget {
  TestPage({Key key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<TestPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
          child: CustomAnimatedContainer(),
        )
    );
  }
}

class CustomAnimatedContainer extends StatefulWidget {
  @override
  _CustomAnimatedContainerState createState() =>
      _CustomAnimatedContainerState();
}

class _CustomAnimatedContainerState extends State<CustomAnimatedContainer> {
  final Decoration startDecoration = BoxDecoration(
      color: Colors.blue,
      image: DecorationImage(
          image: AssetImage('assets/images/wy_200x300.jpg'), fit: BoxFit.cover),
      borderRadius: BorderRadius.all(Radius.circular(20)));
  final Decoration endDecoration = BoxDecoration(
      image: DecorationImage(
          image: AssetImage('assets/images/wy_200x300.jpg'), fit: BoxFit.cover),
      color: Colors.orange,
      borderRadius: BorderRadius.all(Radius.circular(50)));

  final Alignment startAlignment = Alignment(0, 0);
  final Alignment endAlignment = Alignment.topLeft + Alignment(0.2, 0.2);

  final startHeight = 100.0;
  final endHeight = 50.0;

  Decoration _decoration;
  double _height;
  Alignment _alignment;

  @override
  void initState() {
    _decoration = startDecoration;
    _height = startHeight;
    _alignment=startAlignment;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildSwitch(),
        AnimatedContainer(
          duration: Duration(seconds: 1),
          curve: Curves.fastOutSlowIn,
          alignment: _alignment,
          color: Colors.grey.withAlpha(22),
          width: 200,
          height: 120,
          child: UnconstrainedBox(
            child: AnimatedContainer(
              duration: Duration(seconds: 1),
              curve: Curves.fastOutSlowIn,
              decoration: _decoration,
              onEnd: () => print('End'),
              height: _height,
              width: _height,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitch() => Switch(
      value: _height == endHeight,
      onChanged: (v) {
        setState(() {
          _height = v ? endHeight : startHeight;
          _decoration = v ? endDecoration : startDecoration;
          _alignment = v ? endAlignment : startAlignment;
        });
      });
}