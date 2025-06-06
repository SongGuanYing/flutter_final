import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

// 索引 0: 主頁/儀表板
class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DateTime today = DateTime.now();
    int mockRunStreak = 10; // 模擬數據
    double mockTotalDistance = 55.6;
    int mockTotalRuns = 15;



    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 日曆顯示跑步日期
        Card( // 日曆外層加 Card 增加立體感
          elevation: 2.0,
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: today,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor, // 使用主題 primaryColor
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration( // 模擬跑步日期的標記
                color: Theme.of(context).colorScheme.secondary, // 使用主題 secondaryColor
                shape: BoxShape.circle,
              ),
              canMarkersOverflow: true,
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            // 模擬標記有跑步活動的日子
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                // 這裡可以根據 date 是否有跑步紀錄來顯示標記
                // 簡單模擬：假設本月 10, 15, 20, 25 有跑步
                final runDays = [10, 15, 20, 25];
                if (date.month == today.month && runDays.contains(date.day)) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary, // 使用主題 secondaryColor
                        shape: BoxShape.circle,
                      ),
                      width: 8.0,
                      height: 8.0,
                    ),
                  );
                }
                return null;
              },
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          '超慢跑總覽',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 18),
        // 總計數據卡片
        Card(
          elevation: 2.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('總距離', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${mockTotalDistance.toStringAsFixed(1)} km', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)), // 使用主題 primaryColor
                  ],
                ),
                Column(
                  children: [
                    const Text('總次數', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('$mockTotalRuns 次', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)), // 使用主題 primaryColor
                  ],
                ),
                Column(
                  children: [
                    const Text('連續達成', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('$mockRunStreak 天', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)), // 使用主題 primaryColor
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: 點擊此按鈕開始跑步追蹤，導航到 TrackRunPage 並啟動功能 (對應功能 1, 7, 9, 10)
              print('開始跑步!');
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('開始跑步', style: TextStyle(fontSize: 20)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              backgroundColor: Theme.of(context).primaryColor, // 使用主題 primaryColor
              foregroundColor: Colors.white, // 文字顏色
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          '最近跑步紀錄',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Card( // 最近一次跑步總結 (模擬列表項)
          elevation: 1.0,
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: Icon(Icons.run_circle, color: Theme.of(context).primaryColor), // 使用主題 primaryColor
            title: const Text('2023/10/26 - 3.5 km', style: TextStyle(fontSize: 18)),
            subtitle: const Text('時間: 30:00, 配速: 8:30 / km', style: TextStyle(fontSize: 16)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 點擊查看單次跑步詳細紀錄，導航到 DataAnalysisPage 的詳細頁面
              print('查看 2023/10/26 跑步詳細!');
            },
          ),
        ),
        Card( // 另一個模擬列表項
          elevation: 1.0,
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: Icon(Icons.run_circle, color: Theme.of(context).primaryColor), // 使用主題 primaryColor
            title: const Text('2023/10/24 - 3.0 km', style: TextStyle(fontSize: 18)),
            subtitle: const Text('時間: 26:15, 配速: 8:45 / km', style: TextStyle(fontSize: 16)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 點擊查看單次跑步詳細紀錄
              print('查看 2023/10/24 跑步詳細!');
            },
          ),
        ),
        // 可以添加更多最近紀錄項目
      ],
    );
  }
}