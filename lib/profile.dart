import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_final/record.dart';

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

  User? currentUser;

  String? selectedName;
  String? selectedHeight;
  String? selectedWeight;



  void _loadCurrentUser() async {
    currentUser = await User.getCurrentUser();
    if (currentUser != null) {
      setState(() {
        selectedName = currentUser?.name;
        selectedHeight = currentUser?.height.toString();
        selectedWeight = currentUser?.weight.toString();
        _cadenceValue=currentUser!.cadence!.toDouble();
      });
    }
    print('使用者名稱: ${currentUser?.name}');
  }

  final TextEditingController _editController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  @override
  void dispose() {
    heightController.dispose();
    weightController.dispose();
    _editController.dispose();
    super.dispose();
  }

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

    _loadCurrentUser();
    _loadSettings();  // 初始化时加载设置
    super.initState();
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
                  Row(
                    children: const [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('160'),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.center,
                          child: Text('180'),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text('200'),
                        ),
                      ),
                    ],
                  ),
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
                      currentUser?.cadence=_cadenceValue.round();
                      currentUser?.insert();
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

  /*Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }*/

  Future<void> _pickAndSaveImagePath() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      currentUser!.photo= savedImage.path;
      await currentUser?.insert();
      print("currentUser: ${currentUser?.photo}");
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果 currentUser 尚未加載完成，顯示加載指示器
    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<Map<String, String>> connectedDevices = [
      {'name': '小米手環7', 'id': 'DF:34:AB:12'},
      {'name': 'Apple Watch', 'id': 'FE:23:BC:45'},
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '${currentUser!.name}',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // 圓形頭像
        Center(
          child: GestureDetector(
            onTap: _pickAndSaveImagePath,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[300],
              backgroundImage: currentUser!.photo.isNotEmpty
                  ? FileImage(File(currentUser!.photo))
                  : null,
              child:  currentUser!.photo.isEmpty
                  ? Icon(Icons.person, size: 60, color: Colors.grey)
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

        Card(
          margin: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 姓名
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '姓名',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Row(
                      children: [
                        Text(selectedName ?? '未設定'),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () {
                            _showEditDialog('姓名', selectedName, (val) {
                              setState(() {
                                selectedName = val;
                                currentUser?.name=selectedName;
                                currentUser?.insert();
                              });
                            }, keyboardType: TextInputType.text);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(),

                // 身高
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('身高', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Row(
                      children: [
                        Text(selectedHeight != null && selectedHeight!.isNotEmpty ? '${selectedHeight} cm' : '未設定'),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () {
                            _showEditDialog('身高 (cm)', selectedHeight, (val) {
                              setState(()  {
                                selectedHeight = val;
                                currentUser?.height=double.parse(selectedHeight!);
                                currentUser?.insert();
                              });
                            }, keyboardType: TextInputType.number);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(),

                // 體重
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('體重', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Row(
                      children: [
                        Text(selectedWeight != null && selectedWeight!.isNotEmpty ? '${selectedWeight} kg' : '未設定'),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () {
                            _showEditDialog('體重 (kg)', selectedWeight, (val) {
                              setState(()  {
                                selectedWeight = val;
                                currentUser?.weight=double.parse(selectedWeight!);
                                currentUser?.insert();
                              });
                            }, keyboardType: TextInputType.number);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),



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
                  onTap: () async {
                    print('[UI] 使用者點擊匯入 GPX');

                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                      type: FileType.any,
                    );

                    if (result != null && result.files.single.path != null) {
                      String filePath = result.files.single.path!;
                      print('[UI] 選擇的 GPX 檔案路徑: $filePath');

                      // 導向 record.dart，並傳遞檔案路徑
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: null, // 隱藏 AppBar
                            body: RecordPage(routeGpxPath: filePath),
                          ),
                        ),
                      );
                    } else {
                      print('[UI] 使用者取消選擇 GPX 檔案');
                    }
                  },
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
        /*
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
        */
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



  Future<void> _showEditDialog(String title, String? currentValue, Function(String) onSave, {TextInputType keyboardType = TextInputType.text}) async {
    _editController.text = currentValue ?? '';
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('編輯 $title'),
        content: TextField(
          autofocus: true,
          controller: _editController,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: '請輸入 $title',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              onSave(_editController.text.trim());
              Navigator.of(context).pop();
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }
}