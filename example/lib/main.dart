import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import './NowPlaying.dart';

import 'package:flutter/services.dart';
import 'package:deepmusicfinder/deepmusicfinder.dart';

import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Map<dynamic, dynamic>> songsList = [];
  Deepmusicfinder dmf;
  bool paused = true;
  bool stop = true;
  int selectedSongIndex;
  int prevSongIndex;
  int duration = 0;
  int position = 0;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    dmf = new Deepmusicfinder();
    initPlayer();
    this.getPermission();
  }


  initPlayer() {
    dmf.getDuration.listen((d) {
      if (d != duration) {
        if (songsList[selectedSongIndex]["Duration"] != d) {
          setState(() {
            duration = d;
          });
        } else {
          setState(() {
            duration = songsList[selectedSongIndex]["Duration"];
          });
        }

      }
    });

    dmf.onComplete.listen((e) {
      if (e) {
        setState(() {
          stop = true;
          paused = true;
        });
      }
      onComplete();

    });

    dmf.onPositionChange.listen((pos) {
      if(pos > duration) {
        return;
      }
      setState(() {
        position = pos;
      });

    });
  }

  void getPermission() {
    PermissionHandler()
        .checkPermissionStatus(PermissionGroup.storage)
        .then((checkPermissionStatus) async {
      if (checkPermissionStatus == PermissionStatus.granted) {
        try {
          dynamic result = await dmf.fetchSong;

          if (result["error"] == true) {
            print(result["errorMsg"]);
            return;
          }

          setState(() {
            songsList = List.from(result["songs"]);
          });
        } catch (e) {
          print(e);
        }
      } else {
        PermissionHandler().requestPermissions([PermissionGroup.storage]).then(
            (reqPermissions) async {
          if (reqPermissions[PermissionGroup.storage] ==
              PermissionStatus.granted) {
            try {
              dynamic result = await dmf.fetchSong;

              if (result["error"] == true) {
                print(result["errorMsg"]);
                return;
              }

              setState(() {
                songsList = List.from(result["songs"]);
              });
            } on PlatformException {
              print("Error");
            }
          }
        });
      }
    });
  }

  Widget buildLeading(img) {
    if (img == null) {
      return ClipOval(child: Icon(Icons.library_music));
    }
    if (img == "unknown") {
      return ClipOval(child: Icon(Icons.library_music));
    }
    File pic = new File.fromUri(Uri.parse(img));
    return ClipOval(
      child: Image.file(pic, height: 50.0, width: 50.0),
    );
  }

  play(int index) async {
    stopSong();

    try {
      int result = await dmf.play(songsList[index]['path']);
      if (result == 1) {
        setState(() {
          prevSongIndex = index;
          selectedSongIndex = index;
          paused = false;
          stop = false;
        });
      }
    } catch (err) {
      print(err);
    }
  }

  pause() async {

    try {
      int result = await dmf.pause();
      if (result == 1) {
        setState(() {
          paused = true;
          stop = false;
        });
      }
    } catch (err) {
      print("_______________" + err);
    }
  }

  stopSong() async {
    try {
      int result = await dmf.stop();
      if (result == 1) {
        setState(() {
          paused = true;
          stop = true;
        });
      }
    } catch (err) {
      print("______________" + err);
    }
  }

  resume() async {
    try {
      int result = await dmf.play(songsList[selectedSongIndex]['path']);
      if (result == 1) {
        setState(() {
          paused = false;
          stop = false;
        });
      }
    } catch (err) {
      print(err);
    }
  }

  seek(int position) async {
    try {
      int result = await dmf.seek(position);
      if (result == 1) {}
    } catch (err) {
      print("______________" + err);
    }
  }

  onComplete() {
    if (selectedSongIndex >= songsList.length - 1) {
      this.play(0);
    } else {
      this.play(prevSongIndex + 1);
    }
  }

  Widget buildNowPlaying() {
    if (selectedSongIndex == null) {
      return Center(
        child: Text("Song Not Played"),
      );
    }
    return NowPlaying({
      "song": songsList[selectedSongIndex],
      "resume": resume,
      "pause": pause,
      "isPaused": paused,
      "isStop": stop,
      "duration": duration,
      'seek': seek,
      'selectedSongIndex': selectedSongIndex,
      'position': position,
    });
  }

  Widget songBuilder(BuildContext context, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.0),
      child: ListTile(
        title: Text(songsList[index]["Title"]),
        leading: buildLeading(songsList[index]["Image"]),
        onTap: () {
          this.play(index);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              tabs: <Widget>[
                Tab(
                  text: "Songs",
                ),
                Tab(
                  text: 'Now Playing',
                )
              ],
            ),
            title: const Text('Deep Music Player'),
          ),
          body: TabBarView(
            children: <Widget>[
              Container(
                child: ListView.builder(
                  itemBuilder: songBuilder,
                  itemCount: songsList.length,
                ),
              ),
              buildNowPlaying()
            ],
          ),
        ),
      ),
    );
  }
}
