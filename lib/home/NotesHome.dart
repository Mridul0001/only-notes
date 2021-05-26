import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:only_notes/SharedPreferencesHelper/SPHelper.dart';
import 'package:only_notes/encryption/EncryptionHelper.dart';
import 'package:only_notes/filternotes/FilterNotes.dart';
import 'package:only_notes/loadingindiactor/LoadingIndiactor.dart';
import 'package:only_notes/model/Note.dart';
import 'package:only_notes/notecards/NoteCard.dart';
import 'package:only_notes/snackbars/SnackBarHelper.dart';
import 'package:only_notes/theme/colors.dart' as colors;
import 'package:shimmer/shimmer.dart';

bool showBox = false;

class NotesHome extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _NotesHomeState();
  }
}

class _NotesHomeState extends State<NotesHome> with WidgetsBindingObserver {

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference _notesFirestore;
  CollectionReference _users;
  FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  String _uid;
  // final dbHelper = DatabaseHelper.instance;
  List<Note> originalNoteList = List<Note>.empty(growable: true);
  final noteFilterController = new TextEditingController();
  ValueNotifier<List<Note>> _notes = new ValueNotifier<List<Note>>(<Note>[]);
  OverlayEntry _overlayEntry;
  FilterOptions _filterOptions = new FilterOptions();
  bool resetSelection = false;
  FocusNode _focusNode = FocusNode();
  bool hasFocus = false;
  bool isLoading = false;

