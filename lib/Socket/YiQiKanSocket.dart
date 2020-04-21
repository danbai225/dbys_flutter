import 'dart:convert';
import 'package:better_socket/better_socket.dart';

class YiQiKanSocket {
  YiQiKanSocket._internal();

  static YiQiKanSocket _yiQiKanSocket;
  static String _username;

  //消息回调
  static var _roomListInfo;
  static var _join;
  static var _roomInfo;
  static var _sendChat;

  static send(String msg) {
    if (msg.isNotEmpty) {
      BetterSocket.sendMsg(msg);
    }
  }

  static setRoomListInfoCallBack(var back) {
      _roomListInfo = back;
  }

  static setJoinCallBack(var back) {
      _join = back;
  }

  static setRoomInfoCallBack(var back) {
      _roomInfo = back;
  }

  static setSendChatCallBack(var back) {
      _sendChat = back;
  }

  static onMessage(msg) {
    var data = jsonDecode(msg);
    switch (data['type']) {
      case "info":
        if(_roomListInfo!=null){
          _roomListInfo(data);
        }
        break;
      case "join":
        if(_join!=null){
          _join(data);
        }
        break;
      case "roomInfo":
        if(_roomInfo!=null){
          _roomInfo(data);
        }
        break;
      case "sendChat":
        if(_sendChat!=null){
          _sendChat(data);
        }
        break;
    }
  }

  static conn(String username) {
    _username = username;
    BetterSocket.connentSocket("wss://dbys.vip/wss/cinema/socket/$_username",
        trustAllHost: true);
    BetterSocket.addListener(
        onOpen: (httpStatus, httpStatusMessage) {
          print(
              "onOpen---httpStatus:$httpStatus  httpStatusMessage:$httpStatusMessage");
        },
        onMessage: onMessage,
        onClose: onClose,
        onError: onError);
  }

  static onClose(code, reason, remote) {
    print("onClose---code:$code  reason:$reason  remote:$remote");
    BetterSocket.connentSocket("wss://dbys.vip/wss/cinema/socket/$_username",
        trustAllHost: true);
  }

  static onError(message) {
    print("onErrorSokcet");
  }

  static YiQiKanSocket getYiQiKanSocket() {
    // 只能有一个实例
    if (_yiQiKanSocket == null) {
      _yiQiKanSocket = YiQiKanSocket._internal();
    }
    return _yiQiKanSocket;
  }

  static close() {
    BetterSocket.close();
  }
}
