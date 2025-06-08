import 'record.dart';
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

class RunHistory{
  final now = DateTime.now();
  static List<RunRecord> runHistory = [
    RunRecord(
      date: DateTime.now().subtract(const Duration(days: 1)),
      duration: '25:30',
      distance: 3200.0,
      pace: '07:58',
      avgHeartRate: 145,
      maxHeartRate: 162,
    ),
    RunRecord(
      date: DateTime.now().subtract(const Duration(days: 3)),
      duration: '18:45',
      distance: 2400.0,
      pace: '07:48',
      avgHeartRate: 138,
      maxHeartRate: 155,
    ),
    RunRecord(
      date: DateTime.now().subtract(const Duration(days: 5)),
      duration: '32:15',
      distance: 4100.0,
      pace: '07:52',
      avgHeartRate: 142,
      maxHeartRate: 158,
    ),
    RunRecord(
      date: DateTime.now().subtract(const Duration(days: 7)),
      duration: '15:20',
      distance: 2000.0,
      pace: '07:40',
      avgHeartRate: 140,
      maxHeartRate: 152,
    ),
    RunRecord(
      date: DateTime.now().subtract(const Duration(days: 10)),
      duration: '40:30',
      distance: 5200.0,
      pace: '07:47',
      avgHeartRate: 148,
      maxHeartRate: 165,
    ),
  ];



}