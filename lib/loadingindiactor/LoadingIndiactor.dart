import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:only_notes/theme/colors.dart' as colors;

class LoadingIndicator {
  static showLoader(BuildContext context, {bool minTimer, int timer}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: new Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              new CircularProgressIndicator(
                backgroundColor: Colors.transparent,
                semanticsLabel: "Displaying Progress Indicator",
                semanticsValue: "In progress",
                strokeWidth: 5.0,
              ),
            ],
          ),
        );
      },
    );
    new Future.delayed(new Duration(seconds: timer), () {
      if(minTimer == true){
        Navigator.pop(context); //pop dialog
      }
    });
  }

  static hideLoader(BuildContext context){
    Navigator.pop(context);
  }
}
