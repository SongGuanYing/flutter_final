import 'package:flutter/material.dart';

// 索引 1: 工具 - GPX、裝置、設定等
class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          '工具與設定', // 新頁面標題
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
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
                  leading: Icon(Icons.music_note, color: Theme.of(context).primaryColor), // 使用主題 primaryColor
                  title: const Text('步頻節奏引導設定', style: TextStyle(fontSize: 18)),
                  trailing: const Icon(Icons.chevron_right),
                  // TODO: 點擊後導航到步頻設定頁面 (功能 2 設定)
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.accessibility_new, color: Theme.of(context).primaryColor), // 使用主題 primaryColor
                  title: const Text('姿勢矯正提醒設定', style: TextStyle(fontSize: 18)),
                  trailing: const Icon(Icons.chevron_right),
                  // TODO: 點擊後導航到姿勢提醒設定頁面 (功能 3 設定)
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
                ListTile( // 匯入 GPX
                    leading: Icon(Icons.file_upload, color: Theme.of(context).primaryColor), // 使用主題 primaryColor
                    title: const Text('匯入 GPX 檔案', style: TextStyle(fontSize: 18)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: 實現 GPX 匯入功能
                      print('匯入 GPX');
                    }
                ),
                const Divider(),
                ListTile( // 匯出 GPX
                    leading: Icon(Icons.file_download, color: Theme.of(context).primaryColor), // 使用主題 primaryColor
                    title: const Text('匯出跑步紀錄為 GPX', style: TextStyle(fontSize: 18)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: 實現 GPX 匯出功能
                      print('匯出 GPX');
                    }
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
                const Text('穿戴裝置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ListTile(
                    leading: Icon(Icons.watch, color: Theme.of(context).primaryColor), // 使用主題 primaryColor
                    title: const Text('連接新的裝置', style: TextStyle(fontSize: 18)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: 導航到裝置配對頁面
                      print('連接裝置');
                    }
                ),
                const Divider(),
                ListTile(
                    leading: Icon(Icons.bluetooth_connected, color: Theme.of(context).primaryColor), // 使用主題 primaryColor
                    title: const Text('已連接裝置', style: TextStyle(fontSize: 18)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: 導航到已連接裝置列表頁面
                      print('查看已連接裝置');
                    }
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
                  leading: Icon(Icons.straighten, color: Theme.of(context).primaryColor), // 使用主題 primaryColor
                  title: const Text('單位設定 (公里/英里)', style: TextStyle(fontSize: 18)),
                  trailing: const Icon(Icons.chevron_right),
                  // TODO: 點擊後導航到單位設定頁面
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.notifications_none, color: Theme.of(context).primaryColor), // 使用主題 primaryColor
                  title: const Text('通知設定', style: TextStyle(fontSize: 18)),
                  trailing: const Icon(Icons.chevron_right),
                  // TODO: 點擊後導航到通知設定頁面
                ),
                // TODO: 添加更多通用設定項目
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
              // TODO: 顯示 App 資訊或導航到關於頁面
              print('關於 App');
            },
          ),
        ),
        const SizedBox(height: 20),
        // 登出按鈕 (從原來的 ProfileSettingsPage 移過來)
        Center(
          child: ElevatedButton(
            onPressed: () {
              // TODO: 實現登出功能
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