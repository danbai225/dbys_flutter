
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


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
            onPressed: () async {
              Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
              SharedPreferences prefs = await _prefs;
              prefs.remove("UserNmae");
              setState(() {
              });
            },
          ),
        )
    );
  }
}

