import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:only_notes/SharedPreferencesHelper/SPHelper.dart';

class LifeCycleManager extends StatefulWidget {
  final Widget child;
  LifeCycleManager({Key key, this.child}) : super(key: key);

  _LifeCycleManagerState createState() => _LifeCycleManagerState();
}

class _LifeCycleManagerState extends State<LifeCycleManager> with WidgetsBindingObserver {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  CollectionReference users;
  @override
  void initState() {
    users = firestore.collection('users');
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    _redirectedFromShortcut();
    _checkVoiceNote();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async{
    if(state == AppLifecycleState.inactive){
      //app becomes inactive then store lastNoteId to firestore
      if(SPHelper.prefs != null && SPHelper.getInt('enableGlobalServices')==1){
        int lastNoteId = SPHelper.getInt('lastNoteId');
        users.doc(_firebaseAuth.currentUser.uid).update({'lastNoteId':lastNoteId});
      }
      //clear shortcutredirect
      SPHelper.remove('redirectFromShortcut');
      //clear voiceNote
      SPHelper.remove('voiceNote');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: widget.child,
    );
  }

  _redirectedFromShortcut() async{
    bool redirectFromShortcut = await const MethodChannel('app.channel.shared.data')
        .invokeMethod('addNoteShortcut');

    if(redirectFromShortcut != null){
      SPHelper.setBool('redirectFromShortcut', redirectFromShortcut);
    }
  }

  _checkVoiceNote() async{
    var voiceNote = await const MethodChannel('app.channel.shared.data')
        .invokeMethod('getVoiceNote');

    if(voiceNote != null){
      SPHelper.setString('voiceNote', jsonEncode(voiceNote));
    }
  }
}