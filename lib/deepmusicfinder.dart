import 'dart:async';

import 'package:flutter/services.dart';

class Deepmusicfinder {
  static const MethodChannel _channel =
      const MethodChannel('deepmusicfinder');

  static Future<dynamic> get fetchSong async {
    dynamic  songs;
    bool error = false;
    dynamic errorMsg;
    try {

       songs = await _channel.invokeMethod("fetchSong");

    } catch (err) {

        error = true;
        errorMsg = err;

    }
    return {
      "songs" : songs,
      "error" : error,
      "errorMsg":errorMsg
    };
  }
}
