import 'dart:io';

import 'package:only_notes/model/Note.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final _databaseName = "only_notes_database.db";
  static final _databaseVersion = 1;

  static final _table = 'notes';

  static final _id = 'id';
  static final _title = 'title';
  static final _note = 'note';
  static final _dateAndTime = 'datetime';
  // make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // only have a single app-wide reference to the database
  static Database _database;
  Future<Database> get database async {
    if (_database != null) return _database;
    // lazily instantiate the db the first time it is accessed
    _database = await _initDatabase();
    return _database;
  }

  // this opens the database (and creates it if it doesn't exist)
  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $_table (
            $_id INTEGER PRIMARY KEY,
            $_title TEXT,
            $_note TEXT,
            $_dateAndTime TEXT NOT NULL
          )
          ''');
  }

  Future<void> insertNote(Note note) async {
    final Database db = await database;
    await db.insert(_table, note.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Note>> notes() async {
    final Database db = await database;
    var noteMaps = await db.query(_table);

    return List.generate(noteMaps.length, (index) {
      return Note(noteMaps[index]['title'], noteMaps[index]['note'],
          noteMaps[index]['id'], DateTime.parse(noteMaps[index]['datetime']));
    });
  }

  Future<void> updateNote(Note note) async {
    final db = await database;

    await db.update(_table, note.toMap(),
        where: 'id = ?', whereArgs: [note.getId()]);
  }

  Future<void> deleteNote(int id) async {
    final db = await database;

    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> bulkDelete(List<int> ids) async {
    final db = await database;
    String inID = "(";
    for(int i=0; i<ids.length - 1; i++){
      inID = inID + "?, ";
    }
    inID = inID + "?)";
    await db.delete(
        _table,
        where: 'id IN $inID',
        whereArgs: ids);
  }
}
