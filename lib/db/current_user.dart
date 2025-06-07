import 'package:sqflite/sqflite.dart';
import 'db_init.dart';

class CurrentUser {
  final String userID;

  CurrentUser({required this.userID});

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
    };
  }

  /// 插入或取代當前使用者
  static Future<void> setCurrentUser(String userID) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'currentUser',
      {'userID': userID},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 取得當前使用者
  static Future<String?> getCurrentUser() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> result = await db.query('currentUser');

    if (result.isNotEmpty) {
      return result.first['userID'] as String;
    }
    return null;
  }

  /// 移除當前使用者（例如登出時）
  static Future<void> clearCurrentUser() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('currentUser');
  }

  /// 是否已登入
  static Future<bool> isLoggedIn() async {
    final userID = await getCurrentUser();
    return userID != null;
  }
}