  @override
  void initState() {
    _notesFirestore = firestore.collection('notes');
    _users = firestore.collection('users');
    _uid = _firebaseAuth.currentUser.uid;
    isLoading = true;
    checkVoiceNote();
    getNotes();
    super.initState();
    _focusNode.addListener(_focusListener);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_focusListener);
    _focusNode.dispose();
    super.dispose();
  }

  void _focusListener(){
    if(_focusNode.hasFocus != hasFocus){
      setState(() {
        hasFocus = _focusNode.hasFocus;
      });
    }
  }


  final routeNames = <String>["/", "/addnote"];

  @override
  Widget build(BuildContext context) {
    final key = GlobalKey<State<BottomNavigationBar>>();

    //Home view for the app
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Expanded(
                flex: 9,
                child: TextField(
                  enabled: !isLoading,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(100)
                  ],
                  onChanged: (value) {
                    searchNotes(value);
                  },
                  focusNode: _focusNode,
                  controller: noteFilterController,
                  decoration: InputDecoration(
                    suffixIcon: hasFocus?IconButton(
                      alignment: Alignment.centerRight,
                      icon: Icon(Icons.clear, color: Color(colors.hintTextDark)),
                      splashRadius: 12,
                      onPressed: (){
                        noteFilterController.clear();
                        _notes.value = new List.from(originalNoteList);
                      },
                    ):null,
                      labelText: "Search Notes",
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                  ),
                  style: TextStyle(color: Colors.white.withOpacity(0.87)),
                ),
              ),
              Expanded(
                  flex: 1,
                  child: IconButton(
                    color: Color(colors.secondaryDark),
                    padding: EdgeInsets.all(8.0),
                    icon: Icon(Icons.info_outline),
                    // onPressed: (){
                    //   LoadingIndicator.showLoader(context, minTimer: true, timer: 2);
                    // },
                  )
              )
            ],
          ),
        ),
        body: Opacity(
          opacity: 1,
          child: isLoading?Center(
            child: Shimmer.fromColors(
              baseColor: Color(colors.elevationOneDark),
              highlightColor: Colors.grey,
              child: GridView.count(
                crossAxisCount: 2,
                children: List<Widget>.generate(6, (int index) =>
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        color: Color(colors.elevationOneDark),
                        constraints: BoxConstraints(
                          minHeight: 100,
                          maxHeight: 100
                        ),
                      ),
                    )
                )),
            ),
          ):Center(
            child: ValueListenableBuilder(
              builder: (BuildContext context, List<Note> notes, Widget child) {
                return NoteCard(notes:notes, deleteNoteFunction: deleteNoteFunction(), bulkDeleteNotes: deleteBulkNotes(), resetSelection: resetSelection, resetFilters: _resetFilters());
              },
              valueListenable: _notes,
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
          items: [
            BottomNavigationBarItem(
                icon: new Icon(Icons.sort_outlined), label: "Filters"),
            BottomNavigationBarItem(
                icon: new Icon(Icons.add, size: 36), label: "Add Note"),
            BottomNavigationBarItem(
                icon: new Icon(Icons.logout), label: "Logout"),
          ],
          onTap: _navigationActions,
        ),
      ),
    );
  }

  void Function(int) deleteNoteFunction() => (int index) =>{
    originalNoteList.removeAt(index),
    _notes.value = new List.from(originalNoteList)
  };

  void Function(Map<int, Note>) deleteBulkNotes() => (Map<int, Note> notes) => {
    notes.forEach((key, value) {
      originalNoteList.remove(value);
    }),
    _notes.value = new List.from(originalNoteList)
  };


  _navigationActions(int index) async {
    switch (index) {
      case 0:
        // show filter dialog
        this.resetSelection = true;
        showBox = !showBox;
        if (showBox) {
          this._overlayEntry = _createOverlayEntry();
          Overlay.of(context).insert(this._overlayEntry);
        }
        break;

      case 1:
        //add new note
        Navigator.pushNamed(context, "/addnote").then((value) => {
          if(value != false){
            this.resetSelection = true,
            originalNoteList = new List.from(originalNoteList)..add(value),
            ScaffoldMessenger.of(context).showSnackBar(SnackBarHelper.snackBarSaved),
            this._resetFilters()()
          }else{
            ScaffoldMessenger.of(context).showSnackBar(SnackBarHelper.snackBarDiscarded),
          }
        });
        break;

      case 2:
        //logout
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
                  Text('You are about to logout'),
                  Padding(
                    padding: const EdgeInsets.only(top:10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              return;
                            },
                            child: Text('Cancel')),
                        TextButton(
                            onPressed: () {
                              performLogoutActions();
                            },
                            child: Text('Logout')),
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
            reverseTransitionDuration: Duration(milliseconds: 100)

          ),
        );
        break;
    }
  }

  void getNotes() async {
    // await dbHelper.notes().then((value) => {
    //       originalNoteList = new List.from(value),
    //       originalNoteList.sort((a, b) => b.getDateTime().compareTo(a.getDateTime())),
    //       _notes.value = new List.from(originalNoteList)
    // });

    DocumentSnapshot data = await _notesFirestore.doc(_uid).get();
    Map<String, dynamic> notes = data.data();
    notes['notes'].forEach((key, value) {
      String noteDecrypted = EncryptionHelper.decrypt(value['note']);
      Note note = new Note(value['title'], noteDecrypted,
          value['id'], DateTime.parse(value['datetime']));
      originalNoteList.add(note);
    });
    originalNoteList.sort((a, b) => b.getDateTime().compareTo(a.getDateTime()));
    _notes.value = new List.from(originalNoteList);
    setState(() {
      isLoading = false;
    });
  }

  checkVoiceNote() async{
    String encodedVoiceNote = SPHelper.getString('voiceNote');
    var voiceNote = encodedVoiceNote != ''?jsonDecode(encodedVoiceNote):null;
    DateTime dateTime = DateTime.now();
    if(voiceNote !=null && voiceNote['body'] != ''){
      //theres a voice note
      int lastNoteId = SPHelper.getInt('lastNoteId') + 1;
      SPHelper.setInt('lastNoteId', lastNoteId);
      Note note = new Note(voiceNote['title'], voiceNote['body'], lastNoteId, dateTime);
      await _notesFirestore.doc(_uid).update({'notes.${lastNoteId.toString()}': note.toMap()}).then((value) => {
        ScaffoldMessenger.of(context).showSnackBar(SnackBarHelper.snackBarSaved)
      }).catchError((onError)=>{
        ScaffoldMessenger.of(context).showSnackBar(SnackBarHelper.snackBarError)
      });
    }else if(voiceNote !=null && voiceNote['body'] == ''){
      ScaffoldMessenger.of(context).showSnackBar(SnackBarHelper.snackBarDiscarded);
    }
    SPHelper.remove('voiceNote');
  }

  performLogoutActions() async {
      int lastNoteId = SPHelper.getInt('lastNoteId');
      await _users.doc(_firebaseAuth.currentUser.uid).update({'lastNoteId':lastNoteId});
      await FirebaseAuth.instance.signOut().then((value) => {
       SPHelper.logout(),
       ScaffoldMessenger.of(context).showSnackBar(SnackBarHelper.snackBarLogout),
       Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false)
     }).catchError((onError)=>{
       ScaffoldMessenger.of(context).showSnackBar(SnackBarHelper.snackBarError)
     });
  }

  void searchNotes(String value) {
    this.resetSelection = true;
    List<Note> noteSearchResults = List<Note>.empty(growable: true);
    String keyword = value.trim().toLowerCase();
    if (keyword != null && keyword.length != 0) {
      originalNoteList.forEach((element) {
        if (element.getTitle().toLowerCase().contains(keyword) ||
            element.getNote().toLowerCase().contains(keyword)) {
          noteSearchResults.add(element);
        }
      });
      _notes.value.clear();
      _notes.value = new List.from(noteSearchResults);
    }else{
      _notes.value = new List.from(originalNoteList);
    }
  }

  void Function(Filters filter, FilterOrder order) filterNotes() => (Filters filter, FilterOrder order) => {
    this._filterNotes(filter, order)
  };

  _filterNotes(Filters filter, FilterOrder order){
    switch(filter) {
      case Filters.length:
        if (order == FilterOrder.dsc) {
          originalNoteList
              .sort((a, b) => b.getNote().length.compareTo(a.getNote().length));
        } else {
          originalNoteList
              .sort((a, b) => a.getNote().length.compareTo(b.getNote().length));
        }
        break;

      case Filters.alphabetically:
        if (order == FilterOrder.dsc) {
          originalNoteList
              .sort((a, b) => b.getTitle().compareTo(a.getTitle()));
        } else {
          originalNoteList
              .sort((a, b) => a.getTitle().compareTo(b.getTitle()));
        }
        break;

      case Filters.date:
        if (order == FilterOrder.dsc) {
          originalNoteList
              .sort((a, b) => b.getDateTime().compareTo(a.getDateTime()));
        } else {
          originalNoteList
              .sort((a, b) => a.getDateTime().compareTo(b.getDateTime()));
        }
        break;
    }
    _notes.value.clear();
    _notes.value = new List.from(originalNoteList);
  }

  void Function() _resetFilters() => () => {
    setState(() {
      _filterOptions.setFilter(Filters.date);
      _filterOptions.setOrder(FilterOrder.dsc);
      originalNoteList.sort((a, b) => b.getDateTime().compareTo(a.getDateTime()));
      _notes.value = new List.from(originalNoteList);
    })
  };

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(builder: (context) {
      return CustomOverlayBuilder(this._overlayEntry, this._filterOptions, this.filterNotes());
    });
  }
}

