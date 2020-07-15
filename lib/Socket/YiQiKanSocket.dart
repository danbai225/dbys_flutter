import 'dart:convert';
import 'package:better_socket/better_socket.dart';
import 'package:dbys/State/UserState.dart';

class YiQiKanSocket {
  YiQiKanSocket._internal();

  static YiQiKanSocket _yiQiKanSocket;
  //消息回调
  static var _roomListInfo;
  static var _join;
  static var _roomInfo;
  static var _sendChat;
  static bool onConn=false;
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
        if (_roomListInfo != null) {
          _roomListInfo(data);
        }
        break;
      case "join":
        if (_join != null) {
          _join(data);
        }
        break;
      case "roomInfo":
        if (_roomInfo != null) {
          _roomInfo(data);
        }
        break;
      case "sendChat":
        if (_sendChat != null) {
          _sendChat(data);
        }
        break;
    }
  }

  static conn() {
    if(UserState.ifLogin&&onConn==false) {
      BetterSocket.connentSocket(Uri.encodeFull("ws://dbys.vip/cinema/socket/${UserState.username}"),
          trustAllHost: true);
      BetterSocket.addListener(
          onOpen: (httpStatus, httpStatusMessage) {
            print(
                "onOpen---httpStatus:$httpStatus  httpStatusMessage:$httpStatusMessage");
          },
          onMessage: onMessage,
          onClose: onClose,
          onError: onError);
      onConn=true;
    }
  }

  static onClose(code, reason, remote) {
    if(code!=1000){
      BetterSocket.connentSocket(Uri.encodeFull("wss://dbys.vip/wss/cinema/socket/${UserState.username}"),
          trustAllHost: true);
    }
    print("onClose---code:$code  reason:$reason  remote:$remote");
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
    onConn=false;
    BetterSocket.close();
  }
}
