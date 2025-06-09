import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'package:gpx/gpx.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'run_history.dart';
import  'record.dart';
import 'package:intl/intl.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key, required this.onStartRun}) : super(key: key);
  final VoidCallback onStartRun;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late Future<Map<String, dynamic>> weatherFuture;
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, String> _dateNotes = {};
  List<int> _runDays = []; // 假設這些日期有跑步紀錄

  @override
  void initState() {
    super.initState();
    weatherFuture = fetchChiayiWeather();
    _extractRunDays();
  }

  void _extractRunDays() {
    _runDays = RunHistory.runHistory
        .map((record) => record.date.day)
        .toSet() // 若你想要避免重複
        .toList()
      ..sort(); // 排序是可選的
  }

  Future<Map<String, dynamic>> fetchChiayiWeather() async {
    const String apiKey = 'ef44970dfcfa4777b8985755250706';
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

  void _handleDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('筆記 ${selectedDay.toLocal().toString().split(' ')[0]}'),
        content: TextField(
          controller: TextEditingController(
              text: _dateNotes[DateTime(selectedDay.year, selectedDay.month, selectedDay.day)] ?? ''
          ),
          onChanged: (value) {
            _dateNotes[DateTime(selectedDay.year, selectedDay.month, selectedDay.day)] = value;
          },
          maxLines: 3,
          decoration: InputDecoration(hintText: '請輸入：'),
        ),
        actions: [
          TextButton(
            child: Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('保存'),
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMarker(DateTime date) {
    _extractRunDays();
    final hasNote = _dateNotes.containsKey(DateTime(date.year, date.month, date.day));
    final isRunDay = _runDays.contains(date.day) && date.month == _selectedDay.month;

    if (hasNote || isRunDay) {
      return Positioned(
        right: 1,
        bottom: 1,
        child: Container(
          decoration: BoxDecoration(
            color: hasNote ? Colors.redAccent : Theme.of(context).colorScheme.secondary,
            shape: BoxShape.circle,
          ),
          width: 8,
          height: 8,
        ),
      );
    }
    return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    int mockRunStreak = 10;
    double mockTotalDistance = 55.6;
    int mockTotalRuns = 15;
    double totalDistance=0.0;
    int count=RunHistory.runHistory.length;
    for(int i=0;i<RunHistory.runHistory.length;i++){
      totalDistance+=RunHistory.runHistory[i].distance;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 天氣資訊顯示 (保持不變)
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

        // 修改後的日曆顯示
        Card(
          elevation: 2.0,
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _selectedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: _handleDaySelected,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blueAccent,
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
              markerBuilder: (context, date, events) => _buildMarker(date),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // 以下保持不變...
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
                    Text('${(totalDistance/1000).toStringAsFixed(1)} km',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                  ],
                ),
                Column(
                  children: [
                    const Text('總次數', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('$count 次',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                  ],
                ),
                Column(
                  children: [
                    const Text('連續達成', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('2 天',
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

        /*Card(
          elevation: 1.0,
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: Icon(Icons.run_circle, color: Theme.of(context).primaryColor),
            title: const Text('2023/10/26 - 3.5 km', style: TextStyle(fontSize: 18)),
            subtitle: const Text('時間: 30:00, 配速: 8:30 / km', style: TextStyle(fontSize: 16)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GpxFromAssetsPage(gpxAssetPath: 'assets/gpx/2023_10_26.gpx'),
                ),
              );
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GpxFromAssetsPage(gpxAssetPath: 'assets/gpx/2023_10_24.gpx'),
                ),
              );
              print('查看 2023/10/24 跑步詳細!');
            },
          ),
        ),*/

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: RunHistory.runHistory.length,
          itemBuilder: (context, index) {
            final record = RunHistory.runHistory[index];
            return Card(
              elevation: 1.0,
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                leading: Icon(Icons.run_circle, color: Theme.of(context).primaryColor),
                title: Text(
                  '${DateFormat('yyyy/MM/dd').format(record.date)} - ${(record.distance / 1000).toStringAsFixed(2)} km',
                  style: const TextStyle(fontSize: 18),
                ),
                subtitle: Text(
                  '時間: ${record.duration}, 配速: ${record.pace} / km',
                  style: const TextStyle(fontSize: 16),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          RunHistory.runHistory.removeAt(index);
                        });
                      },
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RunDetailPage(record: record),

                    ),
                  );
                  setState(() {});
                },
              ),
            );
          },
        ),
      ],
    );
  }
}



// ----------------------- gpx

class GpxFromAssetsPage extends StatefulWidget {
  final String gpxAssetPath;

  const GpxFromAssetsPage({super.key, required this.gpxAssetPath});

  @override
  State<GpxFromAssetsPage> createState() => _GpxFromAssetsPageState();
}

class _GpxFromAssetsPageState extends State<GpxFromAssetsPage> {
  final MapController _mapController = MapController();
  List<LatLng> _points = [];
  LatLngBounds? _bounds;

  @override
  void initState() {
    super.initState();
    _loadGpx();
  }

  Future<void> _loadGpx() async {
    final gpxString = await rootBundle.loadString(widget.gpxAssetPath);
    final gpx = GpxReader().fromString(gpxString);

    final pts = gpx.trks
        .expand((t) => t.trksegs)
        .expand((s) => s.trkpts)
        .map((pt) => LatLng(pt.lat!, pt.lon!))
        .toList();

    if (pts.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(pts);
      setState(() {
        _points = pts;
        _bounds = bounds;
      });

      Future.delayed(Duration(milliseconds: 200), () {
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(32)),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assets GPX 地圖')),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          // 初始視野使用 bounds，自動 center 與 zoom
          initialCameraFit: _bounds != null
              ? CameraFit.bounds(bounds: _bounds!)
              : null,
          maxZoom: 18,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.myapp',
          ),
          if (_points.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _points,
                  color: Colors.blue,
                  strokeWidth: 4,
                ),
              ],
            ),
          if (_points.isNotEmpty)
            MarkerLayer(
              markers: [
                Marker(
                  point: _points.first,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on, color: Colors.green, size: 32),
                ),
                Marker(
                  point: _points.last,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on, color: Colors.red, size: 32),
                ),
              ],
            ),
        ],
      ),
    );
  }
}