import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:only_notes/SharedPreferencesHelper/SPHelper.dart';
import 'package:only_notes/encryption/EncryptionHelper.dart';
import 'package:only_notes/snackbars/SnackBarHelper.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:only_notes/theme/colors.dart' as colors;

class EncryptionKey extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _EncryptionKey();
}

class _EncryptionKey extends State<EncryptionKey>{
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  CollectionReference _users;
  bool _encryptionStatus = SPHelper.getBool('encryptionStatus');
  bool hasError = false;
  bool _validated;
  bool _validatedConfirm;
  bool disableSaveButton = true;
  final TextEditingController encryptionKey = new TextEditingController();
  StreamController<ErrorAnimationType> errorController;

  @override
  void initState() {
    super.initState();
    _users = _firestore.collection('users');
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    String tempName = _firebaseAuth.currentUser.displayName;
    String firstName = tempName != null ? tempName.split(" ")[0]:'';
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22.0,0.0,22.0,0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 38.0),
                    child: Text(
                      _encryptionStatus?'Welcome Back, '+firstName:'Welcome, '+firstName,
                      textScaleFactor: 1.5,
                    ),
                  ),
                  Text(
                    _encryptionStatus?'Enter your security Key':'Create security Key',
                    style: TextStyle(
                      color: Color(colors.hintTextDark),
                    ),
                    textScaleFactor: 1.3,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom:12.0, top: 12.0),
                    child: TextField(
                      controller: encryptionKey,
                      onChanged: (value){
                        if(value.length<7){
                          setState(() {
                            _validated = false;
                            disableSaveButton = true;
                          });
                        }else if(value.length >=7 && _encryptionStatus){
                          setState(() {
                            _validated = true;
                            disableSaveButton = false;
                          });
                        }else{
                          setState(() {
                            _validated = true;
                            disableSaveButton = true;
                          });
                        }
                      },
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(15),
                        FilteringTextInputFormatter.deny(new RegExp(r"\s")),
                        FilteringTextInputFormatter.allow(RegExp("[A-Za-z0-9~`!@#\/\$\%\^&\*\(\)\+\-\.=\|\?\}\{\[\]]*"))
                      ],
                      obscureText: true,
                      obscuringCharacter: '*',
                      decoration: InputDecoration(
                        hintText: 'Enter your Key',
                        errorText: _validated == false?'Must be between 7 and 15 characters long':null,
                        errorStyle: TextStyle(
                          color: Color(colors.floatingDeleteButtonDark),
                        ),
                        hintStyle: TextStyle(
                          color: Color(colors.hintTextDark).withOpacity(0.5),
                        ),
                        focusedErrorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(colors.floatingDeleteButtonDark), width: 2)
                        ),
                        errorBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(colors.floatingDeleteButtonDark), width: 2)
                        )
                      ),
                    ),
                  ),
                  _encryptionStatus?Container():Padding(
                    padding: const EdgeInsets.only(bottom:12.0, top: 12.0),
                    child: TextField(
                      onChanged: (value){
                        if(value != encryptionKey.text){
                          setState(() {
                            _validatedConfirm = false;
                            disableSaveButton = true;
                          });
                        }else{
                          setState(() {
                            _validatedConfirm = true;
                            disableSaveButton = false;
                          });
                        }
                      },
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(15),
                        FilteringTextInputFormatter.deny(new RegExp(r"\s")),
                        FilteringTextInputFormatter.allow(RegExp("[A-Za-z0-9~`!@#\/\$\%\^&\*\(\)\+\-\.=\|\?\}\{\[\]]*"))
                      ],
                      obscureText: true,
                      obscuringCharacter: '*',
                      decoration: InputDecoration(
                          hintText: 'Confirm your Key',
                          errorText: _validatedConfirm == false?'Key does not match':null,
                          errorStyle: TextStyle(
                            color: Color(colors.floatingDeleteButtonDark),
                          ),
                          hintStyle: TextStyle(
                            color: Color(colors.hintTextDark).withOpacity(0.5),
                          ),
                          focusedErrorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(colors.floatingDeleteButtonDark), width: 2)
                          ),
                          errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(colors.floatingDeleteButtonDark), width: 2)
                          )
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: disableSaveButton?null:(){
                      _verifyEncryptionKey(encryptionKey.text);
                    },
                    label: Text('Proceed', ),
                    icon: Icon(Icons.enhanced_encryption_outlined),
                    style: ButtonStyle(
                        backgroundColor: disableSaveButton?null:MaterialStateProperty.all(Color(colors.googleSignInDark)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top:12.0),
                    child: Text(
                      "\u24D8 Please keep this Key safe with you. We don't store this and if lost then you will loose your notes.",
                      style: TextStyle(
                        color: Color(colors.textButtonDeleteDark),
                      ),
                      textScaleFactor: 1.2,
                    ),
                  )
                ],
              ),
            )
            ],
          ),
        ),
      ),
    );
  }

  _verifyEncryptionKey(String key) async{
    String userKeySignature = SPHelper.getString('keySignature');
    String uid = _firebaseAuth.currentUser.uid;
    bool redirectedFromShortcut = SPHelper.getBool('redirectFromShortcut');
    if(_encryptionStatus){
      //user already has keySignature
      //match that signature with current
      var keyBytes = utf8.encode(key);
      var keySignature = sha512.convert(keyBytes).toString();
      if(keySignature == userKeySignature){
        //user entered right key
        _setSharedPrefs(keySignature, key, uid);
        ScaffoldMessenger.of(context).showSnackBar(SnackBarHelper.snackBarLogin);
        redirectedFromShortcut?
            Navigator.of(context).pushNamedAndRemoveUntil('/voicenote', (Route<dynamic> route) => false):
            Navigator.of(context).pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
    }else{
        //wrong key entered
        return showDialog(
          barrierColor: Color(colors.overlayBackgroundDark).withOpacity(0.75),
          context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                contentPadding: EdgeInsets.fromLTRB(24.0, 24.0, 12.0, 4.0),
                title: Text('\u26A0 Error!', style: TextStyle(color: Color(colors.textButtonDeleteDark)),),
                backgroundColor: Color(colors.dialogBackgroundDark),
                content:  Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Wrong security key entered. Please re-enter your security key'),
                  Padding(
                    padding: const EdgeInsets.only(top:10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text('Close')),
                      ],
                    ),
                  )
                ],)
              );
            }
        );
      }
    }else{
      //create keySignature for user and update in firestore
      var keyBytes = utf8.encode(key);
      var keySignature = sha512.convert(keyBytes).toString();
      await _users.doc(uid).update({
        "keySignature":keySignature,
        "encryptionEnabled":true
      }).then((value) => {
        _setSharedPrefs(keySignature, key, uid),
        ScaffoldMessenger.of(context).showSnackBar(SnackBarHelper.snackBarLogin),
        redirectedFromShortcut?
          Navigator.of(context).pushNamedAndRemoveUntil('/voicenote', (Route<dynamic> route) => false):
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false)
      }).catchError((onError) async => {
        ScaffoldMessenger.of(context).showSnackBar(SnackBarHelper.snackBarError),
        await _firebaseAuth.signOut(),
        SPHelper.logout(),
        Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false),
      });
    }
  }

  _setSharedPrefs(String keySignature, String key, String uid){
    SPHelper.setString('keySignature', keySignature);
    SPHelper.setString('userEncryptionKey', key);
    SPHelper.setBool('encryptionStatus', true);
    SPHelper.setBool("encryptionStatusLocal", true);
    SPHelper.setInt('enableGlobalServices', 1);

    //set global encrypter
    EncryptionHelper encryptionHelper = new EncryptionHelper();
    EncryptionHelper.setEncryptionHelper(encryptionHelper, key, uid);
  }
}