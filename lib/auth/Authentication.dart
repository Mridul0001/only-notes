import 'dart:convert';

import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_signin_button/button_builder.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:only_notes/SharedPreferencesHelper/SPHelper.dart';
import 'package:only_notes/db/FirestoreHelper.dart';
import 'package:only_notes/encryption/EncryptionHelper.dart';
import 'package:only_notes/loadingindiactor/LoadingIndiactor.dart';
import 'package:only_notes/snackbars/SnackBarHelper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:only_notes/theme/colors.dart' as colors;

class Authentication extends StatefulWidget {
  @override
  _AuthenticationState createState() => _AuthenticationState();
}

class _AuthenticationState extends State<Authentication> with TickerProviderStateMixin{
  bool isInitializing = true;
  String _emailAuth = '';
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  @override
  void initState() {
    super.initState();
    this.initDynamicLinks();
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isInitializing?SafeArea(
        child: Material(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Please be patient....', textScaleFactor: 1.3,)
            ],
          ),
        )):Scaffold(
        body: SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22.0, 0.0, 22.0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 38.0),
                    child: Text("Welcome", textScaleFactor: 1.5),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      "Sign in/up with email:",
                      textScaleFactor: 1.3,
                      style: TextStyle(color: Color(colors.hintTextDark)),
                    ),
                  ),
                  Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          TextFormField(
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(50),
                            ],
                            controller: emailController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email can not be empty';
                              } else if (!EmailValidator.validate(value)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: "Email*",
                            ),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.87),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: SignInButtonBuilder(
                              text: 'Password less Sign in',
                              icon: Icons.email_outlined,
                              backgroundColor: Color(colors.googleSignInDark),
                              onPressed: () {
                                SPHelper.setBool('disableDynamicLink', false);
                                if (_formKey.currentState.validate()) {
                                  _emailAuth = emailController.text;
                                  PasswordLessSignIn()
                                      .catchError((onError) async => {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(
                                                        'Something went wrong!')))
                                          })
                                      .then((value) async => {
                                            SPHelper.setString(
                                                'only_notes_temp_user_email',
                                                this._emailAuth),
                                          });
                                }
                              },
                            ),
                          )
                        ],
                      )),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 32.0, bottom: 12.0),
                        child: Text(
                          "OR",
                          textScaleFactor: 1.3,
                          style: TextStyle(color: Color(colors.hintTextDark)),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SignInButton(Buttons.GoogleDark, onPressed: () async {
                        SPHelper.setBool('disableDynamicLink', false);
                        LoadingIndicator.showLoader(context,
                            minTimer: false, timer: 0);
                        var value =
                            await signInWithGoogle().catchError((onError) => {
                                  LoadingIndicator.hideLoader(context),
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBarHelper.snackBarError),
                                });
                        _processGoogleSignIn(value);
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Future<dynamic> PasswordLessSignIn() {
    LoadingIndicator.showLoader(context, minTimer: false, timer: 0);
    var acs = ActionCodeSettings(
        url: "https://onlynotes.page.link/H3Ed",
        dynamicLinkDomain: "onlynotes.page.link",
        // This must be true
        handleCodeInApp: true,
        iOSBundleId: "com.example.ios",
        androidPackageName: "com.onlynotes.app.free",
        // installIfNotAvailable
        androidInstallApp: true,
        // minimumVersion
        androidMinimumVersion: "12");

    return FirebaseAuth.instance
        .sendSignInLinkToEmail(email: _emailAuth, actionCodeSettings: acs)
        .then((value) => {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBarHelper.snackBarEmailSent),
              LoadingIndicator.hideLoader(context)
            })
        .catchError((onError) => {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBarHelper.snackBarError),
              LoadingIndicator.hideLoader(context)
            });
  }

  Future<void> initDynamicLinks() async {
    final PendingDynamicLinkData data = await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri deepLink = data?.link;
    if (deepLink != null && !SPHelper.getBool("disableDynamicLink")) {
      setState(() {
        isInitializing = false;
      });
      handleLinkRedirect(deepLink);
    }else{
      this._checkUserLoggedIn();
    }
    return;
  }

  void handleLinkRedirect(Uri deepLink) async {
    LoadingIndicator.showLoader(context, minTimer: false, timer: 1);
    String emailAuth = SPHelper.getString('only_notes_temp_user_email');
    var auth = FirebaseAuth.instance;
    final link = deepLink.toString();
    if (auth.isSignInWithEmailLink(link)) {
      auth
          .signInWithEmailLink(email: emailAuth, emailLink: link)
          .then((value) =>
              {_processEmailSignIn(value)})
          .catchError((onError) => {
                LoadingIndicator.hideLoader(context),
                ScaffoldMessenger.of(context).showSnackBar(SnackBarHelper.snackBarError)
              });
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential
    final GoogleAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance
        .signInWithCredential(credential)
        .then((value) {
      return value;
    });
  }

  void _processGoogleSignIn(value) async {
    FirestoreHelper firestoreHelper = new FirestoreHelper();
    firestoreHelper.handleUser(context);
  }

  void _processEmailSignIn(value) {
    FirestoreHelper firestoreHelper = new FirestoreHelper();
    firestoreHelper.handleUser(context);
  }

  _checkUserLoggedIn() async {
    bool isLoggedIn = firebaseAuth.currentUser != null ? true : false;
    bool encryptionEnabledLocal = SPHelper.getBool('encryptionStatusLocal');
    bool isRegistered = _checkRegistrationStatus(isLoggedIn);
    bool redirectedFromShortcut = SPHelper.getBool('redirectFromShortcut');
    String isVoiceNote = SPHelper.getString('voiceNote');
    if (isLoggedIn && encryptionEnabledLocal && isRegistered && !redirectedFromShortcut) {
      this._enableGlobalEncrypter();
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBarHelper.snackBarLogin);
    }else if (isLoggedIn && encryptionEnabledLocal && isRegistered && redirectedFromShortcut) {
      this._enableGlobalEncrypter();
      Navigator.of(context).pushNamedAndRemoveUntil('/voicenote', (Route<dynamic> route) => false);
    }else if (isLoggedIn && isRegistered && !encryptionEnabledLocal) {
      Navigator.of(context).pushNamedAndRemoveUntil('/encryption', (Route<dynamic> route) => false);
    }else if (isLoggedIn && !isRegistered) {
      Navigator.of(context).pushNamedAndRemoveUntil('/register', (Route<dynamic> route) => false);
    }else if(redirectedFromShortcut || isVoiceNote !=''){
      ScaffoldMessenger.of(context).showSnackBar(SnackBarHelper.snackBarRedirection);
      setState(() {
        isInitializing = false;
      });
    }else{
      setState(() {
        isInitializing = false;
      });
    }
  }

  void _enableGlobalEncrypter() {
    String key = SPHelper.getString('userEncryptionKey');
    EncryptionHelper encryptionHelper = new EncryptionHelper();
    EncryptionHelper.setEncryptionHelper(
        encryptionHelper, key, firebaseAuth.currentUser.uid);
  }

  bool _checkRegistrationStatus(bool isLoggedIn) {
    if (isLoggedIn && firebaseAuth.currentUser.displayName != null &&
        firebaseAuth.currentUser.displayName.trim().length != 0) {
      return true;
    }
    return false;
  }
}
