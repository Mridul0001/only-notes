import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:only_notes/SharedPreferencesHelper/SPHelper.dart';
import 'package:only_notes/model/Note.dart';
import 'package:only_notes/theme/colors.dart' as colors;

class AddVoiceNote extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _AddVoiceNote();
  }
}

//TODO: I have removed sqlite functionality for now but might need it in future

class _AddVoiceNote extends State<AddVoiceNote> with WidgetsBindingObserver {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference _notes;
  FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  String _noteDoc;
  Note _note;
  int _id;
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  // final _dbHelper = DatabaseHelper.instance;
  @override
  void initState() {
    super.initState();
    _notes = firestore.collection('notes');
    _noteDoc = _firebaseAuth.currentUser.uid;
    this._getID();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        this._saveNote();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    var paddingTop = MediaQuery.of(context).padding.top;
    var paddingBottom = MediaQuery.of(context).padding.bottom;
    var toolbarHeight = kToolbarHeight;
    var deviceHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            leading: null,
            title: Text(
              "Add New Note",
              style: TextStyle(color: Color(colors.hintTextDark)),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Center(
                    child: Container(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: 50),
                          child: TextField(
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(40)
                            ],
                            controller: _titleController,
                            autofocus: true,
                            decoration: InputDecoration(
                                contentPadding: EdgeInsets.all(12),
                                border: InputBorder.none, hintText: "Title"),
                            style: TextStyle(color: Colors.white.withOpacity(0.87), fontSize: 17),
                          ),
                        )),
                  ),
                  Center(
                    child: Container(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            minHeight: 300,
                            maxHeight: deviceHeight -
                                paddingBottom -
                                paddingTop -
                                toolbarHeight -
                                60),
                        child: TextField(
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(2000)
                          ],
                          controller: _noteController,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(12),
                            border: InputBorder.none,
                            hintText: "Note",
                          ),
                          style: TextStyle(color: Colors.white.withOpacity(0.87), fontSize: 17),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          )),
    );
  }

  void _saveNote() {
    String title = this._titleController.text;
    String noteDetails = this._noteController.text;
    int id = this._id;
    DateTime dateTime = DateTime.now();
    Note note = new Note(title, noteDetails, id, dateTime);
    this._insertNote(note);
  }

  void _getID() async {
    this._id = SPHelper.getInt('lastNoteId') + 1;
    SPHelper.setInt('lastNoteId', this._id);
  }

  void _insertNote(Note note) async {
    if ((note.getNote() != null && note.getNote().trim().length != 0)) {
      // await this._dbHelper.insertNote(note);
      await _notes.doc(_noteDoc).update({'notes.${this._id.toString()}': note.toMap()});
      Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
    } else {
      //delete empty note
      await _notes.doc(_noteDoc).update({'notes.${this._id.toString()}': FieldValue.delete()});
      Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
    }
  }
}
