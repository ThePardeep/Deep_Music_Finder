import 'dart:async';

import 'package:flutter/services.dart';

class Deepmusicfinder {
  static const MethodChannel _channel =
      const MethodChannel('deepmusicfinder');

  static Future<dynamic> get fetchSong async {
    try {
      final dynamic songs = await _channel.invokeMethod("fetchSong");
      return songs;
    } catch (err) {

      throw err;

    }
  }
}
