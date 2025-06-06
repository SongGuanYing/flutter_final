import 'package:sqflite/sqflite.dart';
import 'db_init.dart';

class User {
  String userID;
  String? name;
  String? password;
  String? photo;
  double? height;
  double? weight;
  int? cadence;

  User({
    required this.userID,
    this.name,
    this.password,
    this.photo,
    this.height,
    this.weight,
    this.cadence,
  });

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'name': name,
      'password': password,
      'photo': photo,
      'height': height,
      'weight': weight,
      'cadence': cadence,
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      userID: map['userID'],
      name: map['name'],
      password: map['password'],
      photo: map['photo'],
      height: map['height'],
      weight: map['weight'],
      cadence: map['cadence'],
    );
  }

  Future<void> insert() async {
    final db = await DatabaseHelper.instance.database; // 使用單例資料庫
    await db.insert(
      'user',
      toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<User>> getAll() async {
    final db = await DatabaseHelper.instance.database; // 使用單例資料庫
    final List<Map<String, dynamic>> maps = await db.query('user');
    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });
  }

  static Future<User?> getById(String id) async {
    final db = await DatabaseHelper.instance.database; // 使用單例資料庫
    final List<Map<String, dynamic>> maps = await db.query(
      'user',
      where: 'userID = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<void> update() async {
    final db = await DatabaseHelper.instance.database; // 使用單例資料庫
    await db.update(
      'user',
      toMap(),
      where: 'userID = ?',
      whereArgs: [userID],
    );
  }

  Future<void> delete() async {
    final db = await DatabaseHelper.instance.database; // 使用單例資料庫
    await db.delete(
      'user',
      where: 'userID = ?',
      whereArgs: [userID],
    );
  }
}