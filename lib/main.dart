import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'theme/battery_palette.dart';
import 'widgets/battery_icon.dart';
import 'widgets/mode_button.dart';

void main() {
  runApp(const BatteryApp());
}

// Kênh nối Flutter với code Android. Tên kênh phải giống hệt tên trong
// MainActivity.kt thì hai bên mới tìm thấy nhau.
const batteryChannel = MethodChannel('cosXbatteryChannel');

// Gửi yêu cầu 'getPercent' sang Android và chờ nhận về phần trăm pin.
// Nếu Android báo lỗi thì trả về null, màn hình sẽ hiện "Chưa đo".
Future<int?> getBatteryPercent() async {
  try {
    final int? percent = await batteryChannel.invokeMethod<int>('getPercent');
    return percent;
  } catch (e) {
    return null;
  }
}

// Gửi yêu cầu 'getTemperature' sang Android và chờ nhận về nhiệt độ pin (°C).
Future<double?> getBatteryTemperature() async {
  try {
    final double? temperature = await batteryChannel.invokeMethod<double>(
      'getTemperature',
    );
    return temperature;
  } catch (e) {
    return null;
  }
}

const int lowBatteryPercent = 20;

const double highBatteryTemperature = 45;

enum BatteryInfoMode { level, temperature }

// Từ dữ liệu vừa nhận, quyết định màn hình dùng bộ màu nào.
BatteryStatus batteryStatusFor({
  required BatteryInfoMode? mode,
  required int? percent,
  required double? temperature,
}) {
  switch (mode) {
    case null:
      return BatteryStatus.idle;
    case BatteryInfoMode.level:
      if (percent == null) return BatteryStatus.idle;
      return percent <= lowBatteryPercent
          ? BatteryStatus.bad
          : BatteryStatus.normal;
    case BatteryInfoMode.temperature:
      if (temperature == null) return BatteryStatus.idle;
      return temperature >= highBatteryTemperature
          ? BatteryStatus.overheat
          : BatteryStatus.normal;
  }
}

String _formatTemperature(double celsius) => '${celsius.round()}°C';

class BatteryApp extends StatelessWidget {
  const BatteryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trạng thái pin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
      home: const BatteryScreen(),
    );
  }
}

class BatteryScreen extends StatefulWidget {
  const BatteryScreen({super.key});

  @override
  State<BatteryScreen> createState() => _BatteryScreenState();
}

class _BatteryScreenState extends State<BatteryScreen> {
  BatteryInfoMode? _mode;
  int? _percent;
  double? _temperature;

  // Bấm nút % -> hỏi Android -> lưu kết quả -> setState để vẽ lại màn hình.
  Future<void> _onPercentPressed() async {
    final percent = await getBatteryPercent();
    if (!mounted) return;
    setState(() {
      _mode = BatteryInfoMode.level;
      _percent = percent;
    });
  }

