import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:only_notes/SharedPreferencesHelper/SPHelper.dart';
import 'package:only_notes/db/FirestoreHelper.dart';
import 'package:only_notes/loadingindiactor/LoadingIndiactor.dart';
import 'package:only_notes/snackbars/SnackBarHelper.dart';
import 'package:only_notes/theme/colors.dart' as colors;

class CompleteRegistration extends StatefulWidget{
  @override
  State<StatefulWidget> createState() =>  _CompleteRegistration();
}

class _CompleteRegistration extends State<CompleteRegistration>{
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  bool disableSaveButton = true;
  bool nameError = false;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  CollectionReference users;
  @override
  void initState() {
    users = firestore.collection('users');
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
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
                    Text(
                      'Please complete registration process',
                      style: TextStyle(
                        color: Color(colors.hintTextDark),
                      ),
                      textScaleFactor: 1.3,
                    ),
                    TextFormField(
                      controller: firstNameController,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(30)
                      ],
                      onChanged: (value){
                        if (value == null || value.trim().length ==0) {
                          setState(() {
                            disableSaveButton = true;
                            nameError = true;
                          });
                          return null;
                        }
                        setState(() {
                          disableSaveButton = false;
                          nameError = false;
                        });
                        return null;
                      },
                      decoration:
                      InputDecoration(
                          labelText: "First Name*",
                          errorText: nameError?"First name can not be empty":null,
                      ),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.87),
                      ),
                    ),
                    TextField(
                      controller: lastNameController,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(50)
                      ],
                      decoration: InputDecoration(labelText: "Last Name"),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.87),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: disableSaveButton?null:(){
                        updateUserDetails();
                      },
                      label: Text('Save Details', ),
                      icon: Icon(Icons.save_outlined),
                      style: ButtonStyle(
                        backgroundColor: disableSaveButton?null:MaterialStateProperty.all(Color(colors.googleSignInDark)),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  updateUserDetails() async{
    LoadingIndicator.showLoader(context, minTimer: false, timer: 1);
    String firstName = this.firstNameController.text.trim();
    String lastNameTemp = this.lastNameController.text;
    String lastName = '';
    if(lastNameTemp != null || lastNameTemp.trim().length !=0){
      lastName = lastNameTemp.trim();
    }
    String newDisplayName = firstName + ' ' + lastName;
    await firebaseAuth.currentUser.updateProfile(displayName: newDisplayName).then((value) => {
        users.doc(firebaseAuth.currentUser.uid).update({
          "firstName":firstName
        }),
        LoadingIndicator.hideLoader(context),
        Navigator.of(context).pushNamedAndRemoveUntil('/encryption', (Route<dynamic> route) => false)
    }).catchError((onError) async =>{
        LoadingIndicator.hideLoader(context),
        ScaffoldMessenger.of(context).showSnackBar(SnackBarHelper.snackBarError),
        await firebaseAuth.signOut(),
        SPHelper.logout(),
        Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false),
    });
  }
}