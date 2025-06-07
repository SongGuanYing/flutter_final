import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'db_init.dart';
import 'teach_data.dart';
import 'run_record.dart';
import 'user.dart';

class DbDataInit {
  // Make the method static
  static Future<void> initializeSampleData() async {
      final db = await DatabaseHelper.instance.database;

      // Insert User
      User user = User(
        userID: 'user1',
        name: 'John Doe',
        password: 'password123',
        photo:'',
        height: 175.0,
        weight: 70.0,
        cadence: 180,
      );
      if(await User.getById(user.userID) == null) {
        await user.insert();
      }
      // Insert TeachData
      TeachData teachData = TeachData(
        title: '跑步技巧',
        videoUrl: 'http://example.com/video',
      );
      await teachData.insert();

      // Insert RunRecords
      RunRecord runRecord = RunRecord(
        recordID: 'record1',
        userID: 'user1',
        recordFile: 'path/to/record1',
      );
      await runRecord.insert();

      // Query all data
      List<User> users = await User.getAll();
      List<TeachData> teachDatas = await TeachData.getAll();
      List<RunRecord> runRecords = await RunRecord.getAll();

      print('Users: $users');
      print('TeachData: $teachDatas');
      print('RunRecord: $runRecords');

  }
}