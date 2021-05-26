import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:only_notes/LifeCycleManager/LifeCycleManager.dart';
import 'package:only_notes/auth/Authentication.dart';
import 'package:only_notes/encryption/EncryptionKey.dart';
import 'package:only_notes/home/NotesHome.dart';
import 'package:only_notes/newnote/AddVoiceNote.dart';
import 'package:only_notes/registeruserdetails/CompleteRegistration.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './newnote/AddNewNote.dart';
import 'package:only_notes/theme/colors.dart' as colors;

import 'SharedPreferencesHelper/SPHelper.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await SharedPreferences.getInstance().then((value) => {
    SPHelper.setPref(value)
  });
  runApp(MyApp());
}

class MyApp extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    //App starts from here
    final theme = Theme.of(context).textTheme.apply(
      bodyColor: Colors.white.withOpacity(0.87),
      displayColor: Colors.white.withOpacity(0.87)
    );

    final bottomNavTheme = BottomNavigationBarThemeData(
      selectedItemColor: Color(0xFF9e9e9e),
      unselectedItemColor: Color(0xFF9e9e9e),
      backgroundColor: Color(0xFF1d1d1d),
    );
    return GestureDetector(
      onTap: (){
        FocusScopeNode currentFocus = FocusScope.of(context);

        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          FocusManager.instance.primaryFocus.unfocus();
        }
      },
      child: LifeCycleManager(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
              brightness: Brightness.dark,
              primaryColor: Color(0xFF1d1d1d),
              iconTheme: new IconThemeData(
                color: Color(0xFF9e9e9e)
              ),
              cardColor: Color(0xFF1d1d1d),
              scaffoldBackgroundColor: Color(0xFF121212),
              hintColor: Color(colors.hintTextDark),
              shadowColor: Color(0xFF373737),
              bottomNavigationBarTheme: bottomNavTheme,
              textTheme: theme
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => Authentication(),
          },
          onGenerateRoute: (settings){
            switch(settings.name){
              case '/home':
                return PageTransition(child: NotesHome(), type: PageTransitionType.fade, settings: settings, duration: Duration(milliseconds: 500));
                break;
              case '/addnote':
                return PageTransition(child: AddNewNote(), type: PageTransitionType.fade, settings: settings, duration: Duration(milliseconds: 500));
                break;
              case '/encryption':
                return PageTransition(child: EncryptionKey(), type: PageTransitionType.fade, settings: settings, duration: Duration(milliseconds: 500));
                break;
              case '/register':
                return PageTransition(child: CompleteRegistration(), type: PageTransitionType.fade, settings: settings, duration: Duration(milliseconds: 500));
                break;
              case '/voicenote':
                return PageTransition(child: AddVoiceNote(), type: PageTransitionType.fade, settings: settings, duration: Duration(milliseconds: 500));
                break;
              default:
                return null;
            }
          },
          title: "Only Notes",
        ),
      ),
    );
  }
}