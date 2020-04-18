
import 'package:flutter/material.dart';


class TestPage extends StatefulWidget{
  TestPage({Key key}) : super(key: key);
  @override
  _TestState createState() => _TestState();
}

class _TestState extends State<TestPage>{
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
        body: Center(
          child: IconButton(
            icon: Icon(Icons.add),
            onPressed: (){
              setState(() {
              });
            },
          ),
        )
    );
  }
}

