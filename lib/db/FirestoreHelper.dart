import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:only_notes/SharedPreferencesHelper/SPHelper.dart';
import 'package:only_notes/loadingindiactor/LoadingIndiactor.dart';
import 'package:only_notes/snackbars/SnackBarHelper.dart';

class FirestoreHelper{
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  void handleUser(BuildContext context) async{
    CollectionReference users = firestore.collection('users');
    List<String> displayName = (firebaseAuth.currentUser.displayName!=null && firebaseAuth.currentUser.displayName.trim().length != 0)?
                                firebaseAuth.currentUser.displayName.split(" "):
                                new List.from([null, null]);
    String firstName = displayName[0];
    String uid = firebaseAuth.currentUser.uid;
    users.doc(uid).get().then((value) => {
      if(value != null && value.exists){
        //user is present
        if(firstName != null){
          setSharedPrefs(value.data(), uid, context)
        }else{
          //redirect to registration screen
          LoadingIndicator.hideLoader(context),
          Navigator.of(context).pushNamedAndRemoveUntil('/register', (Route<dynamic> route) => false)
        }
      }else{
        //need to create user
        createUserInFirestore(users, uid, firstName, context)
      }
    }).catchError((onError) {
      LoadingIndicator.hideLoader(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBarHelper.snackBarError);
    });
  }

  void createUserInFirestore(CollectionReference users, String uid, String firstName, BuildContext context) async{
    CollectionReference notes = firestore.collection('notes');
    //create new notes document
    await notes.doc(uid).set({
      "notes": {}
    }).then((value) => {
      //after notes is created, create the user
      users.doc(uid).set({
        "firstName": firstName,
        "encryptionEnabled":false,
        "keySignature":null,
        "lastNoteId":0
      }).then((value) async => {
        SPHelper.setBool("encryptionStatus", false),
        SPHelper.setInt("lastNoteId", 0),
        LoadingIndicator.hideLoader(context),
        firstName != null?
            Navigator.of(context).pushNamedAndRemoveUntil('/encryption', (Route<dynamic> route) => false)
            :Navigator.of(context).pushNamedAndRemoveUntil('/register', (Route<dynamic> route) => false)
      })
    }).catchError((onError) {
      LoadingIndicator.hideLoader(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBarHelper.snackBarError);
    });
  }

  void setSharedPrefs(Map<String, dynamic> data, String uid, BuildContext context) async{
    SPHelper.setBool("encryptionStatus", data['encryptionEnabled']);
    SPHelper.setBool("encryptionStatusLocal", false);
    SPHelper.setInt("lastNoteId", data['lastNoteId']);
    SPHelper.setString('keySignature', data['keySignature']);
    LoadingIndicator.hideLoader(context);
    Navigator.of(context).pushNamedAndRemoveUntil('/encryption', (Route<dynamic> route) => false);
  }

}