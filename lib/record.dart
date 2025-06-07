import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
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

  double _currentDistance = 0.0; // 以公尺為單位
  String _currentPace = '00:00';
  final double _averageSlowRunSpeedKph = 6.0;

  int _currentHeartRate = 75;
  final int _restingHeartRate = 75;
  final int _runningHeartRateMin = 130;
  final int _runningHeartRateMax = 170;
  final Random _random = Random();

  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
    _checkAndRequestLocationPermission();
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

  Future<void> _initializeAudioPlayer() async {
    _metronomePlayer = AudioPlayer();
    try {
      await _metronomePlayer.setVolume(0.8);
      setState(() {
        _isAudioPlayerInitialized = true;
      });
      print('節拍器音頻播放器初始化成功');
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
      distanceFilter: 1, // 更精確的位置追蹤
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      LatLng newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = newLocation;
      });

      // 自動移動地圖中心到當前位置，使用更高的縮放級別
      _mapController.move(newLocation, 19.0);
    });
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _stopwatch.start();
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

    setState(() {
      _isRunning = false;
      _stopwatch.reset();
      _elapsedTime = '00:00:00';
      _currentDistance = 0.0;
      _currentPace = '00:00';
      _currentHeartRate = _restingHeartRate;
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
    // 計算距離（公尺）
    final double distancePerSecond = (_averageSlowRunSpeedKph * 1000) / 3600.0; // 公尺/秒
    _currentDistance = _stopwatch.elapsed.inMilliseconds / 1000.0 * distancePerSecond;

    // 計算配速（每公里的時間）
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
    if (!_isAudioPlayerInitialized) {
      print('音頻播放器尚未初始化');
      return;
    }

    try {
      double playbackRate = _targetBPM / _baseBPM;
      playbackRate = playbackRate.clamp(0.5, 2.0);
      await _metronomePlayer.setPlaybackRate(playbackRate);
      await _metronomePlayer.play(AssetSource('audios/tick1.mp3'));
      print('節拍器開始播放，BPM: $_targetBPM, 播放速度: $playbackRate');
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
        double playbackRate = _targetBPM / _baseBPM;
        playbackRate = playbackRate.clamp(0.5, 2.0);
        await _metronomePlayer.setPlaybackRate(playbackRate);
        print('調整播放速度: $playbackRate (BPM: $_targetBPM)');
      } catch (e) {
        print('調整播放速度失敗: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng mapCenter = _currentLocation ?? LatLng(23.4792, 120.4497);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 運動數據顯示卡片
          Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // 第一行：時間和距離
                  Row(
                    children: [
                      Expanded(
                        child: _buildDataColumn(
                          '時間',
                          _elapsedTime,
                          Theme.of(context).primaryColor,
                          fontSize: 24,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: Colors.grey.withOpacity(0.3),
                      ),
                      Expanded(
                        child: _buildDataColumn(
                          '距離 (公尺)',
                          _currentDistance.toStringAsFixed(0),
                          Theme.of(context).primaryColor,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 分隔線
                  Divider(color: Colors.grey.withOpacity(0.3)),
                  const SizedBox(height: 20),
                  // 第二行：配速和心率
                  Row(
                    children: [
                      Expanded(
                        child: _buildDataColumn(
                          '配速 (分/km)',
                          _currentPace,
                          Colors.amber[700]!,
                          fontSize: 24,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: Colors.grey.withOpacity(0.3),
                      ),
                      Expanded(
                        child: _buildDataColumn(
                          '心率 (BPM)',
                          _currentHeartRate.toString(),
                          Colors.redAccent,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 節拍器控制卡片
          Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '步頻節奏',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      _buildBPMButton(Icons.remove, () => _adjustBPM(-5)),
                      const SizedBox(width: 12),
                      _buildBPMDisplay(),
                      const SizedBox(width: 12),
                      _buildBPMButton(Icons.add, () => _adjustBPM(5)),
                      const SizedBox(width: 16),
                      _buildMetronomeButton(),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 地圖卡片
          Expanded(
            child: Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: mapCenter,
                      initialZoom: _currentLocation != null ? 19.0 : 13.0,
                      minZoom: 10.0,
                      maxZoom: 22.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.run_tracker_app',
                      ),
                      if (_currentLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _currentLocation!,
                              width: 80,
                              height: 80,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // 外圈脈衝效果
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  // 中圈
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  // 內圈 - 精確位置
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  // 居中按鈕
                  if (_currentLocation != null)
                    Positioned(
                      right: 16,
                      bottom: 60,
                      child: Column(
                        children: [
                          FloatingActionButton.small(
                            heroTag: "center_map",
                            onPressed: () {
                              _mapController.move(_currentLocation!, 19.0);
                            },
                            backgroundColor: Colors.white,
                            foregroundColor: Theme.of(context).primaryColor,
                            child: const Icon(Icons.my_location),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.small(
                            heroTag: "zoom_in",
                            onPressed: () {
                              final currentZoom = _mapController.camera.zoom;
                              _mapController.move(_currentLocation!, (currentZoom + 1).clamp(10.0, 22.0));
                            },
                            backgroundColor: Colors.white,
                            foregroundColor: Theme.of(context).primaryColor,
                            child: const Icon(Icons.zoom_in),
                          ),
                        ],
                      ),
                    ),
                  // 地圖信息顯示
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _currentLocation != null
                            ? 'GPS已連接'
                            : '尋找GPS信號...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 控制按鈕
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: _isRunning ? Icons.pause : Icons.play_arrow,
                onPressed: () => _isRunning ? _pauseTimer() : _startTimer(),
                backgroundColor: _isRunning ? Colors.orange : Colors.green,
                size: 32,
              ),
              _buildControlButton(
                icon: Icons.stop,
                onPressed: _resetTimer,
                backgroundColor: Colors.redAccent,
                size: 32,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataColumn(String label, String value, Color color, {double fontSize = 24}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBPMButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: Theme.of(context).primaryColor,
        iconSize: 20,
      ),
    );
  }

  Widget _buildBPMDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isAudioPlayerInitialized
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isMetronomePlaying
              ? Theme.of(context).primaryColor
              : Colors.grey.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            '$_targetBPM',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _isAudioPlayerInitialized
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
          ),
          Text(
            'BPM',
            style: TextStyle(
              fontSize: 12,
              color: _isAudioPlayerInitialized
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetronomeButton() {
    return Container(
      decoration: BoxDecoration(
        color: _isMetronomePlaying ? Colors.red.withOpacity(0.1) : Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(_isMetronomePlaying ? Icons.pause : Icons.play_arrow),
        onPressed: _isAudioPlayerInitialized ? _toggleMetronome : null,
        color: _isMetronomePlaying ? Colors.red : Theme.of(context).primaryColor,
        iconSize: 28,
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    double size = 30,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(20),
          shape: const CircleBorder(),
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        child: Icon(icon, size: size),
      ),
    );
  }
}