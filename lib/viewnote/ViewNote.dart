import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:only_notes/model/Note.dart';
import 'package:only_notes/theme/colors.dart' as colors;

class ViewNote {
  BuildContext _context;
  Note _note;
  final _weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
  final _months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  ViewNote(this._note, this._context) {
    this._initViewNote(_note);
  }

  Future<void> _initViewNote(Note note) {
    return Navigator.of(this._context).push(
      PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              SafeArea(
                child: Material(
                  color: Color(colors.dialogBackgroundDark),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 8,
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Container(
                                  child: Text(_note.getTitle(), style: TextStyle(fontSize: 17.0, color: Color(colors.hintTextDark)),),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.topRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: IconButton(
                                      icon: Icon(Icons.close),
                                      onPressed: (){
                                        Navigator.pop(context);
                                      }),
                                )
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        flex: 8,
                        child: Container(
                          alignment: Alignment.topLeft,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: Padding(
                              padding: const EdgeInsets.only(left:16.0, right: 16.0, bottom: 16.0),
                              child: Text(_note.getNote(),
                                style: TextStyle(fontSize: 17.0),
                                textAlign: TextAlign.justify,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                              color: Color(colors.elevationOneDark),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text('Last Edited On: ${this._formatLastEditedDate(_note.getDateTime())}', style: TextStyle(color: Color(colors.hintTextDark)),),
                                        )),
                                    Expanded(
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Text('Note length: ${_note.getNote().length}', style: TextStyle(color: Color(colors.hintTextDark)),),
                                        ))
                                  ],
                                ),
                              ),
                          )],
                      )
                    ],
                  ),
                ),
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child){
            var begin = Offset(0.0, 1.0);
            var end = Offset.zero;
            var curve = Curves.ease;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          barrierColor: Color(colors.overlayBackgroundDark).withOpacity(0.75),
          opaque: false,
          barrierDismissible: true,
          transitionDuration: Duration(milliseconds: 500),
          reverseTransitionDuration: Duration(milliseconds: 500)),
    );
  }
  
  String _formatLastEditedDate(DateTime dateTime){
    final String weekDay = _weekdays[dateTime.weekday-1];
    final String day = _resolveDaySuperScript(dateTime.day);
    final String month = _months[dateTime.month-1];
    final String year = dateTime.year.toString();
    final String time = _resolveHourAndMinute(dateTime.hour, dateTime.minute);
    return weekDay+", "+day+" "+month+" "+year+" at "+time;
  }

  String _resolveDaySuperScript(int day){
    if(day == 1 || day == 21 || day == 31){
      return day.toString() + "\u02e2\u1d57";
    }else if(day == 2 || day == 22){
      return day.toString() + "\u207f\u1d48";
    }else if(day == 3 || day == 23){
      return day.toString() + "\u02b3\u1d48";
    }else{
      return day.toString() + "\u1d57\u02b0";
    }
  }

  String _resolveHourAndMinute(int hour, int minute){
    String _hour;
    String _minute;
    if(hour<10){
      _hour = "0"+hour.toString();
    }else{
      _hour = hour.toString();
    }

    if(minute<10){
      _minute = "0"+minute.toString();
    }else{
      _minute = minute.toString();
    }

    return _hour+":"+_minute;
  }
}
