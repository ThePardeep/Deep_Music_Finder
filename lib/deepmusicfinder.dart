import 'dart:async';

import 'package:flutter/services.dart';

class Deepmusicfinder {
  static const MethodChannel _channel =
      const MethodChannel('deepmusicfinder');

  static Future<dynamic> get fetchSong async {
    dynamic  songs;
    try {
       songs = await _channel.invokeMethod("fetchSong");

    } catch (err) {

      songs = {
        "error" : true,
        "err" : err
      }

    }
    return songs;
  }
}
