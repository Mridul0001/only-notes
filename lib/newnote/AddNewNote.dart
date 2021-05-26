import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:only_notes/SharedPreferencesHelper/SPHelper.dart';
import 'package:only_notes/model/Note.dart';
import 'package:only_notes/theme/colors.dart' as colors;

class AddNewNote extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _AddNewNote();
  }
}

//TODO: I have removed sqlite functionality for now but might need it in future

class _AddNewNote extends State<AddNewNote> with WidgetsBindingObserver {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference _notes;
  FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  String _noteDoc;
  Note _note;
  int _id;
  bool _isEditing = false;
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  // final _dbHelper = DatabaseHelper.instance;
  bool _isEditingOnAppResumed = false;
  // bool _redirectedFromShortcut = SPHelper.getBool('redirectFromShortcut');
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
        this._isEditingOnAppResumed = true;
        this._handleAppInactive();
        // print('appLifeCycleState inactive');
        break;
      case AppLifecycleState.resumed:
        this._isEditingOnAppResumed = true;
        // print('appLifeCycleState resumed');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    _note = ModalRoute.of(context).settings.arguments as Note;
    this._checkForEditing();
    var paddingTop = MediaQuery.of(context).padding.top;
    var paddingBottom = MediaQuery.of(context).padding.bottom;
    var toolbarHeight = kToolbarHeight;
    var deviceHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: WillPopScope(
          child: Scaffold(
              resizeToAvoidBottomInset: true,
              appBar: AppBar(
                leading: BackButton(
                  color: Color(colors.hintTextDark),
                ),
                title: this._isEditing
                    ? Text(
                        "Edit Note",
                        style: TextStyle(color: Color(colors.hintTextDark)),
                      )
                    : Text(
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
                            autofocus: !_isEditing,
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
                              autofocus: _isEditing,
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
          onWillPop: () {
            _isEditingOnAppResumed = false;
            _saveNote();
            return Future.value(true);
          }),
    );
  }

  void _checkForEditing() {
    if (_note != null && !_isEditing) {
      this._id = _note.getId();
      this._titleController.text = _note.getTitle();
      this._noteController.text = _note.getNote();
      this._noteController.selection = TextSelection.fromPosition(
          TextPosition(offset: this._noteController.text.length));
      this._titleController.selection = TextSelection.fromPosition(
          TextPosition(offset: this._titleController.text.length));
      _isEditing = true;
    }
  }

  void _saveNote() {
    String title = this._titleController.text;
    String noteDetails = this._noteController.text;
    int id = this._id;
    DateTime dateTime = DateTime.now();
    if (_isEditing) {
      _note.note = noteDetails;
      _note.title = title;
      _note.dateTime = dateTime;
      // this._updateNote(_note);
      this._insertNote(_note);
    }  else {
      Note note = new Note(title, noteDetails, id, dateTime);
      this._insertNote(note);
    }
  }

  void _getID() async {
    this._id = SPHelper.getInt('lastNoteId') + 1;
    SPHelper.setInt('lastNoteId', this._id);
  }

  void _insertNote(Note note) async {
    if ((note.getNote() != null && note.getNote().trim().length != 0)) {
      // await this._dbHelper.insertNote(note);
      _notes.doc(_noteDoc).update({'notes.${this._id.toString()}': note.toMap()});
      if(!_isEditingOnAppResumed){
        Navigator.pop(context, note);
      }
    } else {
      //delete empty note
      _notes.doc(_noteDoc).update({'notes.${this._id.toString()}': FieldValue.delete()});
      if(!_isEditingOnAppResumed){
        Navigator.pop(context, false);
      }
    }
  }

  // void _updateNote(Note note) async {
  //   if ((note.getNote() != null && note.getNote().trim().length != 0)) {
  //     //update if not empty
  //     await this._dbHelper.updateNote(note);
  //     _notes.doc(_noteDoc).update({'notes.${this._id.toString()}': note.toMap()});
  //     if(!_isEditingOnAppResumed){
  //       Navigator.pop(context, note);
  //     }
  //   } else {
  //     //delete empty note
  //     await this._dbHelper.deleteNote(note.getId());
  //     _notes.doc(_noteDoc).update({'notes.${this._id.toString()}': FieldValue.delete()});
  //     if(!_isEditingOnAppResumed){
  //       Navigator.pop(context, false);
  //     }
  //   }
  // }

  _handleAppInactive() {
    this._saveNote();
    // String title = this._titleController.text;
    // String noteDetails = this._noteController.text;
    // int id = this._id;
    // DateTime dateTime = DateTime.now();
    //
    // if (_isEditing && _draftNote == null) {
    //   _note.note = noteDetails;
    //   _note.dateTime = dateTime;
    //   _note.title = title;
    //   _note.id = id;
    //   _draftNote = _note;
    //   _updateDraft();
    // } else if (_draftNote == null) {
    //   _draftNote = new Note(title, noteDetails, id, dateTime);
    //   _saveDraft();
    // } else {
    //   _draftNote.title = title;
    //   _draftNote.id = id;
    //   _draftNote.note = noteDetails;
    //   _draftNote.dateTime = dateTime;
    //   _note = _draftNote;
    //   _updateDraft();
    // }
  }

  // _saveDraft() async {
  //   if ((_draftNote.getNote() != null &&
  //       _draftNote.getNote().trim().length != 0)) {
  //     await this._dbHelper.insertNote(_draftNote);
  //     List<dynamic> note = new List.empty();
  //     note.add(_draftNote);
  //     _notes.doc(_noteDoc).update({'notes.${this._id.toString()}': _draftNote.toMap()});
  //   }
  // }

  // _updateDraft() async {
  //   if ((_draftNote.getNote() != null &&
  //       _draftNote.getNote().trim().length != 0)) {
  //     //update if not empty
  //     await this._dbHelper.updateNote(_draftNote);
  //     _notes.doc(_noteDoc).update({'notes.${this._id.toString()}': _draftNote.toMap()});
  //   } else {
  //     //delete empty note
  //     await this._dbHelper.deleteNote(_draftNote.getId());
  //   }
  // }
}
