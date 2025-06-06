import 'package:sqflite/sqflite.dart';
import 'db_init.dart';

class RunRecord {
  String recordID;
  String userID;
  String recordFile;

  RunRecord({required this.recordID, required this.userID, required this.recordFile});

  Map<String, dynamic> toMap() {
    return {
      'recordID': recordID,
      'userID': userID,
      'recordFile': recordFile,
    };
  }

  static RunRecord fromMap(Map<String, dynamic> map) {
    return RunRecord(
      recordID: map['recordID'],
      userID: map['userID'],
      recordFile: map['recordFile'],
    );
  }

  Future<void> insert() async {
    final db = await DatabaseHelper.instance.database; // 使用單例資料庫
    await db.insert(
      'runRecord',
      toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<RunRecord>> getAll() async {
    final db = await DatabaseHelper.instance.database; // 使用單例資料庫
    final List<Map<String, dynamic>> maps = await db.query('runRecord');
    return List.generate(maps.length, (i) {
      return RunRecord.fromMap(maps[i]);
    });
  }

  static Future<RunRecord?> getById(String id) async {
    final db = await DatabaseHelper.instance.database; // 使用單例資料庫
    final List<Map<String, dynamic>> maps = await db.query(
      'runRecord',
      where: 'recordID = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return RunRecord.fromMap(maps.first);
    }
    return null;
  }

  Future<void> update() async {
    final db = await DatabaseHelper.instance.database; // 使用單例資料庫
    await db.update(
      'runRecord',
      toMap(),
      where: 'recordID = ?',
      whereArgs: [recordID],
    );
  }

  Future<void> delete() async {
    final db = await DatabaseHelper.instance.database; // 使用單例資料庫
    await db.delete(
      'runRecord',
      where: 'recordID = ?',
      whereArgs: [recordID],
    );
  }
}