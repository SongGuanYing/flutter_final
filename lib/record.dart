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
import 'package:gpx/gpx.dart';
import 'package:flutter/services.dart';
import './db/db_init.dart';
import './db/user.dart';
import './db/run_record.dart';
import './db/teach_data.dart';
import './db/current_user.dart';
import 'run_history.dart';

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
  final String? routeGpxPath; // 新增：GPX檔案路徑
  final String? routeName;    // 新增：路線名稱

  const RecordPage({
    super.key,
    this.routeGpxPath,
    this.routeName,
  });

  @override
  // 將 _RecordPageState 改為 RecordPageState
  State<RecordPage> createState() => RecordPageState();
}

class RecordPageState extends State<RecordPage> {
  // --- 所有狀態變數 ---
  final MapController _mapController = MapController();
  bool _isMetronomePlaying = false;
  int? _targetBPM = 150;
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
  List<RunRecord> _runHistory = RunHistory.runHistory;
  List<LatLng> _gpxTrackPoints = [];
  bool _isLoadingGpx = false;
  String? _currentRouteName;
  User? currentUser;
  double _currentZoom = 17.0; // 新增：當前縮放級別

  @override
  void initState() {
    _loadCurrentUser();
    _initializeAudioPlayer();
    _checkAndRequestLocationPermission();
    _loadRunHistory();

    // 新增：如果有傳入路線參數才載入GPX
    if (widget.routeGpxPath != null) {_loadGpxTrack(widget.routeGpxPath!);
    }

    _currentRouteName = widget.routeName;

    super.initState();
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

  void _loadCurrentUser() async {
    currentUser = await User.getCurrentUser();
    if (currentUser != null) {
      setState(() {
        _targetBPM = currentUser?.cadence;
      });
    }
    print('使用者名稱: ${currentUser?.name}');
  }

  // 新增：縮放方法
  void _zoomIn() {
    setState(() {
      _currentZoom = (_currentZoom + 1).clamp(1.0, 20.0);
    });
    _mapController.move(_mapController.camera.center, _currentZoom);
  }

  void _zoomOut() {
    setState(() {
      _currentZoom = (_currentZoom - 1).clamp(1.0, 20.0);
    });
    _mapController.move(_mapController.camera.center, _currentZoom);
  }

  // record.dart in RecordPageState

  Future<void> _loadGpxTrack(String gpxPath) async {
    print('[record.dart] 進入 _loadGpxTrack 方法...');
    setState(() {
      _isLoadingGpx = true;
    });

    try {
      final gpxString = await rootBundle.loadString(gpxPath);
      final gpx = GpxReader().fromString(gpxString);
      List<LatLng> points = [];

      for (var track in gpx.trks) {
        for (var segment in track.trksegs) {
          points.addAll(segment.trkpts.map((pt) => LatLng(pt.lat!, pt.lon!)));
        }
      }

      // 3. 加入關鍵的 print 指令，確認解析結果
      print('[record.dart] GPX 檔案解析成功，共找到 ${points.length} 個座標點。');

      if (points.isNotEmpty) {
        print('[record.dart] 第一個座標點是：${points.first}');
      }

      setState(() {
        _gpxTrackPoints = points;
        _isLoadingGpx = false;
      });

      if (points.isNotEmpty) {
        _mapController.move(points.first, _currentZoom);
        // 4. 確認地圖移動指令已發出
        print('[record.dart] 地圖移動指令已發出，移至座標：${points.first}');
      }

    } catch (e) {
      print('[record.dart] 載入或解析GPX檔案時發生嚴重錯誤: $e'); // <--- 檢查這裡是否有輸出
      setState(() {
        _isLoadingGpx = false;
      });
    }
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
        print("檔案不存在，建立初始資料");
        //_createInitialData();
        await _saveHistoryToFile();
        print("初始資料已建立，記錄數量: ${_runHistory.length}");
        return;
      }
      final contents = await file.readAsString();
      if (contents.trim().isEmpty || contents == '[]') {
        print("檔案為空，建立初始資料");
        //_createInitialData();
        await _saveHistoryToFile();
        return;
      }
      final List<dynamic> jsonList = json.decode(contents);
      setState(() {
        RunHistory.runHistory = jsonList.map((jsonItem) => RunRecord.fromJson(jsonItem)).toList();
      });
      print("載入記錄數量: ${RunHistory.runHistory.length}");
    } catch (e) {
      print("讀取記錄時發生錯誤: $e，建立初始資料");
      //_createInitialData();
      await _saveHistoryToFile();
    }
  }

  Future<void> _saveHistoryToFile() async {
    try {
      final file = await _localFile;
      final jsonList = RunHistory.runHistory.map((record) => record.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      print("儲存記錄時發生錯誤: $e");
    }
  }

  

  // 新增：刪除單筆記錄的方法
  Future<void> _deleteRunRecord(int index) async {
    setState(() {
      RunHistory.runHistory.removeAt(index);
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
      RunHistory.runHistory.insert(0, record);
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
      print('位置更新: ${position.latitude}, ${position.longitude}');
      LatLng newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = newLocation;
      });
      _mapController.move(newLocation, _currentZoom); // 修改：使用當前縮放級別
    }, onError: (e) {
      print('位置更新錯誤: $e');
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

  // 新增：供外部呼叫的方法，用於載入新路線

  void loadNewRoute(String gpxPath, String routeName) {
    // 2. 加入 print 指令
    print('[record.dart] RecordPage 收到指令，準備載入路徑：$gpxPath');

    _currentRouteName = routeName;
    _loadGpxTrack(gpxPath);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已載入路線：$routeName'),
        backgroundColor: Colors.green,
      ),
    );
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
      double playbackRate = (_targetBPM! / _baseBPM).clamp(0.5, 2.0);
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
      _targetBPM = (_targetBPM! + delta).clamp(60, 200);
    });
    if (_isMetronomePlaying && _isAudioPlayerInitialized) {
      try {
        double playbackRate = (_targetBPM! / _baseBPM).clamp(0.5, 2.0);
        await _metronomePlayer.setPlaybackRate(playbackRate);
      } catch (e) {
        print('調整播放速度失敗: $e');
      }
    }
  }

  void _navigateToHistoryPage() {
    if (RunHistory.runHistory.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RunHistoryPage(
            records: RunHistory.runHistory,
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

  // record.dart in RecordPageState

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
                  // 修改：將垂直內距從 20.0 縮小為 16.0
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
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
                      // 修改：將垂直間距從 20 縮小為 16
                      const SizedBox(height: 16),
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
              // 修改：將垂直間距從 16 縮小為 12
              const SizedBox(height: 12),
              // 節拍器控制卡
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  // 修改：將內距從 16.0 縮小為 12.0
                  padding: const EdgeInsets.all(12.0),
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
              // 修改：將垂直間距從 16 縮小為 12
              const SizedBox(height: 12),
              // 地圖區域（此區塊會因上方空間縮小而自動變大）
              Expanded(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // 地圖主體
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: mapCenter,
                          initialZoom: _currentZoom,
                          onMapEvent: (MapEvent mapEvent) {
                            if (mapEvent is MapEventMoveEnd) {
                              setState(() {
                                _currentZoom = _mapController.camera.zoom;
                              });
                            }
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                          ),
                          // GPX 路徑顯示
                          if (_gpxTrackPoints.isNotEmpty)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: _gpxTrackPoints,
                                  strokeWidth: 4.0,
                                  color: Colors.blue,
                                ),
                              ],
                            ),
                          // 當前位置標記
                          if (_currentLocation != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  width: 80.0,
                                  height: 80.0,
                                  point: _currentLocation!,
                                  child: Icon(
                                    Icons.person_pin_circle,
                                    color: Theme.of(context).primaryColor,
                                    size: 40.0,
                                  ),
                                ),
                              ],
                            ),
                          // GPX 路徑起點和終點標記
                          if (_gpxTrackPoints.isNotEmpty)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  width: 60.0,
                                  height: 60.0,
                                  point: _gpxTrackPoints.first,
                                  child: const Icon(
                                    Icons.play_circle,
                                    color: Colors.green,
                                    size: 30.0,
                                  ),
                                ),
                                if (_gpxTrackPoints.length > 1)
                                  Marker(
                                    width: 60.0,
                                    height: 60.0,
                                    point: _gpxTrackPoints.last,
                                    child: const Icon(
                                      Icons.flag,
                                      color: Colors.red,
                                      size: 30.0,
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                      // 縮放控制按鈕
                      Positioned(
                        right: 16,
                        top: 16,
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(51),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _zoomIn,
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(color: Colors.grey, width: 0.5),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: Colors.black54,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _zoomOut,
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        child: const Icon(
                                          Icons.remove,
                                          color: Colors.black54,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 修改：將垂直間距從 16 縮小為 12
              const SizedBox(height: 12),
              // 查看歷史記錄按鈕
              Padding(
                // 修改：將水平邊距從 60.0 縮小為 40.0，讓按鈕寬一點
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('查看運動記錄'),
                  onPressed: _navigateToHistoryPage,
                  style: OutlinedButton.styleFrom(
                    // 修改：將垂直內距從 12 縮小為 10
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    foregroundColor: Theme.of(context).primaryColor,
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              // 修改：將垂直間距從 16 縮小為 12
              const SizedBox(height: 12),
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

  // --- UI Helper Widgets ---
  Widget _buildDataColumn(String label, String value, Color color, {double fontSize = 24}) => Column(children: [Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)), const SizedBox(height: 8), Text(value, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: color))]);

  Widget _buildBPMButton(IconData icon, VoidCallback onPressed) => Container(decoration: BoxDecoration(color: Theme.of(context).primaryColor.withAlpha(26), borderRadius: BorderRadius.circular(8)), child: IconButton(icon: Icon(icon), onPressed: onPressed, color: Theme.of(context).primaryColor, iconSize: 20));

  Widget _buildBPMDisplay() => Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: _isAudioPlayerInitialized ? Theme.of(context).primaryColor.withAlpha(26) : Colors.grey.withAlpha(77), borderRadius: BorderRadius.circular(12), border: Border.all(color: _isMetronomePlaying ? Theme.of(context).primaryColor : Colors.grey.withAlpha(128), width: 2)), child: Column(children: [Text('$_targetBPM', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _isAudioPlayerInitialized ? Theme.of(context).primaryColor : Colors.grey)), Text('BPM', style: TextStyle(fontSize: 12, color: _isAudioPlayerInitialized ? Theme.of(context).primaryColor : Colors.grey))]));

  Widget _buildMetronomeButton() => Container(decoration: BoxDecoration(color: _isMetronomePlaying ? Colors.red.withAlpha(26) : Theme.of(context).primaryColor.withAlpha(26), borderRadius: BorderRadius.circular(8)), child: IconButton(icon: Icon(_isMetronomePlaying ? Icons.pause : Icons.play_arrow), onPressed: _isAudioPlayerInitialized ? _toggleMetronome : null, color: _isMetronomePlaying ? Colors.red : Theme.of(context).primaryColor, iconSize: 28));

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
