package com.bm.deepmusicfinder;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;


import android.app.Activity;
import android.content.Context;
import android.content.ContentResolver;
import android.content.ContentUris;
import android.database.Cursor;
import android.net.Uri;
import android.os.Environment;
import android.provider.MediaStore;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

public class DeepmusicfinderPlugin implements FlutterPlugin, MethodCallHandler {

  private static Context context;
  private static Activity activity;
  private HashMap<Long, String> songsPicture = new HashMap<>();
  private static ContentResolver contentResolver;
  private List<Map<String,Object>> songData = new ArrayList<Map<String,Object>>();
  private HashMap<Long, String> songsPath= new HashMap<>();

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    final MethodChannel channel = new MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "deepmusicfinder");
    channel.setMethodCallHandler(new DeepmusicfinderPlugin());
    context = flutterPluginBinding.getApplicationContext();
  }


  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "deepmusicfinder");
    context = registrar.context();
    activity= registrar.activity();
    contentResolver = registrar.activity().getContentResolver();
    channel.setMethodCallHandler(new DeepmusicfinderPlugin());
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {

    if (call.method.equals("fetchSong")) {
      fetchSongPath();
      songsMetaData();
      fetchSongsPicture();
      Map<String,Object> data = new HashMap<String, Object>();
      data.put("SongsData",songData);
      data.put("AlbumsData",songsPicture);
      data.put("SongsPath",songsPath);
      result.success(data);
    }
    else {
      result.notImplemented();
    }
  }

  private void songsMetaData() {


    contentResolver = context.getContentResolver();
    Uri uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI;


    Cursor cursor = contentResolver.query(uri,null, MediaStore.Audio.Media.IS_MUSIC + " = 1",null,null);

    if (cursor == null) {
      return;
    }
    if (!cursor.moveToFirst()) {
      return;
    }

    int artistColumn = cursor.getColumnIndex(MediaStore.Audio.Media.ARTIST);
    int titleColumn = cursor.getColumnIndex(MediaStore.Audio.Media.TITLE);
    int albumColumn = cursor.getColumnIndex(MediaStore.Audio.Media.ALBUM);
    int albumArtColumn = cursor.getColumnIndex(MediaStore.Audio.Media.ALBUM_ID);
    int durationColumn = cursor.getColumnIndex(MediaStore.Audio.Media.DURATION);
    int idColumn = cursor.getColumnIndex(MediaStore.Audio.Media._ID);




    String musicDirPath = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC).getAbsolutePath();
    do {


      Map<String,Object> data = new HashMap<String,Object>();
      data.put("idColumn",cursor.getLong(idColumn));
      data.put("artist",cursor.getString(artistColumn));
      data.put("title",cursor.getString(titleColumn));
      data.put("album",cursor.getString(albumColumn));
      data.put("duration",cursor.getLong(durationColumn));
      data.put("albumArtColumn",cursor.getString(albumArtColumn));



      songData.add(data);

    } while (cursor.moveToNext());

    cursor.close();

  }

  private void fetchSongsPicture() {
    contentResolver = context.getContentResolver();
    Cursor cursor = contentResolver.query(MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI,
            new String[] {MediaStore.Audio.Albums._ID, MediaStore.Audio.Albums.ALBUM_ART},
            null,
            null,
            null);

    if (cursor.moveToFirst()) {
      do {
        long id = cursor.getLong(cursor.getColumnIndex(MediaStore.Audio.Albums._ID));
        String path = cursor.getString(cursor.getColumnIndex(MediaStore.Audio.Albums.ALBUM_ART));
        songsPicture.put(id, path);
      } while (cursor.moveToNext());
    }
    cursor.close();
  }

  private void fetchSongPath() {
    contentResolver = context.getContentResolver();
    Cursor cursor = contentResolver.query(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            new String[] { MediaStore.Audio.Media._ID, MediaStore.Audio.Media.DATA},
            null,
            null,
            null);

    if (cursor.moveToFirst()) {
      do {
        long id = cursor.getLong(cursor.getColumnIndex(MediaStore.Audio.Media._ID));
        String path = cursor.getString(cursor.getColumnIndex(MediaStore.Audio.Media.DATA));
        songsPath.put(id, path);
      } while (cursor.moveToNext());
    }
    cursor.close();
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
  }
}


