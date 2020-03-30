import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:deepmusicfinder/deepmusicfinder.dart';

import 'package:permission_handler/permission_handler.dart';
void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  Map<dynamic,dynamic> albumArt = {};
  List<Map<dynamic,dynamic>>  songsList = [];
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }


  Future<void> initPlatformState() async {

    this.per();
    try {
      dynamic data = await Deepmusicfinder.pp;
      print(data);
      setState(() {
      albumArt = Map.from(data["AlbumsData"]);
      songsList = List.from(data["SongsData"]);
      });

    } on PlatformException {
      print("Error");
    }


  }


  void per() {

      PermissionHandler()
          .checkPermissionStatus(PermissionGroup.storage)
          .then((checkPermissionStatus) {
        if (checkPermissionStatus == PermissionStatus.granted) {
          // FetchSongs fetch = new FetchSongs(setSongs);
          // fetch.start(path);

        } else {
          PermissionHandler().requestPermissions(
              [PermissionGroup.storage]).then((reqPermissions) {
            // FetchSongs fetch = new FetchSongs(setSongs);

            if (reqPermissions[PermissionGroup.storage] ==
                PermissionStatus.granted) {
              // fetch.start(path);

            }
          });
        }
      });
  }

  Widget buildLeading(id) {

    String url = albumArt[int.parse(id)];
    print(url);
    if(url == null) {
      return Icon(Icons.library_music);
    }
    return Image.asset(url);
  }

  Widget songBuilder(BuildContext context,int index) {

    return ListTile(
      title: Text(songsList[index]["title"]),
      leading: buildLeading(songsList[index]["albumArtColumn"]),
    );

  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: ListView.builder(itemBuilder: songBuilder,itemCount: songsList.length,),
        ),
      ),
    );
  }
}
