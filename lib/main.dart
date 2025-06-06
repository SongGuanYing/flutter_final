import 'package:flutter/material.dart';
import 'profile.dart';
import 'record.dart';
import 'route.dart';
import 'teach.dart';
import 'main_page.dart';

import './db/db_init.dart';
import './db/user.dart';
import './db/run_record.dart';
import './db/teach_data.dart';

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await DatabaseHelper.instance.deleteDatabase();
  await DatabaseHelper.instance.printAllTablesAndData();
  runApp(App());
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
  // 追蹤當前選中的頁面索引
  int _selectedIndex = 0;

  // 定義所有頁面 Widget 列表，順序對應 _selectedIndex
  // 索引 0 對應 AppBar 的 Home 按鈕
  // 索引 1-5 對應 BottomNavigationBar 的項目
  final List<Widget> _pages = [
    const RoutePage(),           // 索引 4: 路線
    const RecordPage(),         // 索引 2: 運動
    const MainPage(),        // 索引 0: 主頁/儀表板
    const TeachPage(),         // 索引 5: 教學
    const ProfilePage(),            // 索引 1: 工具 (新的分頁)
  ];

  // 處理 BottomNavigationBar 項目點擊事件
  void _onItemTapped(int index) {
    setState(() {
      // BottomNavigationBar 的索引從 0 開始，對應 _pages 列表中的索引 1-5
      _selectedIndex = index;
    });
  }

  // 定義 BottomNavigationBar 的項目列表
  final List<BottomNavigationBarItem> _bottomItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.map), label: '路線'),
    BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: '運動'),
    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: '首頁'),
    BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: '教學'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: '使用者'), // 使用工具箱圖示，標籤為工具
  ];

  @override
  Widget build(BuildContext context) {
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
        // Removed the home button from actions
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _bottomItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8.0,
      ),
    );
  }
}

