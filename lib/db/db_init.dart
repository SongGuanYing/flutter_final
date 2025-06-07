import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_final/db/db_data_init.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    final dbDataInit = DbDataInit();
    await DbDataInit.initializeSampleData();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    WidgetsFlutterBinding.ensureInitialized();

    final databasePath = join(await getDatabasesPath(), 'goodPace_database.db');

    bool exists = await databaseExists(databasePath);
    if (exists) {
      print('資料庫已存在: $databasePath');
      return await openDatabase(
        databasePath,
        version: 2,
      );
    } else {
      print('資料庫不存在，將創建新資料庫: $databasePath');
      //await DatabaseHelper.instance.deleteDatabase();

      return await openDatabase(
        databasePath,
        onCreate: (db, version) async {
          try {
            // 啟用外鍵約束
            await db.execute('PRAGMA foreign_keys = ON;');

            // 建立 user 表
            await db.execute('''
              CREATE TABLE user (
                userID VARCHAR(50) PRIMARY KEY,
                name VARCHAR(100),
                password VARCHAR(100),
                photo VARCHAR(255),
                height DOUBLE,
                weight DOUBLE,
                cadence INT
              )
            ''');

            // 建立 teachData 表
            await db.execute('''
              CREATE TABLE teachData (
                teachID INTEGER PRIMARY KEY AUTOINCREMENT,
                title VARCHAR(255),
                videoUrl VARCHAR(255)
              )
            ''');

            // 建立 runRecord 表
            await db.execute('''
              CREATE TABLE runRecord (
                recordID VARCHAR(50) PRIMARY KEY,
                userID VARCHAR(50),
                recordFile VARCHAR(255),
                FOREIGN KEY (userID) REFERENCES user(userID)
              )
            ''');
            await db.execute('''
              CREATE TABLE currentUser (
                userID VARCHAR(50) PRIMARY KEY
              )
            ''');
          } catch (e) {
            print('建立資料表失敗: $e');
            rethrow; // 拋出異常以便進一步除錯
          }
        },
        version: 2,
      );
    }
  }

  // 檢查所有表是否正確建立
  Future<List<String>> getTableNames() async {
    final db = await database;
    final List<Map<String, dynamic>> tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';",
    );
    return tables.map((table) => table['name'] as String).toList();
  }

  // 刪除資料庫
  Future<void> deleteDatabase() async {
    final databasePath = join(await getDatabasesPath(), 'goodPace_database.db');
    try {
      await databaseFactory.deleteDatabase(databasePath);
      print('資料庫已刪除: $databasePath');
      _database = null; // Reset the database instance
    } catch (e) {
      print('刪除資料庫失敗: $e');
      rethrow;
    }
  }

  // 印出所有表名稱及內容
  Future<void> printAllTablesAndData() async {
    final db = await database;
    final tables = await getTableNames();

    if (tables.isEmpty) {
      print('資料庫中沒有表');
      return;
    }

    print('=== 資料庫中的表 ===');
    for (String table in tables) {
      print('表: $table');
      final List<Map<String, dynamic>> rows = await db.query(table);
      if (rows.isEmpty) {
        print('  無資料');
      } else {
        print('  內容:');
        for (var row in rows) {
          print('    $row');
        }
      }
    }
    print('=================');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}