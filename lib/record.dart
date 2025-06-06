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
  int _targetBPM = 100; // 預設 100 BPM
  final int _baseBPM = 120; // 基礎音訊的 BPM（需要與你的音訊文件匹配）

  late AudioPlayer _metronomePlayer;
  bool _isAudioPlayerInitialized = false;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _elapsedTime = '00:00:00:00';
  bool _isRunning = false;

  double _currentDistance = 0.0;
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

  // 初始化音頻播放器
  Future<void> _initializeAudioPlayer() async {
    _metronomePlayer = AudioPlayer();
    try {
      // 移除循環播放設定，因為使用30分鐘的完整音檔
      // await _metronomePlayer.setReleaseMode(ReleaseMode.loop);
      // 預設音量
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
      distanceFilter: 5,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _mapController.move(_currentLocation!, 17.0);
      });
    });
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _stopwatch.start();
    // 使用 10ms 間隔來顯示百分秒
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
      _elapsedTime = '00:00:00:00';
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
    int centiseconds = (totalMilliseconds % 1000) ~/ 10; // 百分秒 (00-99)
    int seconds = (totalMilliseconds / 1000).floor();
    int minutes = (seconds / 60).floor();
    int hours = (minutes / 60).floor();

    seconds = seconds % 60;
    minutes = minutes % 60;

    return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}:${twoDigits(centiseconds)}';
  }

  void _updateDistanceAndPace() {
    final double distancePerSecond = _averageSlowRunSpeedKph / 3600.0;
    _currentDistance = _stopwatch.elapsed.inMilliseconds / 1000.0 * distancePerSecond;

    if (_currentDistance > 0) {
      final int totalElapsedMilliseconds = _stopwatch.elapsed.inMilliseconds;
      final int totalMillisecondsPerKm = (totalElapsedMilliseconds / _currentDistance).round();
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
      // 計算播放速度比例
      double playbackRate = _targetBPM / _baseBPM;

      // 設置播放速度 (audioplayers 支援 0.5 到 2.0 的速度)
      playbackRate = playbackRate.clamp(0.5, 2.0);
      await _metronomePlayer.setPlaybackRate(playbackRate);

      // 開始播放音訊（不循環，因為是30分鐘完整音檔）
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

    // 如果節拍器正在播放，立即調整播放速度
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
          Card(
            elevation: 4.0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(children: [
                        const Text('時間', style: TextStyle(fontSize: 18)),
                        Text(_elapsedTime, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor))
                      ]),
                      Column(children: [
                        const Text('距離 (km)', style: TextStyle(fontSize: 18)),
                        Text(_currentDistance.toStringAsFixed(1), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor))
                      ]),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(children: [
                        const Text('配速 (分/km)', style: TextStyle(fontSize: 18)),
                        Text(_currentPace, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor))
                      ]),
                      Column(children: [
                        const Text('心率 (BPM)', style: TextStyle(fontSize: 18)),
                        Text(_currentHeartRate.toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.redAccent))
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4.0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('步頻節奏', style: TextStyle(fontSize: 18)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () => _adjustBPM(-5),
                        color: Theme.of(context).primaryColor,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isAudioPlayerInitialized
                              ? Theme.of(context).primaryColor.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
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
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _isAudioPlayerInitialized
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey
                                )
                            ),
                            Text(
                                'BPM',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: _isAudioPlayerInitialized
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey
                                )
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _adjustBPM(5),
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(_isMetronomePlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: _isAudioPlayerInitialized ? _toggleMetronome : null,
                    color: _isMetronomePlaying ? Colors.red : Theme.of(context).primaryColor,
                    iconSize: 30,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              elevation: 4.0,
              clipBehavior: Clip.antiAlias,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: mapCenter,
                  initialZoom: _currentLocation != null ? 17.0 : 13.0,
                  minZoom: 5.0,
                  maxZoom: 18.0,
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
                          child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () => _isRunning ? _pauseTimer() : _startTimer(),
                child: Icon(_isRunning ? Icons.pause : Icons.play_arrow, size: 30),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(15),
                  shape: const CircleBorder(),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton(
                onPressed: _resetTimer,
                child: const Icon(Icons.stop, size: 30),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(15),
                  shape: const CircleBorder(),
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}