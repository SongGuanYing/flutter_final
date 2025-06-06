import 'package:sqflite/sqflite.dart';
import 'db_init.dart';

class TeachData {
  int? teachID;
  String title;
  String videoUrl;

  TeachData({this.teachID, required this.title, required this.videoUrl});

  Map<String, dynamic> toMap() {
    return {
      'teachID': teachID,
      'title': title,
      'videoUrl': videoUrl,
    };
  }

  static TeachData fromMap(Map<String, dynamic> map) {
    return TeachData(
      teachID: map['teachID'],
      title: map['title'],
      videoUrl: map['videoUrl'],
    );
  }

  Future<void> insert() async {
    final db = await DatabaseHelper.instance.database; // 使用單例資料庫
    await db.insert(
      'teachData',
      toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<TeachData>> getAll() async {
    final db = await DatabaseHelper.instance.database; // 使用單例資料庫
    final List<Map<String, dynamic>> maps = await db.query('teachData');
    return List.generate(maps.length, (i) {
      return TeachData.fromMap(maps[i]);
    });
  }

  static Future<TeachData?> getById(int id) async {
    final db = await DatabaseHelper.instance.database; // 使用單例資料庫
    final List<Map<String, dynamic>> maps = await db.query(
      'teachData',
      where: 'teachID = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return TeachData.fromMap(maps.first);
    }
    return null;
  }

  Future<void> update() async {
    final db = await DatabaseHelper.instance.database; // 使用單例資料庫
    await db.update(
      'teachData',
      toMap(),
      where: 'teachID = ?',
      whereArgs: [teachID],
    );
  }

  Future<void> delete() async {
    final db = await DatabaseHelper.instance.database; // 使用單例資料庫
    await db.delete(
      'teachData',
      where: 'teachID = ?',
      whereArgs: [teachID],
    );
  }
}