class CustomOverlayBuilder extends StatefulWidget {
  final OverlayEntry overlayEntry;
  final Function(Filters filters, FilterOrder order) filterNotes;
  final FilterOptions _filterOptions;
  CustomOverlayBuilder(this.overlayEntry, this._filterOptions, this.filterNotes);
  @override
  State<StatefulWidget> createState() => _CustomOverlayBuilder();
}

class _CustomOverlayBuilder extends State<CustomOverlayBuilder> with TickerProviderStateMixin{
  AnimationController _controller;
  Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    )..repeat(reverse: false);

    _animation = Tween(
      begin: 0.0,
      end: 1.0
    ).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    var paddingTop = MediaQuery.of(context).padding.top;
    var paddingBottom = MediaQuery.of(context).padding.bottom;
    var toolbarHeight = kToolbarHeight;
    var deviceHeight = MediaQuery.of(context).size.height;
    OverlayEntry _overlayEntry = widget.overlayEntry;
    FilterOptions filterOptions = widget._filterOptions;
    return SafeArea(
      child: FadeTransition(
        opacity: _animation,
        child: Container(
          decoration: BoxDecoration(
              color: Color(colors.overlayBackgroundDark).withOpacity(0.75)
          ),
          child: Center(
            child: Material(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: (MediaQuery.of(context).size.width * 2) / 3,
                height: deviceHeight < 900
                    ? 480
                    : deviceHeight -
                        paddingBottom -
                        paddingTop -
                        toolbarHeight -
                        200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Color(colors.dialogBackgroundDark),
                ),
                child: Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Material(
                          color: Color(colors.dialogBackgroundDark),
                          child: IconButton(
                              icon: new Icon(Icons.close),
                              splashRadius: 20,
                              onPressed: () {
                                _overlayEntry.remove();
                                showBox = false;
                              }),
                        ),
                      ),
                    ),
                    Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 0, 8),
                              child: Text(
                                'Filters',
                                style: TextStyle(fontSize: 17.0, color: Color(colors.hintTextDark)),
                                textAlign: TextAlign.left,
                                textScaleFactor: 1.3,
                              ),
                            ),
                            ListTile(
                              title: const Text('Date Edited'),
                              leading: Radio<Filters>(
                                value: Filters.date,
                                groupValue: filterOptions.getFilter(),
                                onChanged: (Filters value) {
                                  setState(() {
                                    filterOptions.setFilter(value);
                                  });
                                },
                              ),
                            ),
                            ListTile(
                              title: const Text('Note Length'),
                              leading: Radio<Filters>(
                                value: Filters.length,
                                groupValue: filterOptions.getFilter(),
                                onChanged: (Filters value) {
                                  setState(() {
                                    filterOptions.setFilter(value);
                                  });
                                },
                              ),
                            ),
                            ListTile(
                              title: const Text('Title'),
                              leading: Radio<Filters>(
                                value: Filters.alphabetically,
                                groupValue: filterOptions.getFilter(),
                                onChanged: (Filters value) {
                                  setState(() {
                                    filterOptions.setFilter(value);
                                  });
                                },
                              ),
                            ),
                          ],
                        )),
                    Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 0, 8),
                              child: Text(
                                'Order',
                                style: TextStyle(fontSize: 17.0, color: Color(colors.hintTextDark)),
                                textAlign: TextAlign.left,
                                textScaleFactor: 1.3,
                              ),
                            ),
                            ListTile(
                              title: const Text('Ascending'),
                              leading: Radio<FilterOrder>(
                                value: FilterOrder.asc,
                                groupValue: filterOptions.getOrder(),
                                onChanged: (FilterOrder value) {
                                  setState(() {
                                    filterOptions.setOrder(value);
                                  });
                                },
                              ),
                            ),
                            ListTile(
                              title: const Text('Descending'),
                              leading: Radio<FilterOrder>(
                                value: FilterOrder.dsc,
                                groupValue: filterOptions.getOrder(),
                                onChanged: (FilterOrder value) {
                                  setState(() {
                                    filterOptions.setOrder(value);
                                  });
                                },
                              ),
                            ),
                          ],
                        )),
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Expanded(
                              child: TextButton(
                                  onPressed: () {
                                    widget.filterNotes(
                                        filterOptions.getFilter(),
                                        filterOptions.getOrder());
                                    _overlayEntry.remove();
                                    showBox = false;
                                  },
                                  child: Text('Apply'))),
                          Expanded(
                              child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      filterOptions.setFilter(Filters.date);
                                      filterOptions.setOrder(FilterOrder.dsc);
                                      widget.filterNotes(
                                         filterOptions.getFilter(),
                                         filterOptions.getOrder());
                                      _overlayEntry.remove();
                                      showBox = false;
                                    });
                                  },
                                  child: Text('Reset')))
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _resetFocus(){
    FocusScopeNode currentFocus = FocusScope.of(context);

    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus.unfocus();
    }
  }
}
