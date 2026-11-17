import 'dart:isolate';
import 'dart:math' as math;

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../main.dart' show batteryChannel;

const String userDatabaseName = 'battery_history.db';
const String sampleDatabaseName = 'battery_sample.db';

const String _table = 'measurements';
const String _createTable =
    'CREATE TABLE IF NOT EXISTS measurements ('
    'id INTEGER PRIMARY KEY AUTOINCREMENT, '
    'measured_at INTEGER NOT NULL, '
    'temperature REAL NOT NULL)';

const Duration statsWindow = Duration(hours: 24);

enum HistorySource { user, sample }

class Measurement {
  const Measurement({required this.measuredAt, required this.temperature});

  final DateTime measuredAt;
  final double temperature;
}

class ChartPoint {
  const ChartPoint(this.minute, this.temperature);

  final double minute;
  final double temperature;
}

class TemperatureStats {
  const TemperatureStats({
    required this.from,
    required this.to,
    required this.min,
    required this.max,
    required this.axisMin,
    required this.axisStep,
    required this.points,
    required this.newestFirst,
  });

  final DateTime from;
  final DateTime to;
  final double? min;
  final double? max;
  final double axisMin;
  final double axisStep;
  final List<ChartPoint> points;
  final List<Measurement> newestFirst;

  double get axisMax => axisMin + 2 * axisStep;
  int get count => newestFirst.length;
  bool get isEmpty => newestFirst.isEmpty;

  factory TemperatureStats.empty(DateTime now) => TemperatureStats(
    from: now.subtract(statsWindow),
    to: now,
    min: null,
    max: null,
    axisMin: 0,
    axisStep: 1,
    points: const [],
    newestFirst: const [],
  );
}

Future<Database> _open(String name) async {
  final path = p.join(await getDatabasesPath(), name);
  return openDatabase(path, onOpen: (db) => db.execute(_createTable));
}

String _databaseName(HistorySource source) =>
    source == HistorySource.sample ? sampleDatabaseName : userDatabaseName;

Future<List<Measurement>> readMeasurements(
  HistorySource source, {
  required DateTime since,
}) async {
  final db = await _open(_databaseName(source));
  try {
    final rows = await db.query(
      _table,
      columns: ['measured_at', 'temperature'],
      where: 'measured_at >= ?',
      whereArgs: [since.millisecondsSinceEpoch],
      orderBy: 'measured_at ASC',
    );
    return [
      for (final row in rows)
        Measurement(
          measuredAt: DateTime.fromMillisecondsSinceEpoch(
            row['measured_at']! as int,
          ),
          temperature: (row['temperature']! as num).toDouble(),
        ),
    ];
  } finally {
    await db.close();
  }
}

List<Measurement> generateSampleMeasurements(DateTime now) {
  final random = math.Random(42);
  final start = now.subtract(statsWindow);
  return [
    for (var i = 1; i <= 96; i++)
      () {
        final time = start.add(Duration(minutes: 15 * i));
        final hour = time.hour + time.minute / 60;
        final wave = math.sin(2 * math.pi * (hour - 10) / 24);
        final noise = random.nextDouble() * 0.5 - 0.25;
        final temperature = ((32 + 4.5 * wave + noise) * 10).round() / 10;
        return Measurement(measuredAt: time, temperature: temperature);
      }(),
  ];
}

Future<void> writeSampleMeasurements(DateTime now) async {
  final db = await _open(sampleDatabaseName);
  try {
    final batch = db.batch()..delete(_table);
    for (final m in generateSampleMeasurements(now)) {
      batch.insert(_table, {
        'measured_at': m.measuredAt.millisecondsSinceEpoch,
        'temperature': m.temperature,
      });
    }
    await batch.commit(noResult: true);
  } finally {
    await db.close();
  }
}

TemperatureStats computeTemperatureStats(
  List<Measurement> measurements,
  DateTime now,
) {
  final from = now.subtract(statsWindow);
  final inWindow =
      measurements
          .where(
            (m) => !m.measuredAt.isBefore(from) && !m.measuredAt.isAfter(now),
          )
          .toList()
        ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
  if (inWindow.isEmpty) return TemperatureStats.empty(now);

  var min = inWindow.first.temperature;
  var max = min;
  for (final m in inWindow) {
    min = math.min(min, m.temperature);
    max = math.max(max, m.temperature);
  }

  final axisMin = min.floorToDouble();
  final axisStep = math
      .max(1, ((max.ceil() - axisMin + 2) / 2).ceil())
      .toDouble();

  return TemperatureStats(
    from: from,
    to: now,
    min: min,
    max: max,
    axisMin: axisMin,
    axisStep: axisStep,
    points: [
      for (final m in inWindow)
        ChartPoint(m.measuredAt.difference(from).inSeconds / 60, m.temperature),
    ],
    newestFirst: inWindow.reversed.toList(),
  );
}

Future<TemperatureStats> loadTemperatureStats(
  HistorySource source, {
  DateTime? now,
}) async {
  final current = now ?? DateTime.now();
  final List<Measurement> measurements;
  try {
    measurements = await readMeasurements(
      source,
      since: current.subtract(statsWindow),
    );
  } catch (e) {
    return TemperatureStats.empty(current);
  }

  // BACKGROUND ISOLATE
  // Isolate.run tạo một isolate mới (một "luồng" Dart có bộ nhớ riêng), chép
  // danh sách measurements sang đó, chạy computeTemperatureStats ở bên đó rồi
  // gửi kết quả về và tự đóng isolate.
  // Trong lúc chờ, isolate chính vẫn rảnh để vẽ giao diện, nên màn hình không
  // bị khựng dù danh sách lần đo có dài.
  // Hàm truyền vào chỉ được dùng dữ liệu gửi qua được giữa các isolate (số,
  // chuỗi, DateTime, List, object tự định nghĩa...), không được đụng tới
  // widget hay context.
  return Isolate.run(() => computeTemperatureStats(measurements, current));
}

Future<bool> isPeriodicMeasurementEnabled() async {
  try {
    return await batteryChannel.invokeMethod<bool>('isPeriodicEnabled') ??
        false;
  } catch (e) {
    return false;
  }
}

Future<bool> setPeriodicMeasurement(bool enabled) async {
  try {
    await batteryChannel.invokeMethod<bool>(
      enabled ? 'startPeriodic' : 'stopPeriodic',
    );
    return enabled;
  } catch (e) {
    return !enabled;
  }
}
