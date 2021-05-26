import 'package:only_notes/encryption/EncryptionHelper.dart';

class Note{
  String _title;
  String _note;
  int _id;
  DateTime _dateTime;

  Note(this._title, this._note, this._id, this._dateTime);

  Map<String, dynamic> toMap(){
    return {
      'title':_title,
      'note':EncryptionHelper.encrypt(_note),
      'id':_id,
      'datetime': _dateTime.toIso8601String()
    };
  }

  String getNote(){
    return this._note;
  }

  String getTitle(){
    return this._title;
  }

  int getId(){
    return this._id;
  }

  set title(String value) {
    _title = value;
  }

  DateTime getDateTime(){
    return this._dateTime;
  }

  @override
  String toString() {
    return 'Note{title: $_title, note: $_note, id: $_id, dateAndTime: $_dateTime}';
  }

  set note(String value) {
    _note = value;
  }

  set dateTime(DateTime value) {
    _dateTime = value;
  }

  set id(int value) {
    _id = value;
  }
}