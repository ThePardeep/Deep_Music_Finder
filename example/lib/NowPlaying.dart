import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui';

// ignore: must_be_immutable
class NowPlaying extends StatelessWidget {
  @override
  Map<String, dynamic> _song;
  Function resume, pause, seek;
  bool isPaused, isStop;
  Duration duration, position;
  int index;

  String currentPosition;

  NowPlaying(data) {
    _song = data['song'];
    pause = data["pause"];
    resume = data["resume"];
    position = new Duration(milliseconds: data['position']);
    isPaused = data['isPaused'];
    isStop = data['isStop'];
    seek = data['seek'];
    index = data['selectedSongIndex'];
    duration = new Duration(milliseconds: data['duration']);
  }

  Widget buildBackground(img) {
    if (img != null) {
      if (img == 'unknown') {
        return Image(
          image: new AssetImage("./assets/songlogo.png"),
          color: Colors.black54,
          fit: BoxFit.cover,
          colorBlendMode: BlendMode.darken,
        );
      } else {
        File pic = new File.fromUri(Uri.parse(img));

        return Image.file(
          pic,
          fit: BoxFit.cover,
          color: Colors.black54,
          colorBlendMode: BlendMode.darken,
        );
      }
    } else {
      return Image(
        image: new AssetImage("./assets/songlogo.png"),
        color: Colors.black54,
        fit: BoxFit.cover,
        colorBlendMode: BlendMode.darken,
      );
    }
  }

  buildImage(img) {
    if (img != null) {
      if (img == 'unknown') {
        return Image(
          image: new AssetImage("./assets/songlogo.png"),
        );
      } else {
        File pic = new File.fromUri(Uri.parse(img));

        return Image.file(
          pic,
        );
      }
    } else {
      return Image(
        image: new AssetImage("./assets/songlogo.png"),
      );
    }
  }

  String getDuration(Duration duration) {
    List<String> d = duration.toString().split(":");

    String Time = '';

    if (double.parse(d[0]) > 0.0) {
      Time = Time + d[0] + ":";
    }
    if (double.parse(d[1]) > 0.0) {
      Time = Time + d[1] + ":";
    }

    if (double.parse(d[2]) > 0.0) {
      Time = Time + d[2].split(".")[0];
    }
    if (Time == "") Time = "0:0";

    return Time;
  }

  Widget buildButton(bool paused) {
    if (paused) {
      return InkWell(
        child: Icon(Icons.play_arrow, color: Colors.white, size: 30.0),
        onTap: () {
          resume();
        },
      );
    }

    return InkWell(
        child: Icon(Icons.pause, color: Colors.white, size: 30.0),
        onTap: () {
          pause();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.black),
      child: Stack(
        children: <Widget>[
          Container(
            child: buildBackground(_song["Image"]),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              decoration: BoxDecoration(color: Colors.black87.withOpacity(0.1)),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(top: 10.0),
                padding: EdgeInsets.only(bottom: 20.0),
                child: Column(
                  children: <Widget>[
                    Text(
                      _song["Title"],
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    Text(
                      _song["Artist"],
                      style: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                  ],
                ),
              ),
              Container(
                child: buildImage(_song["Image"]),
                height: 300,
                width: 300,
              ),
              Container(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Text(
                      getDuration(position),
                      style: TextStyle(fontSize: 15.0, color: Colors.white),
                    ),
                    Slider(
                      activeColor: Colors.white,
                      inactiveColor: Colors.white,
                      value: position.inMilliseconds.toDouble(),
                      onChanged: (val) {
                        seek(val.toInt());
                      },
                      min: 0.0,
                      max: duration.inMilliseconds.toDouble(),
                    ),
                    Text(
                      getDuration(duration),
                      style: TextStyle(fontSize: 15.0, color: Colors.white),
                    )
                  ],
                ),
              ),
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    InkWell(
                      child: Icon(
                        Icons.fast_rewind,
                        size: 40.0,
                        color: Colors.white,
                      ),
                      onTap: () {},
                    ),
                    buildButton(isPaused),
                    InkWell(
                      child: Icon(Icons.fast_forward,
                          size: 40.0, color: Colors.white),
                      onTap: () {
                        seek(300000);
                      },
                    ),
                  ],
                ),
              )
            ],
          )
        ],
        fit: StackFit.expand,
      ),
    );
  }
}
