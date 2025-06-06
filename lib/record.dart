import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart'; // Import geolocator

// 索引 2: 運動追蹤 - 跑步進行中的實時數據和引導 (功能 1, 2, 3, 7, 9, 10)
class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  // Map Controller for programmatically moving the map
  final MapController _mapController = MapController();

  // State variables for Pace Guidance
  bool _isMetronomePlaying = false;
  int _targetBPM = 100;
  late AudioPlayer _audioPlayer;
  Timer? _metronomeTimer;
  final String _metronomeSoundPath = 'audios/tick.mp3';

  // 計時器相關的 State variables
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _elapsedTime = '00:00:00';
  bool _isRunning = false;

  // 距離和配速相關的 State variables
  double _currentDistance = 0.0;
  String _currentPace = '00:00';
  final double _averageSlowRunSpeedKph = 6.0;

  // 心率模擬相關的 State variables
  int _currentHeartRate = 75;
  final int _restingHeartRate = 75;
  final int _runningHeartRateMin = 130;
  final int _runningHeartRateMax = 170;
  final Random _random = Random();

  // Location variables
  LatLng? _currentLocation; // User's current geographical location
  StreamSubscription<Position>? _positionStreamSubscription; // Stream to listen for location updates

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _checkAndRequestLocationPermission(); // Check and request permission on init
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    _metronomeTimer?.cancel();
    _audioPlayer.dispose();
    _positionStreamSubscription?.cancel(); // Cancel location stream
    super.dispose();
  }

  // --- Location Handling Functions ---
  Future<void> _checkAndRequestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, don't continue
      // accessing the position and request users to enable the location services.
      print('Location services are disabled.');
      // Optionally show a dialog to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請啟用位置服務以追蹤您的位置。')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could show a dialog
        // with a explanation to the user.
        print('Location permissions are denied');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('位置權限已被拒絕。')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      print('Location permissions are permanently denied, we cannot request permissions.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('位置權限已被永久拒絕，請在設定中開啟。')),
      );
      return;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high, // Use high accuracy for better tracking
      distanceFilter: 5, // Update every 5 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        // Automatically move the map camera to the new location
        _mapController.move(_currentLocation!, 17.0); // Zoom in closer
      });
      print('Location updated: ${position.latitude}, ${position.longitude}');
    });
  }

  // --- Timer & Data Update Functions ---
  void _startTimer() {
    setState(() {
      _isRunning = true;
    });
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = _formatDuration(_stopwatch.elapsed);
        _updateDistanceAndPace();
        _updateHeartRate();
      });
    });
    print('計時器開始');
  }

  void _pauseTimer() {
    setState(() {
      _isRunning = false;
    });
    _stopwatch.stop();
    _timer?.cancel();
    print('計時器暫停');
  }

  void _resetTimer() {
    if (_isMetronomePlaying) {
      _toggleMetronome();
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
    print('計時器重置');
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  void _updateDistanceAndPace() {
    final double distancePerSecond = _averageSlowRunSpeedKph / 3600.0;
    _currentDistance = _stopwatch.elapsed.inSeconds * distancePerSecond;

    if (_currentDistance > 0) {
      final int totalElapsedSeconds = _stopwatch.elapsed.inSeconds;
      final int totalSecondsPerKm = (totalElapsedSeconds / _currentDistance).round();

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
        if (_currentHeartRate < _runningHeartRateMin) {
          _currentHeartRate += _random.nextInt(3) + 1;
        } else {
          _currentHeartRate += _random.nextInt(5) - 2;
        }
        _currentHeartRate = _currentHeartRate.clamp(_runningHeartRateMin - 5, _runningHeartRateMax + 5);
      } else {
        if (_currentHeartRate > _restingHeartRate) {
          _currentHeartRate -= _random.nextInt(3) + 1;
        } else {
          _currentHeartRate += _random.nextInt(3) - 1;
        }
        _currentHeartRate = _currentHeartRate.clamp(_restingHeartRate - 5, _restingHeartRate + 10);
      }
      _currentHeartRate = _currentHeartRate.clamp(50, 200);
    });
  }

  // --- Metronome Functions ---
  void _toggleMetronome() {
    setState(() {
      _isMetronomePlaying = !_isMetronomePlaying;
    });

    if (_isMetronomePlaying) {
      _startMetronome();
      print('節拍器開始播放, BPM: $_targetBPM');
    } else {
      _stopMetronome();
      print('節拍器暫停');
    }
  }

  void _startMetronome() {
    _metronomeTimer?.cancel();
    final double intervalSeconds = 60.0 / _targetBPM;
    final Duration interval = Duration(milliseconds: (intervalSeconds * 1000).round());

    _metronomeTimer = Timer.periodic(interval, (timer) async {
      await _audioPlayer.play(AssetSource(_metronomeSoundPath));
    });
  }

  void _stopMetronome() {
    _metronomeTimer?.cancel();
  }

  void _adjustBPM(int delta) {
    setState(() {
      _targetBPM = (_targetBPM + delta).clamp(100, 200);
    });
    if (_isMetronomePlaying) {
      _startMetronome();
    }
    print('調整 BPM 至: $_targetBPM');
  }

  @override
  Widget build(BuildContext context) {
    // Determine map center based on current location or default
    final LatLng mapCenter = _currentLocation ?? LatLng(23.4792, 120.4497); // Default to Chiayi if no location yet

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ... (Existing UI for stats and metronome) ...
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
                        Text(
                          _elapsedTime,
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                        )
                      ]),
                      Column(children: [
                        const Text('距離 (km)', style: TextStyle(fontSize: 18)),
                        Text(
                          _currentDistance.toStringAsFixed(2),
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                        )
                      ]),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(children: [
                        const Text('配速 (分/km)', style: TextStyle(fontSize: 18)),
                        Text(
                          _currentPace,
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                        )
                      ]),
                      Column(children: [
                        const Text('心率 (BPM)', style: TextStyle(fontSize: 18)),
                        Text(
                          _currentHeartRate.toString(),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.redAccent),
                        )
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
                      Text('$_targetBPM BPM', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _adjustBPM(5),
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(_isMetronomePlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: _toggleMetronome,
                    color: _isMetronomePlaying ? Colors.red : Theme.of(context).primaryColor,
                    iconSize: 30,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 地圖顯示區塊 (使用 flutter_map)
          Expanded(
            child: Card(
              elevation: 4.0,
              clipBehavior: Clip.antiAlias,
              child: FlutterMap(
                mapController: _mapController, // Assign the MapController
                options: MapOptions(
                  initialCenter: mapCenter, // Use current location or default
                  initialZoom: _currentLocation != null ? 17.0 : 13.0, // Zoom in more if location is available
                  minZoom: 5.0,
                  maxZoom: 18.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.run_tracker_app',
                  ),
                  // Display user location marker only if location is available
                  if (_currentLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentLocation!, // Use non-null asserted location
                          width: 80,
                          height: 80,
                          child: const Icon(
                            Icons.person_pin_circle, // Use a person icon for user
                            color: Colors.blue, // Blue marker for user
                            size: 40,
                          ),
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
                onPressed: () {
                  if (_isRunning) {
                    _pauseTimer();
                  } else {
                    _startTimer();
                  }
                },
                child: Icon(
                  _isRunning ? Icons.pause : Icons.play_arrow,
                  size: 30,
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(15),
                  shape: const CircleBorder(),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _resetTimer();
                  print('停止');
                },
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