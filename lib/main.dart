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
  //await DatabaseHelper.instance.deleteDatabase();
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
  int _selectedIndex = 2;
  final GlobalKey<RecordPageState> _recordPageKey = GlobalKey<RecordPageState>();

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
      barrierDismissible: false,
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
              onPressed: () async {
                final user = await User.verifyLogin('user1', 'password123');
                if (user != null) {
                  await CurrentUser.setCurrentUser('user1');
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('登入成功：user1')),
                  );
                  Phoenix.rebirth(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('帳號或密碼錯誤')),
                  );
                }
              },
              child: const Text(''),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = await User.verifyLogin(userID, password);
                if (user != null) {
                  await CurrentUser.setCurrentUser(userID);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('登入成功：$userID')),
                  );
                  Phoenix.rebirth(context);
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void handleStartRun() {
    _onItemTapped(1);
  }

  // main.dart in _HomeScreenState

  void _handleStartRoute(RouteData route) {
    // 1. 加入 print 指令
    print('[main.dart] 指令已發出：載入 ${route.name} 到 RecordPage。');
    _recordPageKey.currentState?.loadNewRoute(route.gpxPath, route.name);
    _onItemTapped(1);
  }


  // main.dart in _HomeScreenState

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      RoutePage(onStartRoute: _handleStartRoute),
      RecordPage(key: _recordPageKey),
      MainPage(onStartRun: () => _onItemTapped(1)),
      const TeachPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.directions_run_outlined, color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '好腳步',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
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
      // --- 核心修改在此 ---
      // 將 body: pages[_selectedIndex],
      // 換成 IndexedStack
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      // ---------------------
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


