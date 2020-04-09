import 'dart:async';
import 'package:path/path.dart';
import 'package:flutter/services.dart';

class Deepmusicfinder {
  static const MethodChannel _channel = const MethodChannel('deepmusicfinder');
  int duration;
  StreamController<int> _durationStreamController;
  StreamController<bool> _onCompleteStreamController;
  StreamController<int> _onPositionChangeStreamController;
  bool error = false;

  Deepmusicfinder() {

    _channel.setMethodCallHandler(platformCallHandler);
    _durationStreamController = new StreamController<int>();
    _onCompleteStreamController = new StreamController<bool>.broadcast();
    _onPositionChangeStreamController = new StreamController<int>.broadcast();
  }

  String getImage(id, songsPicture) {
    id = int.parse(id);
    return songsPicture[id];
  }

  String getPath(id, songsPath) {
    return songsPath[id];
  }

  buildSongList(songsPath, songsPicture, songsData) {
    List<Map<String, dynamic>> songs = [];

    for (var i = 0; i < songsData.length; i++) {
      String path = getPath(songsData[i]["idColumn"], songsPath);
      if ((songsData[i]["duration"] != 0) && (extension(path) == ".mp3")) {
        String img = getImage(songsData[i]["albumArtColumn"], songsPicture);
        songs.add({
          "Title":
              songsData[i]["title"] == null ? "unknown" : songsData[i]["title"],
          "Duration":
              songsData[i]["duration"] == 0 ? "0" : songsData[i]["duration"],
          "Album":
              songsData[i]["album"] == null ? "unknown" : songsData[i]["album"],
          "Artist": songsData[i]["artist"] == null
              ? "unknown"
              : songsData[i]["artist"],
          "path": path,
          "Image": img == null ? "unknown" : img
        });
      }
    }

    return songs;
  }

  Future<dynamic> get fetchSong async {
    dynamic songs;
    bool error = false;
    dynamic errorMsg, songsPath, songsPicture;
    List<Map<dynamic, dynamic>> songsData = [];
    try {
      dynamic result = await _channel.invokeMethod("fetchSong");

      songsPath = Map.from(result["SongsPath"]);
      songsPicture = Map.from(result["AlbumsData"]);
      songsData = List.from(result["SongsData"]);
      songs = buildSongList(songsPath, songsPicture, songsData);
    } catch (err) {
      error = true;
      errorMsg = err;
    }
    return {
      "error": error,
      "errorMsg": errorMsg,
      "songs": songs,
    };
  }

  Future<int> play(url) async {
    int result;
    try {
      result = await _channel.invokeMethod('play', {"url": url});
    } catch (e) {
      result = 0;
      print(e);
    }
    return result;
  }

  Future<int> pause() async {
    int res;
    try {
      res = await _channel.invokeMethod("pause");
    } catch (err) {
      res = 0;
      print(err);
    }
    return res;
  }

  Future<int> seek(int position) async {
    if (position < 0) {
      return 0;
    }
    int res;
    try {
      res = await _channel.invokeMethod("seek", {'position': position});
    } catch (err) {
      res = 0;
      print(err);
    }
    return res;
  }

  Future<int> stop() async {
    int res;
    try {
      res = await _channel.invokeMethod("stop");
    } catch (err) {
      res = 0;
      print(err);
    }
    return res;
  }

  Stream get getDuration {
    return _durationStreamController.stream;
  }

  Stream get onComplete {
    return _onCompleteStreamController.stream;
  }

  Stream get onPositionChange {
    return _onPositionChangeStreamController.stream;
  }

  Future<dynamic> platformCallHandler(MethodCall call) {
    switch (call.method) {
      case 'audioDuration':
        duration = call.arguments;
        _durationStreamController.add(duration);
        break;
      case 'onComplete':
        _onCompleteStreamController.add(call.arguments);
        break;
      case 'onPlayerError':
        error = call.arguments;
        break;
      case 'onPositionChange':
        _onPositionChangeStreamController.add(call.arguments);
        break;
    }
  }
}
