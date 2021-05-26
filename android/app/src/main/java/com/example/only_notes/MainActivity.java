package com.example.only_notes;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import java.util.HashMap;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    private HashMap<String, String> voiceNote;
    private boolean addNote = false;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(new FlutterEngine(this));
        Intent intent = getIntent();
        String action = intent.getAction();


        if(Intent.ACTION_VIEW.equals(action)){
            String title = intent.getStringExtra("name");
            String body = intent.getStringExtra("articleBody");
            voiceNote = new HashMap<String, String>();
            voiceNote.put("title", (title!=null?title:""));
            voiceNote.put("body", (body!=null?body:""));
        }

        if(Intent.ACTION_INSERT.equals(action)){
            addNote = true;
        }

        new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), "app.channel.shared.data")
                .setMethodCallHandler(new MethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
                        if (methodCall.method.contentEquals("getVoiceNote")) {
                            result.success(voiceNote);
                            voiceNote = null;
                        }else if (methodCall.method.contentEquals("addNoteShortcut")) {
                            result.success(addNote);
                            addNote = false;
                        }
                    }
                });

    }
}
