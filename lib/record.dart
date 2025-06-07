import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';


// 為了讓程式碼能獨立運行，加上 main 函數和 MyApp
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Running Tracker',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const RecordPage(),
    );
  }
}

// ------------------- 數據模型 -------------------
class RunRecord {
  final DateTime date;
  final String duration;
  final double distance;
  final String pace;
  final int avgHeartRate;
  final int maxHeartRate;

  RunRecord({
    required this.date,
    required this.duration,
    required this.distance,
    required this.pace,
    required this.avgHeartRate,
    required this.maxHeartRate,
  });

  factory RunRecord.fromJson(Map<String, dynamic> json) {
    return RunRecord(
      date: DateTime.parse(json['date']),
      duration: json['duration'],
      distance: json['distance'],
      pace: json['pace'],
      avgHeartRate: json['avgHeartRate'],
      maxHeartRate: json['maxHeartRate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'duration': duration,
      'distance': distance,
      'pace': pace,
      'avgHeartRate': avgHeartRate,
      'maxHeartRate': maxHeartRate,
    };
  }
}


// ------------------- 主要運動頁面 -------------------
class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  // --- 所有狀態變數 ---
  final MapController _mapController = MapController();
  bool _isMetronomePlaying = false;
  int _targetBPM = 150;
  final int _baseBPM = 120;
  late AudioPlayer _metronomePlayer;
  bool _isAudioPlayerInitialized = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _elapsedTime = '00:00:00';
  bool _isRunning = false;
  double _currentDistance = 0.0;
  String _currentPace = '00:00';
  final double _averageSlowRunSpeedKph = 6.0;
  int _currentHeartRate = 75;
  final int _restingHeartRate = 75;
  final int _runningHeartRateMin = 130;
  final int _runningHeartRateMax = 170;
  final Random _random = Random();
  List<int> _heartRateHistory = [];
  int _maxHeartRate = 75;
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStreamSubscription;
  List<RunRecord> _runHistory = [];


  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
    _checkAndRequestLocationPermission();
    _loadRunHistory();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    if (_isAudioPlayerInitialized) {
      _metronomePlayer.dispose();
    }
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/run_history.json');
  }

  Future<void> _loadRunHistory() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        return;
      }
      final contents = await file.readAsString();
      final List<dynamic> jsonList = json.decode(contents);
      setState(() {
        _runHistory = jsonList.map((jsonItem) => RunRecord.fromJson(jsonItem)).toList();
      });
    } catch (e) {
      print("讀取記錄時發生錯誤: $e");
    }
  }

  Future<void> _saveHistoryToFile() async {
    try {
      final file = await _localFile;
      final jsonList = _runHistory.map((record) => record.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      print("儲存記錄時發生錯誤: $e");
    }
  }

  // 新增：刪除單筆記錄的方法
  Future<void> _deleteRunRecord(int index) async {
    setState(() {
      _runHistory.removeAt(index);
    });
    await _saveHistoryToFile();
  }

  void _saveRunRecord() {
    final avgHeartRate = _heartRateHistory.isNotEmpty
        ? (_heartRateHistory.reduce((a, b) => a + b) / _heartRateHistory.length).round()
        : _currentHeartRate;

    final record = RunRecord(
      date: DateTime.now(),
      duration: _elapsedTime.substring(0, 5),
      distance: _currentDistance,
      pace: _currentPace,
      avgHeartRate: avgHeartRate,
      maxHeartRate: _maxHeartRate,
    );
    setState(() {
      _runHistory.insert(0, record);
    });
    _saveHistoryToFile();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('運動記錄已保存！距離: ${_currentDistance.toStringAsFixed(0)}公尺'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _initializeAudioPlayer() async {
    _metronomePlayer = AudioPlayer();
    try {
      await _metronomePlayer.setVolume(0.8);
      setState(() {
        _isAudioPlayerInitialized = true;
      });
    } catch (e) {
      print('初始化節拍器音頻播放器失敗: $e');
    }
  }

  Future<void> _checkAndRequestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請啟用位置服務以追蹤您的位置。')),
      );
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('位置權限已被拒絕。')),
        );
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('位置權限已被永久拒絕，請在設定中開啟。')),
      );
      return;
    }
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    );
    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      LatLng newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = newLocation;
      });
      _mapController.move(newLocation, 19.0);
    });
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _stopwatch.start();
    _heartRateHistory.clear();
    _maxHeartRate = _currentHeartRate;
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      setState(() {
        _elapsedTime = _formatDurationWithCentiseconds(_stopwatch.elapsed);
        _updateDistanceAndPace();
        _updateHeartRate();
      });
    });
    if (_isMetronomePlaying) {
      _startMetronome();
    }
  }

  void _pauseTimer() {
    setState(() => _isRunning = false);
    _stopwatch.stop();
    _timer?.cancel();
    if (_isMetronomePlaying) {
      _pauseMetronome();
    }
  }

  void _resetTimer() {
    if (_isMetronomePlaying) {
      _stopMetronome();
    }
    if (_stopwatch.elapsed.inSeconds > 0 && _currentDistance > 0) {
      _saveRunRecord();
    }
    setState(() {
      _isRunning = false;
      _stopwatch.reset();
      _elapsedTime = '00:00:00';
      _currentDistance = 0.0;
      _currentPace = '00:00';
      _currentHeartRate = _restingHeartRate;
      _heartRateHistory.clear();
      _maxHeartRate = _restingHeartRate;
    });
    _stopwatch.stop();
    _timer?.cancel();
  }

  String _formatDurationWithCentiseconds(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    int totalMilliseconds = duration.inMilliseconds;
    int centiseconds = (totalMilliseconds % 1000) ~/ 10;
    int seconds = (totalMilliseconds / 1000).floor();
    int minutes = (seconds / 60).floor();
    seconds = seconds % 60;
    return '${twoDigits(minutes)}:${twoDigits(seconds)}:${twoDigits(centiseconds)}';
  }

  void _updateDistanceAndPace() {
    final double distancePerSecond = (_averageSlowRunSpeedKph * 1000) / 3600.0;
    _currentDistance = _stopwatch.elapsed.inMilliseconds / 1000.0 * distancePerSecond;
    if (_currentDistance > 0) {
      final double distanceInKm = _currentDistance / 1000.0;
      final int totalElapsedMilliseconds = _stopwatch.elapsed.inMilliseconds;
      final int totalMillisecondsPerKm = (totalElapsedMilliseconds / distanceInKm).round();
      final int totalSecondsPerKm = totalMillisecondsPerKm ~/ 1000;
      final int minutes = totalSecondsPerKm ~/ 60;
      final int seconds = totalSecondsPerKm % 60;
      _currentPace = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      _currentPace = '00:00';
    }
  }

  void _updateHeartRate() {
    setState(() {
      if (_isRunning) {
        _currentHeartRate += _random.nextInt(5) - 2;
        _currentHeartRate = _currentHeartRate.clamp(_runningHeartRateMin - 5, _runningHeartRateMax + 5);
        _heartRateHistory.add(_currentHeartRate);
        if (_currentHeartRate > _maxHeartRate) {
          _maxHeartRate = _currentHeartRate;
        }
      } else {
        _currentHeartRate += _random.nextInt(3) - 1;
        _currentHeartRate = _currentHeartRate.clamp(_restingHeartRate - 5, _restingHeartRate + 10);
      }
    });
  }

  void _toggleMetronome() {
    setState(() => _isMetronomePlaying = !_isMetronomePlaying);
    if (_isMetronomePlaying) {
      _startMetronome();
    } else {
      _stopMetronome();
    }
  }

  Future<void> _startMetronome() async {
    if (!_isAudioPlayerInitialized) return;
    try {
      double playbackRate = (_targetBPM / _baseBPM).clamp(0.5, 2.0);
      await _metronomePlayer.setPlaybackRate(playbackRate);
      await _metronomePlayer.play(AssetSource('audios/tick1.mp3'));
    } catch (e) {
      print('啟動節拍器失敗: $e');
    }
  }

  Future<void> _pauseMetronome() async {
    try {
      await _metronomePlayer.pause();
    } catch (e) {
      print('暫停節拍器失敗: $e');
    }
  }

  Future<void> _stopMetronome() async {
    try {
      await _metronomePlayer.stop();
      setState(() => _isMetronomePlaying = false);
    } catch (e) {
      print('停止節拍器失敗: $e');
    }
  }

  Future<void> _adjustBPM(int delta) async {
    setState(() {
      _targetBPM = (_targetBPM + delta).clamp(60, 200);
    });
    if (_isMetronomePlaying && _isAudioPlayerInitialized) {
      try {
        double playbackRate = (_targetBPM / _baseBPM).clamp(0.5, 2.0);
        await _metronomePlayer.setPlaybackRate(playbackRate);
      } catch (e) {
        print('調整播放速度失敗: $e');
      }
    }
  }

  void _navigateToHistoryPage() {
    if (_runHistory.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RunHistoryPage(
            records: _runHistory,
            onDeleteRecord: _deleteRunRecord, // 傳遞刪除函數
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('目前沒有任何運動記錄。'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng mapCenter = _currentLocation ?? LatLng(23.4792, 120.4497);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 主要數據顯示卡
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Column(
                    children: [
                      Text(
                        _elapsedTime,
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildDataColumn('距離', '${_currentDistance.toStringAsFixed(0)} m', Colors.black87),
                          _buildDataColumn('配速', _currentPace, Colors.black87),
                          _buildDataColumn('心率', '$_currentHeartRate bpm', Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 節拍器控制卡
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBPMButton(Icons.remove, () => _adjustBPM(-5)),
                      _buildBPMDisplay(),
                      _buildBPMButton(Icons.add, () => _adjustBPM(5)),
                      const SizedBox(width: 16),
                      _buildMetronomeButton(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // *** 主要修正區域 (地圖) ***
              Expanded(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  clipBehavior: Clip.antiAlias,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      // [修正] 'center' -> 'initialCenter', 'zoom' -> 'initialZoom'
                      initialCenter: mapCenter,
                      initialZoom: 17.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                        // [註] 'subdomains' 參數已過時，通常可以直接移除
                      ),
                      if (_currentLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              width: 80.0,
                              height: 80.0,
                              point: _currentLocation!,
                              // [修正] 'builder' -> 'child'
                              child: Icon(
                                Icons.person_pin_circle,
                                color: Theme.of(context).primaryColor,
                                size: 40.0,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 查看歷史記錄按鈕
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60.0),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('查看運動記錄'),
                  onPressed: _navigateToHistoryPage,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: Theme.of(context).primaryColor,
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 主要控制按鈕
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: _isRunning ? Icons.pause : Icons.play_arrow,
                    onPressed: _isRunning ? _pauseTimer : _startTimer,
                    backgroundColor: _isRunning ? Colors.orange.shade600 : Colors.green.shade500,
                    size: 40,
                  ),
                  _buildControlButton(
                    icon: Icons.stop,
                    onPressed: _resetTimer,
                    backgroundColor: Colors.red.shade500,
                    size: 40,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Helper Widgets (修正 withOpacity) ---
  Widget _buildDataColumn(String label, String value, Color color, {double fontSize = 24}) => Column(children: [Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)), const SizedBox(height: 8), Text(value, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: color))]);

  // [修正] withOpacity -> withAlpha
  Widget _buildBPMButton(IconData icon, VoidCallback onPressed) => Container(decoration: BoxDecoration(color: Theme.of(context).primaryColor.withAlpha(26), borderRadius: BorderRadius.circular(8)), child: IconButton(icon: Icon(icon), onPressed: onPressed, color: Theme.of(context).primaryColor, iconSize: 20));

  // [修正] withOpacity -> withAlpha
  Widget _buildBPMDisplay() => Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: _isAudioPlayerInitialized ? Theme.of(context).primaryColor.withAlpha(26) : Colors.grey.withAlpha(77), borderRadius: BorderRadius.circular(12), border: Border.all(color: _isMetronomePlaying ? Theme.of(context).primaryColor : Colors.grey.withAlpha(128), width: 2)), child: Column(children: [Text('$_targetBPM', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _isAudioPlayerInitialized ? Theme.of(context).primaryColor : Colors.grey)), Text('BPM', style: TextStyle(fontSize: 12, color: _isAudioPlayerInitialized ? Theme.of(context).primaryColor : Colors.grey))]));

  // [修正] withOpacity -> withAlpha
  Widget _buildMetronomeButton() => Container(decoration: BoxDecoration(color: _isMetronomePlaying ? Colors.red.withAlpha(26) : Theme.of(context).primaryColor.withAlpha(26), borderRadius: BorderRadius.circular(8)), child: IconButton(icon: Icon(_isMetronomePlaying ? Icons.pause : Icons.play_arrow), onPressed: _isAudioPlayerInitialized ? _toggleMetronome : null, color: _isMetronomePlaying ? Colors.red : Theme.of(context).primaryColor, iconSize: 28));

  // [修正] withOpacity -> withAlpha
  Widget _buildControlButton({required IconData icon, required VoidCallback onPressed, required Color backgroundColor, double size = 30}) => Container(decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: backgroundColor.withAlpha(77), blurRadius: 8, offset: const Offset(0, 4))]), child: ElevatedButton(onPressed: onPressed, style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20), shape: const CircleBorder(), backgroundColor: backgroundColor, foregroundColor: Colors.white, elevation: 0), child: Icon(icon, size: size)));
}

