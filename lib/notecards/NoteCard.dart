import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:only_notes/db/DatabaseHelper.dart';
import 'package:only_notes/loadingindiactor/LoadingIndiactor.dart';
import 'package:only_notes/model/Note.dart';
import 'package:only_notes/snackbars/SnackBarHelper.dart';
import 'package:only_notes/theme/colors.dart' as colors;
import 'package:only_notes/viewnote/ViewNote.dart';

class NoteCard extends StatefulWidget {
  final List<Note> notes;
  bool resetSelection;
  final Function(int) deleteNoteFunction;
  final Function(Map<int, Note>) bulkDeleteNotes;
  final Function() resetFilters;
  NoteCard(
      {this.notes,
      this.deleteNoteFunction,
      this.bulkDeleteNotes,
      this.resetSelection,
      this.resetFilters
      });
  @override
  State<StatefulWidget> createState() {
    return _NoteCard();
  }
}

class _NoteCard extends State<NoteCard> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference _notes;
  FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  String _noteDoc;
  Map<int, bool> _multiSelect = new Map();
  Map<int, Note> _multiSelectNote = new Map();
  bool multiSelectEnabled = false;
  // List<int> _selectedIds = List<int>.empty(growable: true);
  Map<String, dynamic> _selectedIds = new Map();
  final _dbHelper = DatabaseHelper.instance;
  void initState() {
    _notes = firestore.collection('notes');
    _noteDoc =  _firebaseAuth.currentUser.uid;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.resetSelection) {
      this._resetSelection();
      widget.resetSelection = false;
    }
    List<Note> notes = new List.from(widget.notes);
    return (notes == null || notes.length == 0)
        ? (Scaffold(
            body: Center(
              child: Text('No notes to display'),
            ),
          ))
        : WillPopScope(
            onWillPop: () async {
              if (multiSelectEnabled) {
                setState(() {
                  _multiSelect.clear();
                  multiSelectEnabled = !multiSelectEnabled;
                });
                return false;
              }
              return true;
            },
            child: (Scaffold(
              body: StaggeredGridView.countBuilder(
                crossAxisCount: 2,
                itemCount: notes.length,
                itemBuilder: (BuildContext context, int index) => Card(
                  shape: (_multiSelect[index] == true)
                      ? RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: BorderSide(
                              color: Color(colors.selectedBorderDark),
                              width: 1.5))
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: 100, maxHeight: 200),
                        child: InkWell(
                          onLongPress: () {
                            setState(() {
                              multiSelect(index, 'longpress', notes[index]);
                            });
                          },
                          onTap: () {
                            if (multiSelectEnabled) {
                              setState(() {
                                multiSelect(index, 'tap', notes[index]);
                              });
                            } else {
                              viewNote(notes[index]);
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(notes[index].getTitle(), style: TextStyle(color: Color(colors.hintTextDark)),),
                              ),
                              ConstrainedBox(
                                constraints: BoxConstraints(minHeight: 100, maxHeight: 150),
                                child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(notes[index].getNote()),
                                    ),
                              ),
                            ],
                          ),

                        ),
                      ),
                      (!multiSelectEnabled)
                          ? Container(
                              color: Color(0xFF212121),
                              child: Material(
                                type: MaterialType.transparency,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                        icon: new Icon(Icons.remove_red_eye,
                                            semanticLabel: 'View Note'),
                                        onPressed: () {
                                          viewNote(notes[index]);
                                        }),
                                    IconButton(
                                        icon: new Icon(Icons.delete_outline,
                                            semanticLabel: 'Delete Note'),
                                        onPressed: () {
                                          this
                                              .showDeleteDialog()
                                              .then((value) => {
                                                    if (value)
                                                      {
                                                        _deleteNote(
                                                            notes[index]),
                                                        widget
                                                            .deleteNoteFunction(
                                                                index)
                                                      }
                                                  });
                                        }),
                                    IconButton(
                                        icon: new Icon(Icons.edit_outlined,
                                            semanticLabel: 'Edit Note'),
                                        onPressed: () {
                                          Navigator.pushNamed(
                                                  context, '/addnote',
                                                  arguments: notes[index])
                                              .then((value) => {
                                                    if (value == false){
                                                      widget.deleteNoteFunction(index),
                                                      ScaffoldMessenger.of(context).showSnackBar(SnackBarHelper.snackBarDiscarded),
                                                    }else{
                                                      ScaffoldMessenger.of(context).showSnackBar(SnackBarHelper.snackBarSaved),
                                                    },
                                                    this.setState(() {}),
                                                    widget.resetFilters()
                                                  });
                                        }),
                                  ],
                                ),
                              ),
                            )
                          : GestureDetector(
                              onTap: () {
                                setState(() {
                                  multiSelect(index, 'tap', notes[index]);
                                });
                              },
                              onLongPress: () {
                                setState(() {
                                  multiSelect(index, 'longpress', notes[index]);
                                });
                              },
                              child: Container(
                                color: Color(0xFF212121),
                                child: Material(
                                  type: MaterialType.transparency,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        (_multiSelect[index] == true)
                                            ? Icon(
                                                Icons.check_circle,
                                                size: 24.0,
                                                color: Color(
                                                    colors.selectedBorderDark),
                                              )
                                            : Icon(
                                                Icons.check_circle_outline,
                                                size: 24.0,
                                              )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
                staggeredTileBuilder: (int index) => StaggeredTile.fit(1),
              ),
              floatingActionButton: multiSelectEnabled
                  ? FloatingActionButton(
                      backgroundColor: Color(colors.floatingDeleteButtonDark),
                      onPressed: () {
                        showDeleteDialog().then((value) => {
                              if (value)
                                {
                                  _bulkDeleteNotes(widget.bulkDeleteNotes),
                                }
                            });
                      },
                      child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 28,))
                  : null,
            )),
          );
  }

  _resetSelection() {
    _multiSelectNote.clear();
    _multiSelect.clear();
    multiSelectEnabled = false;
    _selectedIds.clear();
  }

  void viewNote(Note note) {
    ViewNote(note, context);
  }

  Future<bool> showDeleteDialog() {
    return Navigator.of(context).push(
      PageRouteBuilder(
          pageBuilder: (context, _, __) => AlertDialog(
                contentPadding: EdgeInsets.fromLTRB(24.0, 24.0, 12.0, 4.0),
                title: Text('Confirmation!', style: TextStyle(color: Color(colors.textButtonDeleteDark)),),
                backgroundColor: Color(colors.dialogBackgroundDark),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('This action is irreversible!'),
                    Padding(
                      padding: const EdgeInsets.only(top:10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                              onPressed: () {
                                Navigator.pop(context, false);
                                setState(() {
                                  multiSelectEnabled = false;
                                  _multiSelect.clear();
                                  _multiSelectNote.clear();
                                  _selectedIds.clear();
                                });
                              },
                              child: Text('Cancel')),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context, true);
                            },
                            child: Text(
                              'Delete',
                              style: TextStyle(
                                color: Color(colors.textButtonDeleteDark),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          barrierColor: Color(colors.overlayBackgroundDark).withOpacity(0.75),
          opaque: false,
          barrierDismissible: true,
          transitionDuration: Duration(milliseconds: 100),
          reverseTransitionDuration: Duration(milliseconds: 100)),
    );
  }

  Future<void> _deleteNote(Note note) async {
    // await this._dbHelper.deleteNote(note.getId());
    await _notes.doc(_noteDoc).update({'notes.${note.getId().toString()}': FieldValue.delete()})
      .then((value) => {
      ScaffoldMessenger.of(context).showSnackBar(SnackBarHelper.snackBarDeleted)
    }).catchError((onError)=>{
      ScaffoldMessenger.of(context).showSnackBar(SnackBarHelper.snackBarError)
    });
  }

  Future<void> _bulkDeleteNotes(Function(Map<int, Note>) bulkDeleteNotes) async {
    // _multiSelectNote.forEach((key, value) {
    //   _selectedIds.add(value.getId());
    // });

    // await this._dbHelper.bulkDelete(_selectedIds);
    LoadingIndicator.showLoader(context, minTimer: false, timer: 1);
    _multiSelectNote.forEach((key, value) {
      _selectedIds['notes.${value.getId().toString()}'] = FieldValue.delete();
    });
    await _notes.doc(_noteDoc).update(_selectedIds).then((value) => {
      LoadingIndicator.hideLoader(context),
      ScaffoldMessenger.of(context).showSnackBar(SnackBarHelper.snackBarBulkDelete)
    }).catchError((onError)=>{
      LoadingIndicator.hideLoader(context),
      ScaffoldMessenger.of(context).showSnackBar(SnackBarHelper.snackBarError)
    });
    bulkDeleteNotes(_multiSelectNote);
    _multiSelect.clear();
    _multiSelectNote.clear();
    multiSelectEnabled = false;
  }

  void multiSelect(int index, String eventType, Note note) {
    if (eventType == 'longpress') {
      _multiSelect.clear();
      _multiSelectNote.clear();
      multiSelectEnabled = false;
    }

    if (_multiSelect == null || _multiSelect.isEmpty) {
      _multiSelect[index] = true;
      _multiSelectNote[index] = note;
      multiSelectEnabled = true;
    } else if (_multiSelect.containsKey(index)) {
      _multiSelect.remove(index);
      _multiSelectNote.remove(index);
    } else if (!_multiSelect.containsKey(index)) {
      _multiSelect[index] = true;
      _multiSelectNote[index] = note;
    }

    if (_multiSelect.isEmpty) {
      multiSelectEnabled = false;
    }
  }
}
