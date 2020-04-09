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
import android.media.AudioManager;
import android.net.Uri;
import android.os.Environment;
import android.os.Handler;
import android.provider.MediaStore;

import android.media.MediaPlayer;

import java.io.IOException;
import java.lang.String;

import android.util.Log;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

public class DeepmusicfinderPlugin implements FlutterPlugin, MethodCallHandler {

    private static Context context;
    private static Activity activity;
    private MediaPlayer mediaPlayer;
    private static MethodChannel _channel;
    private HashMap<Long, String> songsPicture = new HashMap<>();
    private static ContentResolver contentResolver;
    private List<Map<String, Object>> songData = new ArrayList<Map<String, Object>>();
    private HashMap<Long, String> songsPath = new HashMap<>();


    int currentPosition;
    boolean paused = true;
    boolean stop = true;

    Handler handler = new Handler();


    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        final MethodChannel channel = new MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "deepmusicfinder");
        channel.setMethodCallHandler(new DeepmusicfinderPlugin());
        context = flutterPluginBinding.getApplicationContext();
        _channel = channel;
    }


    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "deepmusicfinder");
        context = registrar.context();
        activity = registrar.activity();
        _channel = channel;
        contentResolver = registrar.activity().getContentResolver();
        channel.setMethodCallHandler(new DeepmusicfinderPlugin());
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {

        if (call.method.equals("fetchSong")) {
            fetchSongPath();
            songsMetaData();
            fetchSongsPicture();
            Map<String, Object> data = new HashMap<String, Object>();
            data.put("SongsData", songData);
            data.put("AlbumsData", songsPicture);
            data.put("SongsPath", songsPath);


            result.success(data);
            songData.clear();
            songsPath.clear();
            songsPicture.clear();
        } else if (call.method.equals("play")) {

            play(((HashMap) call.arguments()));

            result.success(1);

        } else if (call.method.equals("pause")) {

            boolean res = pause();

            result.success(res ? 1 : 0);

        } else if (call.method.equals("seek")) {

            int position = call.argument("position");
            boolean res = seek(position);

            result.success(res ? 1 : 0);

        } else if (call.method.equals("stop")) {

            boolean res = stopSong();

            result.success(res ? 1 : 0);

        } else {
            result.notImplemented();
        }
    }

    private void play(Map<String, Object> args) {

        String url = args.get("url").toString();


        if (mediaPlayer == null) {
            mediaPlayer = new MediaPlayer();
            mediaPlayer.setAudioStreamType(AudioManager.STREAM_MUSIC);

            try {

                mediaPlayer.setDataSource(context, Uri.parse(url));

            } catch (IOException e) {

                e.printStackTrace();
                Log.d("Invalid URl", "Invalid DataSource" + e);
            }

            mediaPlayer.prepareAsync();


        } else {

            _channel.invokeMethod("audioDuration", mediaPlayer.getDuration());

            mediaPlayer.start();

            paused = false;
            stop = false;

        }

        mediaPlayer.setOnPreparedListener(new MediaPlayer.OnPreparedListener() {
            @Override
            public void onPrepared(MediaPlayer mp) {

                _channel.invokeMethod("audioDuration", mp.getDuration());
                mp.start();
                paused = false;
                stop = false;
            }
        });

        mediaPlayer.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
            @Override
            public void onCompletion(MediaPlayer mp) {

                _channel.invokeMethod("onComplete", true);
                stopSong();
            }
        });
        mediaPlayer.setOnErrorListener(new MediaPlayer.OnErrorListener() {
            @Override
            public boolean onError(MediaPlayer mp, int what, int extra) {
                _channel.invokeMethod("onPlayerError", true);
                return true;
            }
        });

        handler.post(onPositionChange);
    }

    private boolean pause() {
        if (mediaPlayer.isPlaying()) {
            currentPosition = mediaPlayer.getCurrentPosition();
            mediaPlayer.pause();
            handler.removeCallbacks(onPositionChange);
            paused = true;
            return true;
        }
        return false;
    }

    private boolean seek(int position) {
        if (!stop) {
            mediaPlayer.seekTo(position);
            return true;
        }
        return false;

    }


    private boolean stopSong() {
        handler.removeCallbacks(onPositionChange);
        if (!stop) {
            mediaPlayer.stop();
            mediaPlayer.release();
            mediaPlayer = null;
            stop = true;
            paused = true;
        }

        return stop;
    }


    private void songsMetaData() {


        contentResolver = context.getContentResolver();
        Uri uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI;


        Cursor cursor = contentResolver.query(uri, null, MediaStore.Audio.Media.IS_MUSIC + " = 1", null, null);

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


        do {


            Map<String, Object> data = new HashMap<String, Object>();
            data.put("idColumn", cursor.getLong(idColumn));
            data.put("artist", cursor.getString(artistColumn));
            data.put("title", cursor.getString(titleColumn));
            data.put("album", cursor.getString(albumColumn));
            data.put("duration", cursor.getLong(durationColumn));
            data.put("albumArtColumn", cursor.getString(albumArtColumn));


            songData.add(data);

        } while (cursor.moveToNext());

        cursor.close();

    }

    private void fetchSongsPicture() {
        contentResolver = context.getContentResolver();
        Cursor cursor = contentResolver.query(MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI,
                new String[]{MediaStore.Audio.Albums._ID, MediaStore.Audio.Albums.ALBUM_ART},
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
                new String[]{MediaStore.Audio.Media._ID, MediaStore.Audio.Media.DATA},
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

    private final Runnable onPositionChange = new Runnable() {
        @Override
        public void run() {

            try {

                if (!mediaPlayer.isPlaying()) {
                    handler.removeCallbacks(onPositionChange);
                }
                int position = mediaPlayer.getCurrentPosition();

                _channel.invokeMethod("onPositionChange", position);
                handler.postDelayed(this, 200);


            } catch (Exception e) {
                e.printStackTrace();
            }

        }
    };


    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    }
}


