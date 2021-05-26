import 'package:flutter/material.dart';
import 'package:only_notes/theme/colors.dart' as colors;
class SnackBarHelper{
  static final snackBarSaved = SnackBar(content: Text('Note saved successfully'), duration: Duration(milliseconds: 2000),);
  static final snackBarDiscarded = SnackBar(content: Text('Empty note discarded'), duration: Duration(milliseconds: 2000),);
  static final snackBarDeleted = SnackBar(content: Text('Note deleted successfully'), duration: Duration(milliseconds: 2000),);
  static final snackBarBulkDelete = SnackBar(content: Text('Notes deleted successfully'), duration: Duration(milliseconds: 2000));
  static final snackBarLogout = SnackBar(content: Text('Logged out successfully'), duration: Duration(milliseconds: 2000));
  static final snackBarLogin = SnackBar(content: Text('Logged in successfully'), duration: Duration(milliseconds: 2000));
  static final snackBarError = SnackBar(content: Text('Something went wrong, check your connection or try again later.', style: TextStyle(color: Color(colors.textButtonDeleteDark))), duration: Duration(milliseconds: 3000));
  static final snackBarEmailSent = SnackBar(content: Text('Email sent successfully'), duration: Duration(milliseconds: 2000));
  static final snackBarVoiceNote = SnackBar(content: Text('Please login to save voice note'), duration: Duration(milliseconds: 2000));
  static final snackBarRedirection = SnackBar(content: Text('Please login to add new note'), duration: Duration(milliseconds: 3000));
}