// ------------------- 歷史紀錄頁面 (已修改：加入刪除功能) -------------------
class RunHistoryPage extends StatefulWidget {
  final List<RunRecord> records;
  final Function(int) onDeleteRecord; // 刪除記錄的回調函數

  const RunHistoryPage({
    super.key,
    required this.records,
    required this.onDeleteRecord
  });

  @override
  State<RunHistoryPage> createState() => _RunHistoryPageState();
}

class _RunHistoryPageState extends State<RunHistoryPage> {
  Future<void> _showDeleteConfirmDialog(int index) async {
    final record = widget.records[index];
    final String formattedDate = DateFormat('yyyy/MM/dd HH:mm').format(record.date);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('確認刪除'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('確定要刪除這筆運動記錄嗎？'),
                const SizedBox(height: 8),
                Text(
                  '日期：$formattedDate\n距離：${(record.distance / 1000).toStringAsFixed(2)} 公里',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('刪除', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteRecord(index);
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteRecord(int index) {
    widget.onDeleteRecord(index);
    setState(() {
      // 觸發 UI 更新
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('運動記錄已刪除'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('運動歷史記錄'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: widget.records.isEmpty
          ? const Center(
        child: Text(
          '目前沒有任何運動記錄',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: widget.records.length,
        itemBuilder: (context, index) {
          final record = widget.records[index];
          final String formattedDate = DateFormat('yyyy/MM/dd HH:mm').format(record.date);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_run,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                ],
              ),
              title: Text(
                '${(record.distance / 1000).toStringAsFixed(2)} 公里',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Text(
                '$formattedDate\n時間: ${record.duration} | 配速: ${record.pace}/km',
                style: TextStyle(color: Colors.grey[600]),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmDialog(index),
                    tooltip: '刪除記錄',
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              isThreeLine: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RunDetailPage(record: record),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ------------------- 運動詳情頁面 (已修改：加入刪除按鈕) -------------------
class RunDetailPage extends StatelessWidget {
  final RunRecord record;

  const RunDetailPage({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('yyyy年MM月dd日 HH:mm').format(record.date);

    return Scaffold(
      appBar: AppBar(
        title: Text(formattedDate),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmDialog(context),
            tooltip: '刪除記錄',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow(
                  context,
                  icon: Icons.speed,
                  label: '平均配速',
                  value: '${record.pace} /km',
                  color: Colors.orange,
                ),
                const Divider(indent: 20, endIndent: 20),
                _buildDetailRow(
                  context,
                  icon: Icons.favorite,
                  label: '平均心率',
                  value: '${record.avgHeartRate} BPM',
                  color: Colors.red,
                ),
                const Divider(indent: 20, endIndent: 20),
                _buildDetailRow(
                  context,
                  icon: Icons.whatshot,
                  label: '最高心率',
                  value: '${record.maxHeartRate} BPM',
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmDialog(BuildContext context) async {
    final String formattedDate = DateFormat('yyyy/MM/dd HH:mm').format(record.date);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('確認刪除'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('確定要刪除這筆運動記錄嗎？'),
                const SizedBox(height: 8),
                Text(
                  '日期：$formattedDate\n距離：${(record.distance / 1000).toStringAsFixed(2)} 公里',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('刪除', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // 關閉對話框
                Navigator.of(context).pop(); // 回到上一頁
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('請返回記錄列表進行刪除操作'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
