import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_final/record.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key, required this.onStartRun}) : super(key: key);
  final VoidCallback onStartRun;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late Future<Map<String, dynamic>> weatherFuture;

  @override
  void initState() {
    super.initState();
    weatherFuture = fetchChiayiWeather();
  }

  Future<Map<String, dynamic>> fetchChiayiWeather() async {
    const String apiKey = 'ef44970dfcfa4777b8985755250706'; // ← 改成你的 API 金鑰
    final url = Uri.parse('https://api.weatherapi.com/v1/current.json?key=$apiKey&q=Chiayi%20City&lang=zh');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'temp': data['current']['temp_c'],
        'condition': data['current']['condition']['text'],
        'icon': 'https:${data['current']['condition']['icon']}',
      };
    } else {
      throw Exception('無法載入天氣資料');
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime today = DateTime.now();
    int mockRunStreak = 10;
    double mockTotalDistance = 55.6;
    int mockTotalRuns = 15;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 📍 天氣資訊顯示
        FutureBuilder<Map<String, dynamic>>(
          future: weatherFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Text('❌ 無法載入天氣資料');
            } else if (snapshot.hasData) {
              final weather = snapshot.data!;
              return Card(
                elevation: 2,
                child: ListTile(
                  leading: Image.network(weather['icon'], width: 48, height: 48),
                  title: Text('嘉義市 ${weather['temp'].toStringAsFixed(1)}°C'),
                  subtitle: Text(weather['condition']),
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
        const SizedBox(height: 16),

        // 📆 日曆顯示
        Card(
          elevation: 2.0,
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: today,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              canMarkersOverflow: true,
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final runDays = [10, 15, 20, 25];
                if (date.month == today.month && runDays.contains(date.day)) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
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

        const Text('超慢跑總覽', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
        const SizedBox(height: 18),

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
                    Text('${mockTotalDistance.toStringAsFixed(1)} km',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                  ],
                ),
                Column(
                  children: [
                    const Text('總次數', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('$mockTotalRuns 次',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                  ],
                ),
                Column(
                  children: [
                    const Text('連續達成', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('$mockRunStreak 天',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
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
              widget.onStartRun();
              print('開始跑步!');
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('開始跑步', style: TextStyle(fontSize: 20)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ),

        const SizedBox(height: 30),
        const Text('最近跑步紀錄', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),

        Card(
          elevation: 1.0,
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: Icon(Icons.run_circle, color: Theme.of(context).primaryColor),
            title: const Text('2023/10/26 - 3.5 km', style: TextStyle(fontSize: 18)),
            subtitle: const Text('時間: 30:00, 配速: 8:30 / km', style: TextStyle(fontSize: 16)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              print('查看 2023/10/26 跑步詳細!');
            },
          ),
        ),

        Card(
          elevation: 1.0,
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: Icon(Icons.run_circle, color: Theme.of(context).primaryColor),
            title: const Text('2023/10/24 - 3.0 km', style: TextStyle(fontSize: 18)),
            subtitle: const Text('時間: 26:15, 配速: 8:45 / km', style: TextStyle(fontSize: 16)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              print('查看 2023/10/24 跑步詳細!');
            },
          ),
        ),
      ],
    );
  }
}
