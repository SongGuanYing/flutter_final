import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:flutter_phoenix/flutter_phoenix.dart';

import './db/db_init.dart';
import './db/user.dart';
import './db/run_record.dart';
import './db/teach_data.dart';
import './db/current_user.dart';

double _cadenceValue = 180;
// 索引 1: 工具 - GPX、裝置、設定等
class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _unit = '公里';
  String _notification = '每天';
  File? _profileImage;
  String? selectedHeight;
  String? selectedWeight;

  final heightOptions = List.generate(61, (i) => '${140 + i} cm');

  final weightOptions = List.generate(61, (i) => '${40 + i} kg');

  double _intervalMinutes = 5.0;  // 默认5分钟
  String _reminderType = '震動';
  final List<String> _reminderTypes = ['震動', '聲音', '混合'];

  // 加载保存的设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _intervalMinutes = prefs.getDouble('intervalMinutes') ?? 5.0;
      _reminderType = prefs.getString('reminderType') ?? '震動';
    });
  }

  // 保存设置
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('intervalMinutes', _intervalMinutes);
    await prefs.setString('reminderType', _reminderType);
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();  // 初始化时加载设置
  }

  void _showUnitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('選擇單位'),
        content: DropdownButton<String>(
          value: _unit,
          isExpanded: true,
          items: ['公里', '英里'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _unit = newValue!;
            });
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _showNotificationDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('選擇通知頻率'),
        content: DropdownButton<String>(
          value: _notification,
          isExpanded: true,
          items: ['每天', '一天兩次', '兩天一次', '永不'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _notification = newValue!;
            });
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _showConnectingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('正在搜尋裝置...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('請確保穿戴裝置已開啟並在藍牙範圍內'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    // 3秒後自動關閉（模擬連接過程）
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未發現可用裝置，請重試')),
      );
    });
  }

  // 顯示已連接裝置列表
  void _showConnectedDevices(
      BuildContext context, List<Map<String, String>> devices) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('已連接裝置'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return ListTile(
                leading: const Icon(Icons.watch),
                title: Text(device['name']!),
                subtitle: Text(device['id']!),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  void _showPostureSettingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('姿勢矯正設定'),
            content: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  const Text('時間間隔（分鐘）', style: TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: _intervalMinutes,
                min: 1,
                max: 10,
                divisions: 9,
                label: _intervalMinutes.round().toString(),
                onChanged: (v) => setState(() => _intervalMinutes = v),
              ),
              Text('當前: ${_intervalMinutes.round()} 分鐘', textAlign: TextAlign.center),
              const Divider(height: 30),
              const Text('提醒方式', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField(
                value: _reminderType,
                items: _reminderTypes.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                )).toList(),
                onChanged: (v) => setState(() => _reminderType = v!),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('取消'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text('儲存'),
                onPressed: () async {
                  await _saveSettings(); // 保存到 SharedPreferences
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCadenceSettingDialog(BuildContext context) {
    double tempCadence = _cadenceValue; // 暫存滑動條的值

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(  // 關鍵：用 StatefulBuilder 讓對話框內部可重建
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('設定步頻節奏'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '當前步頻: ${tempCadence.round()} BPM', // 顯示暫存值
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    value: tempCadence,
                    min: 160,
                    max: 200,
                    divisions: 40,
                    label: tempCadence.round().toString(),
                    onChanged: (double value) {
                      setState(() {  // 這裡用 StatefulBuilder 的 setState
                        tempCadence = value; // 更新暫存值
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text('160      180      200', textAlign: TextAlign.center),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('取消'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('確認'),
                  onPressed: () {
                    setState(() {  // 更新主頁面的狀態
                      _cadenceValue = tempCadence; // 確認後才存回實際變數
                    });
                    print('設定步頻為: ${_cadenceValue.round()} BPM');
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> connectedDevices = [
      {'name': '小米手環7', 'id': 'DF:34:AB:12'},
      {'name': 'Apple Watch', 'id': 'FE:23:BC:45'},
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          '使用者介面',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // 圓形頭像
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[300],
              backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
              child: _profileImage == null
                  ? const Icon(Icons.person, size: 60, color: Colors.grey)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            '點擊更換頭像',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        const SizedBox(height: 30),

        // 身高下拉選單
        const Text('身高', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedHeight,
          menuMaxHeight: 200,
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            hintText: '選擇身高',
          ),
          items: heightOptions.map((v) => DropdownMenuItem(
            value: v,
            child: Text(v),
          )).toList(),
          onChanged: (v) => setState(() => selectedHeight = v),
        ),
        const SizedBox(height: 20),

// 體重下拉選單
        const Text('體重', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedWeight,
          menuMaxHeight: 200,
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            hintText: '選擇體重',
          ),
          items: weightOptions.map((v) => DropdownMenuItem(
            value: v,
            child: Text(v),
          )).toList(),
          onChanged: (v) => setState(() => selectedWeight = v),
        ),
        const SizedBox(height: 30),

        // 跑步相關設定區塊 (從原來的 ProfileSettingsPage 移過來，與功能 2, 3 相關)
        Card(
          elevation: 2.0,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('跑步設定', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ListTile(
                  leading: Icon(Icons.music_note, color: Theme.of(context).primaryColor),
                  title: const Text('步頻節奏引導設定', style: TextStyle(fontSize: 18)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showCadenceSettingDialog(context); // 點擊後顯示設定對話框
                  },
                ),
                const Divider(),
                ListTile( // 姿勢
                    leading: Icon(Icons.accessibility_new, color: Theme.of(context).primaryColor), // 使用主題 primaryColor
                    title: const Text('姿勢矯正提醒設定', style: TextStyle(fontSize: 18)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showPostureSettingDialog(context);
                    }
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // GPX 工具區塊 (功能 9, 10 相關)
        Card(
          elevation: 2.0,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('GPX 工具', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ListTile(
                  leading: Icon(Icons.file_upload, color: Theme.of(context).primaryColor),
                  title: const Text('匯入 GPX 檔案', style: TextStyle(fontSize: 18)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => print('lmao'),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.file_download, color: Theme.of(context).primaryColor),
                  title: const Text('匯出跑步紀錄為 GPX', style: TextStyle(fontSize: 18)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => print('lmao'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // 穿戴裝置區塊 (功能 10 相關設定)
        Card(
          elevation: 2.0,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '穿戴裝置',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                // 連接新裝置按鈕
                ListTile(
                  leading: Icon(Icons.watch, color: Theme.of(context).primaryColor),
                  title: const Text('連接新的裝置', style: TextStyle(fontSize: 18)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showConnectingDialog(context),
                ),
                const Divider(),
                // 已連接裝置列表
                ListTile(
                  leading: Icon(Icons.bluetooth_connected,
                      color: Theme.of(context).primaryColor),
                  title: const Text('連接過的裝置', style: TextStyle(fontSize: 18)),
                  subtitle: Text('${connectedDevices.length}個裝置已連接'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showConnectedDevices(context, connectedDevices),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // 通用設定區塊 (單位、通知等)
        Card(
          elevation: 2.0,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('通用設定', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ListTile(
                  leading: Icon(Icons.straighten, color: Theme.of(context).primaryColor),
                  title: Text('單位設定 ($_unit)', style: const TextStyle(fontSize: 18)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showUnitDialog,
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.notifications_none, color: Theme.of(context).primaryColor),
                  title: Text('通知設定 ($_notification)', style: const TextStyle(fontSize: 18)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showNotificationDialog,
                ),
                // 可在此添加更多設定
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // 關於 App (範例)
        Card(
          elevation: 2.0,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            leading: Icon(Icons.info_outline, color: Theme.of(context).primaryColor), // 使用主題 primaryColor
            title: const Text('關於 App', style: TextStyle(fontSize: 18)),
            trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text(
                      '關於 App',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                    content: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style.copyWith(fontSize: 16),
                        children: const [
                          TextSpan(
                            text: ' 這是一款老少適宜的運動紀錄應用程式，讓你輕鬆追蹤跑步、健走、等活動。\n\n版本：',
                          ),
                          TextSpan(
                            text: '1.0.0\n',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          TextSpan(
                            text: '\n開發者：',
                          ),
                          TextSpan(
                            text: '潘振業，宋冠穎，范嘉和，薛博徽',
                            style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('關閉'),
                      ),
                    ],
                  ),
                );
              }
          ),
        ),
        const SizedBox(height: 20),
        // 登出按鈕 (從原來的 ProfileSettingsPage 移過來)
        Center(
          child: ElevatedButton(
            onPressed: () async{
              await CurrentUser.clearCurrentUser();
              Phoenix.rebirth(context);
              print('登出');
            },
            child: const Text('登出'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), // 登出按鈕保持紅色，表示危險操作
          ),
        )
      ],
    );
  }
}