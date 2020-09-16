import 'dart:async';
import 'dart:math';

import 'package:chewie/src/chewie_player.dart';
import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:chewie/src/material_progress_bar.dart';
import 'package:chewie/src/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_light_plugin/flutter_light_plugin.dart';
import 'package:video_player/video_player.dart';
import 'package:volume/volume.dart';

class CustomControls extends StatefulWidget {
  const CustomControls({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MaterialControlsState();
  }
}

class _MaterialControlsState extends State<CustomControls> {
  VideoPlayerValue _latestValue;
  double _latestVolume;
  bool _hideStuff = true;
  Timer _hideTimer;
  Timer _initTimer;
  Timer _showAfterExpandCollapseTimer;
  bool _dragging = false;
  bool _displayTapped = false;

  final barHeight = 48.0;
  final marginSize = 5.0;

  VideoPlayerController controller;
  ChewieController chewieController;
  DateTime now;
  double beginY;
  int beginV;
  int maxV;
  double maxLight;
  double beginLight;
  int beginTime;
  double beginX;
  int spkTime = 0;
  double pSpeed=1.0;
  @override
  Widget build(BuildContext context) {
    if (_latestValue.hasError) {
      return chewieController.errorBuilder != null
          ? chewieController.errorBuilder(
              context,
              chewieController.videoPlayerController.value.errorDescription,
            )
          : Center(
              child: Icon(
                Icons.error,
                color: Colors.white,
                size: 42,
              ),
            );
    }
    return Stack(
      children: <Widget>[
        Align(
            //防止logo一只在一个位置烧屏(玄学)
            alignment: DateTime.now().minute > 30
                ? FractionalOffset.topLeft
                : FractionalOffset.bottomRight,
            child: Transform(
              alignment: Alignment.center,
              child: Image.asset(
                "assets/img/logo.png",
                width: chewieController.isFullScreen ? 50 : 30,
              ),
              transform: Matrix4.rotationZ(DateTime.now().second / 60 * pi * 2),
            )),
        Align(
            alignment: FractionalOffset.topCenter,
            child: spkTime != 0
                ? Text(
                    "快进:$spkTime秒",
                    style: TextStyle(fontSize: 20, color: Colors.blue),
                  )
                :null),
        Align(
            alignment: FractionalOffset.topRight,
            child: DateTime.now().minute==59
                ? Text(
              "现在时间:"+DateTime.now().hour.toString()+":"+DateTime.now().minute.toString()+":"+DateTime.now().second.toString(),
              style: TextStyle(fontSize: 20, color: Colors.white),
            )
                :null),
        MouseRegion(
          onHover: (_) {
            _cancelAndRestartTimer();
          },
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              //调音量
              if (details.globalPosition.dx <
                  (MediaQuery.of(context).size.width / 2)) {
                Volume.setVol(
                    (beginV -
                        ((details.globalPosition.dy - beginY) * 0.05).toInt()),
                    showVolumeUI: ShowVolumeUI.SHOW);
              } else {
                //亮度
                if (DateTime.now().difference(now).inMilliseconds > 500) {
                  beginLight =
                      beginLight - ((details.globalPosition.dy - beginY) * 0.05);
                  setLight();
                }
              }
            },
            //长按倍速播放
            onLongPress: (){
              setState(() {
                controller.setSpeed(2.0);
              });
            },
    onLongPressEnd:(e){

      setState(() {
        controller.setSpeed(pSpeed);
      });
    },
    onVerticalDragDown: (e) async {
              now = new DateTime.now();
              beginY = e.globalPosition.dy;
              beginX=e.globalPosition.dx;
              beginV = await Volume.getVol;
              maxV = await Volume.getMaxVol;
            },
            onHorizontalDragUpdate: (e) {
              //进度
              spkTime = ((e.globalPosition.dx - beginX) * 0.1).toInt();
              setState(() {});
            },
            onHorizontalDragEnd: (e) {
              controller.seekTo(Duration(seconds: beginTime + spkTime));
              spkTime = 0;
              if (!_latestValue.isPlaying) {
                _playPause();
              }
            },
            onVerticalDragEnd: (e) {
              //简单调节两端 右半屏 上下滑动加减 10%的亮度  时间在0.5s内为简单调节 否则为精度调节
              if (DateTime.now().difference(now).inMilliseconds < 500&&beginX>(MediaQuery.of(context).size.width / 2)) {
                print(beginLight);
                if (e.primaryVelocity > 0) {
                  beginLight -=maxLight*0.1;
                }
                if (e.primaryVelocity < 0) {
                  beginLight += maxLight*0.1;
                }
                print(beginLight);
                setLight();
              }
            },
            onHorizontalDragDown: (e) async {
              var d = await controller.position;
              beginTime = d.inSeconds;
              beginX = e.globalPosition.dx;
            },
            onTap: () => _cancelAndRestartTimer(),
            child: AbsorbPointer(
              absorbing: _hideStuff,
              child: Column(
                children: <Widget>[
                  _latestValue != null &&
                              !_latestValue.isPlaying &&
                              _latestValue.duration == null ||
                          _latestValue.isBuffering
                      ? const Expanded(
                          child: const Center(
                            child: const CircularProgressIndicator(),
                          ),
                        )
                      : _buildHitArea(),
                  _buildBottomBar(context),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  setLight() {
    if (beginLight < 0) {
      beginLight = 0;
    }
    if (beginLight > maxLight) {
      beginLight = maxLight;
    }
    FlutterLightPlugin.setLight(beginLight);
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    final _oldController = chewieController;
    chewieController = ChewieController.of(context);
    controller = chewieController.videoPlayerController;

    if (_oldController != chewieController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  AnimatedOpacity _buildBottomBar(
    BuildContext context,
  ) {
    final iconColor = Theme.of(context).textTheme.button.color;
    List strSpeed = ["1.0", "1.25", "1.5", "1.75", "2.0", "2.5","0.7", "0.5"];
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: Duration(milliseconds: 300),
      child: Container(
        height: barHeight,
        color: Theme.of(context).dialogBackgroundColor,
        child: Row(
          children: <Widget>[
            _buildPlayPause(controller),
            chewieController.isLive
                ? Expanded(child: const Text('LIVE'))
                : _buildPosition(iconColor),
            chewieController.isLive ? const SizedBox() : _buildProgressBar(),
            chewieController.isLive
                ? Container()
                : Container(
                    child: CupertinoPicker(
                      itemExtent: 20,
                      onSelectedItemChanged: (value) {
                        pSpeed=double.parse(strSpeed[value]);
                        setState(() {
                          controller.setSpeed(pSpeed);
                        });
                      },
                      children: strSpeed.map((data) {
                        return Text(
                          data.toString(),
                          style: TextStyle(fontSize: 13),
                        );
                      }).toList(),
                    ),
                    width: 30,
                    height: 40,
                  ),
            chewieController.allowMuting
                ? _buildMuteButton(controller)
                : Container(),
            chewieController.allowFullScreen
                ? _buildExpandButton()
                : Container(),
          ],
        ),
      ),
    );
  }

  GestureDetector _buildExpandButton() {
    return GestureDetector(
      onTap: _onExpandCollapse,
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: Container(
          height: barHeight,
          margin: EdgeInsets.only(right: 12.0),
          padding: EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Center(
            child: Icon(
              chewieController.isFullScreen
                  ? Icons.fullscreen_exit
                  : Icons.fullscreen,
            ),
          ),
        ),
      ),
    );
  }

  Expanded _buildHitArea() {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_latestValue != null && _latestValue.isPlaying) {
            if (_displayTapped) {
              setState(() {
                _hideStuff = true;
              });
            } else
              _cancelAndRestartTimer();
          } else {
            _playPause();

            setState(() {
              _hideStuff = true;
            });
          }
        },
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: AnimatedOpacity(
              opacity:
                  _latestValue != null && !_latestValue.isPlaying && !_dragging
                      ? 1.0
                      : 0.0,
              duration: Duration(milliseconds: 300),
              child: GestureDetector(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).dialogBackgroundColor,
                    borderRadius: BorderRadius.circular(48.0),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Icon(Icons.play_arrow, size: 32.0),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildMuteButton(
    VideoPlayerController controller,
  ) {
    return GestureDetector(
      onTap: () {
        _cancelAndRestartTimer();

        if (_latestValue.volume == 0) {
          controller.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          controller.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: ClipRect(
          child: Container(
            child: Container(
              height: barHeight,
              padding: EdgeInsets.only(
                left: 8.0,
                right: 8.0,
              ),
              child: Icon(
                (_latestValue != null && _latestValue.volume > 0)
                    ? Icons.volume_up
                    : Icons.volume_off,
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildPlayPause(VideoPlayerController controller) {
    return GestureDetector(
      onTap: _playPause,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        margin: EdgeInsets.only(left: 8.0, right: 4.0),
        padding: EdgeInsets.only(
          left: 12.0,
          right: 12.0,
        ),
        child: Icon(
          controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }

  Widget _buildPosition(Color iconColor) {
    final position = _latestValue != null && _latestValue.position != null
        ? _latestValue.position
        : Duration.zero;
    final duration = _latestValue != null && _latestValue.duration != null
        ? _latestValue.duration
        : Duration.zero;

    return Padding(
      padding: EdgeInsets.only(right: 24.0),
      child: Text(
        '${formatDuration(position)} / ${formatDuration(duration)}',
        style: TextStyle(
          fontSize: 14.0,
        ),
      ),
    );
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();

    setState(() {
      _hideStuff = false;
      _displayTapped = true;
    });
  }

  Future<Null> _initialize() async {
    beginLight = await FlutterLightPlugin.getCurrentLight;
    maxLight = await FlutterLightPlugin.getMaxLight;
    controller.addListener(_updateState);

    _updateState();

    if ((controller.value != null && controller.value.isPlaying) ||
        chewieController.autoPlay) {
      _startHideTimer();
    }

    if (chewieController.showControlsOnInitialize) {
      _initTimer = Timer(Duration(milliseconds: 200), () {
        setState(() {
          _hideStuff = false;
        });
      });
    }
  }

  void _onExpandCollapse() {
    setState(() {
      _hideStuff = true;

      chewieController.toggleFullScreen();
      _showAfterExpandCollapseTimer = Timer(Duration(milliseconds: 300), () {
        setState(() {
          _cancelAndRestartTimer();
        });
      });
    });
  }

  void _playPause() {
    bool isFinished = _latestValue.position >= _latestValue.duration;

    setState(() {
      if (controller.value.isPlaying) {
        _hideStuff = false;
        _hideTimer?.cancel();
        controller.pause();
      } else {
        _cancelAndRestartTimer();

        if (!controller.value.initialized) {
          controller.initialize().then((_) {
            controller.play();
          });
        } else {
          if (isFinished) {
            controller.seekTo(Duration(seconds: 0));
          }
          controller.play();
        }
      }
    });
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void _updateState() {
    setState(() {
      _latestValue = controller.value;
    });
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: 20.0),
        child: MaterialVideoProgressBar(
          controller,
          onDragStart: () {
            setState(() {
              _dragging = true;
            });

            _hideTimer?.cancel();
          },
          onDragEnd: () {
            setState(() {
              _dragging = false;
            });

            _startHideTimer();
          },
          colors: chewieController.materialProgressColors ??
              ChewieProgressColors(
                  playedColor: Theme.of(context).accentColor,
                  handleColor: Theme.of(context).accentColor,
                  bufferedColor: Theme.of(context).backgroundColor,
                  backgroundColor: Theme.of(context).disabledColor),
        ),
      ),
    );
  }
}
