import 'package:flutter/material.dart';
import 'profile.dart';
import 'record.dart';
import 'route.dart';
import 'teach.dart';
import 'main_page.dart';

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

import './db/db_init.dart';
import './db/user.dart';
import './db/run_record.dart';
import './db/teach_data.dart';
import './db/current_user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await DatabaseHelper.instance.deleteDatabase();
  await DatabaseHelper.instance.printAllTablesAndData();
  runApp(
    Phoenix(
      child: App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal, // 使用藍綠色系作為主要的 Material 3 配色基礎
        // 其他主題設定可以在這裡調整，例如 字體、卡片陰影等
      ),
      home: const HomeScreen(),
    );
  }
}

// 主畫面 Scaffold，包含 AppBar 和 BottomNavigationBar
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2; // 預設到 MainPage (首頁)



  final List<BottomNavigationBarItem> _bottomItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.map), label: '路線'),
    BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: '運動'),
    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: '首頁'),
    BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: '教學'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: '使用者'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowLoginDialog();
    });
  }

  Future<void> _checkAndShowLoginDialog() async {
    String? currentUserID = await CurrentUser.getCurrentUser();
    if (currentUserID == null) {
      _showLoginDialog();
    }
  }

  void _showLoginDialog() {
    String userID = '';
    String password = '';

    showDialog(
      context: context,
      barrierDismissible: false, // 使用者不能點外面關閉
      builder: (context) {
        return AlertDialog(
          title: const Text('登入'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: '帳號'),
                onChanged: (value) => userID = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: '密碼'),
                obscureText: true,
                onChanged: (value) => password = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // 關閉對話框
              child: const Text(''),//取消按鈕
            ),
            ElevatedButton(
              onPressed: () async {
                final user = await User.verifyLogin(userID, password);
                if (user != null) {
                  await CurrentUser.setCurrentUser(userID);
                  Navigator.of(context).pop(); // 關閉對話框
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('登入成功：$userID')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('帳號或密碼錯誤')),
                  );
                }
              },
              child: const Text('登入'),
            ),
          ],
        );
      },
    );
  }

  // 處理 BottomNavigationBar 項目點擊事件
  void _onItemTapped(int index) {
    setState(() {
      // BottomNavigationBar 的索引從 0 開始，對應 _pages 列表中的索引 1-5
      _selectedIndex = index;
    });
  }

  void handleStartRun() {
    _onItemTapped(1);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      const RoutePage(),
      const RecordPage(),
      MainPage(onStartRun: () => _onItemTapped(1),),
      const TeachPage(),
      const ProfilePage(),
    ];
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.directions_run_outlined, color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueGrey[600]!, Colors.teal[300]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _bottomItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8.0,
      ),
    );
  }
}


