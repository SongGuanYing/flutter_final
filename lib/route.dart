import 'package:flutter/material.dart';

// 索引 4: 路線 - 路線推薦與 GPX (功能 8, 部分 9/10)
class RoutePage extends StatelessWidget {
  const RoutePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 模擬推薦路線數據
    final mockRoutes = [
      {'name': '公園環湖路線', 'distance': '3.0 km', 'duration': '約 30 分鐘'},
      {'name': '河濱自行車道', 'distance': '5.2 km', 'duration': '約 50 分鐘'},
    ];

    // 模擬已儲存路線數據 (這個區塊的功能已部分移至工具頁，這裡只保留列表外觀)
    final mockSavedRoutes = [
      {'name': '我家附近的路線 A', 'distance': '2.5 km'},
      {'name': '學校操場路線', 'distance': '1.2 km'},
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          '跑步路線',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Card( // 路線推薦區塊 (功能 8)
          elevation: 2.0,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('推薦路線', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text('根據您的位置推薦周圍的優質跑步路線：', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                ...mockRoutes.map((route) => ListTile( // 模擬推薦路線列表項
                  leading: Icon(Icons.map_outlined, color: Theme.of(context).colorScheme.secondary), // 使用主題 secondaryColor
                  title: Text(route['name']!, style: const TextStyle(fontSize: 18)),
                  subtitle: Text('${route['distance']}, ${route['duration']}', style: const TextStyle(fontSize: 16)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: 點擊查看推薦路線詳情或導航
                    print('查看推薦路線: ${route['name']}');
                  },
                )).toList(),
                const SizedBox(height: 10),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: 實現尋找更多推薦路線功能 (功能 8)
                      print('尋找更多推薦路線!');
                    },
                    child: const Text('尋找更多路線'),
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white), // 使用主題 primaryColor
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card( // 已儲存路線區塊 (保留列表外觀)
          elevation: 2.0,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('已儲存路線', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...mockSavedRoutes.map((route) => ListTile( // 模擬已儲存路線列表項
                  leading: Icon(Icons.save, color: Theme.of(context).primaryColor), // 使用主題 primaryColor
                  title: Text(route['name']!, style: const TextStyle(fontSize: 18)),
                  subtitle: Text('${route['distance']}', style: const TextStyle(fontSize: 16)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: 點擊查看已儲存路線詳情或用於運動
                    print('查看已儲存路線: ${route['name']}');
                  },
                )).toList(),
              ],
            ),
          ),
        ),
        // 原來的 GPX 工具區塊已移至 ToolsPage
      ],
    );
  }
}