  Future<void> _onTemperaturePressed() async {
    final temperature = await getBatteryTemperature();
    if (!mounted) return;
    setState(() {
      _mode = BatteryInfoMode.temperature;
      _temperature = temperature;
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = batteryStatusFor(
      mode: _mode,
      percent: _percent,
      temperature: _temperature,
    );
    final palette = BatteryPalette.of(status);
    final isHot =
        _temperature != null && _temperature! >= highBatteryTemperature;
    final isLow = _percent != null && _percent! <= lowBatteryPercent;

    final String modeLabel;
    final String mainValue;
    final String caption;
    switch (status) {
      case BatteryStatus.idle:
        modeLabel = 'SẴN SÀNG ĐO';
        mainValue = 'Chưa đo';
        caption = 'Chọn một thông tin bên dưới để bắt đầu';
      case BatteryStatus.normal:
        if (_mode == BatteryInfoMode.temperature) {
          modeLabel = 'NHIỆT ĐỘ PIN';
          mainValue = _formatTemperature(_temperature!);
          caption = 'Nhiệt độ pin bình thường';
        } else {
          modeLabel = 'MỨC PIN';
          mainValue = '$_percent%';
          caption = 'Pin đủ cho ngày dài';
        }
      case BatteryStatus.bad:
        modeLabel = 'CẢNH BÁO TÌNH TRẠNG PIN';
        mainValue = '$_percent%';
        caption = 'Pin yếu, nên sạc sớm';
      case BatteryStatus.overheat:
        modeLabel = 'CẢNH BÁO NHIỆT ĐỘ CAO';
        mainValue = _formatTemperature(_temperature!);
        caption = 'Pin quá nóng, hãy để thiết bị nguội';
    }

    final String? healthText = isHot
        ? 'Quá nóng'
        : _percent == null
        ? null
        : (isLow ? 'Yếu' : 'Tốt');
    final String? temperatureText = _temperature == null
        ? null
        : _formatTemperature(_temperature!);

    final double? fillLevel = status == BatteryStatus.idle
        ? null
        : (_percent != null ? _percent! / 100 : 1);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: palette.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TitleBar(palette: palette),
                _BatterySummary(
                  status: status,
                  palette: palette,
                  fillLevel: fillLevel,
                  modeLabel: modeLabel,
                  mainValue: mainValue,
                  mainValueIsNumeric: status != BatteryStatus.idle,
                  caption: caption,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(21, 4, 21, 21),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ModeButton(
                        icon: Symbols.percent,
                        label: 'Trạng thái pin',
                        selected: _mode == BatteryInfoMode.level,
                        palette: palette,
                        onPressed: _onPercentPressed,
                      ),
                      ModeButton(
                        icon: Symbols.device_thermostat,
                        label: 'Nhiệt độ pin',
                        selected: _mode == BatteryInfoMode.temperature,
                        palette: palette,
                        onPressed: _onTemperaturePressed,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _DetailCard(
                  palette: palette,
                  healthText: healthText,
                  temperatureText: temperatureText,
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const double _lineHeight = 1.21;

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.palette});

  final BatteryPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.only(top: 20),
      alignment: Alignment.topLeft,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.divider)),
      ),
      child: Text(
        'Trạng thái pin hiện tại',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 21,
          height: _lineHeight,
          fontWeight: FontWeight.w600,
          color: palette.primaryText,
        ),
      ),
    );
  }
}

class _BatterySummary extends StatelessWidget {
  const _BatterySummary({
    required this.status,
    required this.palette,
    required this.fillLevel,
    required this.modeLabel,
    required this.mainValue,
    required this.mainValueIsNumeric,
    required this.caption,
  });

  final BatteryStatus status;
  final BatteryPalette palette;
  final double? fillLevel;
  final String modeLabel;
  final String mainValue;

  final bool mainValueIsNumeric;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
      child: Column(
        children: [
          Text(
            modeLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: _lineHeight,
              fontWeight: FontWeight.w600,
              color: palette.modeLabel,
            ),
          ),
          const SizedBox(height: 21),
          Container(
            width: 260,
            height: 260,
            padding: const EdgeInsets.only(top: 10),
            alignment: Alignment.topCenter,
            decoration: BoxDecoration(
              color: palette.illustrationCircle,
              shape: BoxShape.circle,
            ),
            child: BatteryIcon(
              status: status,
              level: fillLevel,
              palette: palette,
            ),
          ),
          SizedBox(
            height: 75,
            child: Align(
              alignment: const Alignment(0, 0.3),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  mainValue,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: mainValueIsNumeric ? 56 : 40,
                    height: _lineHeight,
                    fontWeight: FontWeight.w600,
                    color: palette.mainValue,
                  ),
                ),
              ),
            ),
          ),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: _lineHeight,
              color: palette.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.palette,
    required this.healthText,
    required this.temperatureText,
  });

  final BatteryPalette palette;
  final String? healthText;
  final String? temperatureText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DetailItem(
              label: 'Tình trạng pin',
              value: healthText,
              palette: palette,
            ),
          ),
          Container(width: 1, height: 44, color: palette.cardDivider),
          Expanded(
            child: _DetailItem(
              label: 'Nhiệt độ pin',
              value: temperatureText,
              palette: palette,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.label,
    required this.value,
    required this.palette,
  });

  final String label;

  final String? value;
  final BatteryPalette palette;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 6, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              height: _lineHeight,
              color: palette.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value ?? 'Chưa tiến hành đo',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: hasValue ? 16 : 14,
              height: _lineHeight,
              fontWeight: FontWeight.w600,
              color: hasValue ? palette.primaryText : palette.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
