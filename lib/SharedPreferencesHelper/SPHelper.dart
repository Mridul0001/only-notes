import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SPHelper {
  static SharedPreferences prefs;
  static void setPref(SharedPreferences prefs1) {
    prefs = prefs1;
  }

  static int getInt(String key) {
    return prefs.getInt(key) ?? 0;
  }

  static void setInt(String key, int value) {
    prefs.setInt(key, value);
    //prefs.commit();
  }

  static String getString(String key) {
    return prefs.getString(key) ?? "";
  }

  static void setString(String key, String value) {
    prefs.setString(key, value);
  }

  static bool getBool(String key){
    return prefs.getBool(key) ?? false;
  }

  static void setBool(String key, bool value){
    prefs.setBool(key, value);
  }

  static void remove(String key){
    prefs.remove(key);
  }

  static void logout(){
    prefs.clear();
    prefs.setBool('disableDynamicLink', true);
  }
}