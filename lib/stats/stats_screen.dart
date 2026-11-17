import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'battery_history.dart';

const _background = Color(0xFFF6F9F5);
const _card = Color(0xFFFFFFFF);
const _primaryText = Color(0xFF213F30);
const _secondaryText = Color(0xFF6A796D);
const _accentText = Color(0xFF496044);
const _divider = Color(0xFFE1E9DF);
const _rowDivider = Color(0xFFEDF1E9);
const _line = Color(0xFF284C36);
const _area = Color(0xFFB6E880);
const _switchOn = Color(0xFF284C36);
const _switchOnThumb = Color(0xFFD0F4A5);
const _switchOff = Color(0xFFDCE5D8);
const _chipBackground = Color(0xFFE7EEDF);

const double _lineHeight = 1.21;

const String sampleDataNotice =
    'Đây là dữ liệu ví dụ, không phải dữ liệu thật của bạn';

String _two(int n) => n.toString().padLeft(2, '0');
String _time(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';
String _dateTime(DateTime t) => '${_time(t)}, ${_two(t.day)}/${_two(t.month)}';
String _celsius(double? value) => value == null ? '—°C' : '${value.round()}°C';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, this.clock});

  final DateTime Function()? clock;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  HistorySource _source = HistorySource.user;
  TemperatureStats? _stats;
  bool _periodicEnabled = false;
  late final AppLifecycleListener _lifecycle;

  DateTime _now() => widget.clock?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _reload);
    _loadPeriodicState();
    _reload();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _loadPeriodicState() async {
    final enabled = await isPeriodicMeasurementEnabled();
    if (!mounted) return;
    setState(() => _periodicEnabled = enabled);
  }

  Future<void> _reload() async {
    final stats = await loadTemperatureStats(_source, now: _now());
    if (!mounted) return;
    setState(() => _stats = stats);
  }

  Future<void> _onPeriodicChanged(bool enabled) async {
    setState(() => _periodicEnabled = enabled);
    final result = await setPeriodicMeasurement(enabled);
    if (!mounted) return;
    setState(() => _periodicEnabled = result);
    if (result && _source == HistorySource.user) await _reload();
  }

  Future<void> _onSamplePressed() async {
    if (_source == HistorySource.user) {
      try {
        await writeSampleMeasurements(_now());
      } catch (e) {
        return;
      }
      _source = HistorySource.sample;
    } else {
      _source = HistorySource.user;
    }
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats ?? TemperatureStats.empty(_now());
    final isSample = _source == HistorySource.sample;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TitleBar(
                  isSample: isSample,
                  onSamplePressed: _onSamplePressed,
                ),
                const SizedBox(height: 16),
                _PeriodicCard(
                  enabled: _periodicEnabled,
                  onChanged: _onPeriodicChanged,
                ),
                if (isSample) ...[
                  const SizedBox(height: 12),
                  const _SampleNotice(),
                ],
                const SizedBox(height: 16),
                _ChartCard(stats: stats, isSample: isSample),
                const SizedBox(height: 20),
                _HistoryHeader(count: stats.count),
                const SizedBox(height: 14),
                _HistoryCard(stats: stats),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.isSample, required this.onSamplePressed});

  final bool isSample;
  final VoidCallback onSamplePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Thống kê nhiệt độ',
                maxLines: 1,
                style: TextStyle(
                  fontSize: 21,
                  height: _lineHeight,
                  fontWeight: FontWeight.w600,
                  color: _primaryText,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onSamplePressed,
            style: TextButton.styleFrom(
              backgroundColor: _chipBackground,
              foregroundColor: _accentText,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isSample ? 'Dữ liệu của tôi' : 'Dữ liệu mẫu',
              style: const TextStyle(
                fontSize: 12,
                height: _lineHeight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodicCard extends StatelessWidget {
  const _PeriodicCard({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đo định kì mỗi 15p',
                  style: TextStyle(
                    fontSize: 14,
                    height: _lineHeight,
                    fontWeight: FontWeight.w600,
                    color: _primaryText,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Tự động ghi lại nhiệt độ pin',
                  style: TextStyle(
                    fontSize: 12,
                    height: _lineHeight,
                    color: _secondaryText,
                  ),
                ),
              ],
            ),
          ),
          _PeriodicSwitch(value: enabled, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _PeriodicSwitch extends StatelessWidget {
  const _PeriodicSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: 'Đo định kì mỗi 15p',
      child: GestureDetector(
        key: const ValueKey('periodic-switch'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 46,
          height: 26,
          padding: const EdgeInsets.all(3),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: value ? _switchOn : _switchOff,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: value ? _switchOnThumb : _card,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _SampleNotice extends StatelessWidget {
  const _SampleNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _chipBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Symbols.info, size: 18, color: _accentText, weight: 500),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              sampleDataNotice,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: _accentText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.stats, required this.isSample});

  final TemperatureStats stats;
  final bool isSample;

  @override
  Widget build(BuildContext context) {
    const label = TextStyle(
      fontSize: 12,
      height: _lineHeight,
      color: _secondaryText,
    );
    const value = TextStyle(
      fontSize: 26,
      height: _lineHeight,
      fontWeight: FontWeight.w600,
      color: _primaryText,
    );

    return Container(
      height: 316,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 18,
            right: 18,
            top: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '24 GIỜ QUA',
                  style: label.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 7),
                Text(
                  stats.isEmpty
                      ? 'Nhiệt độ pin trong 24 giờ gần nhất'
                      : '${_dateTime(stats.from)} – ${_dateTime(stats.to)}',
                  style: label,
                ),
                const SizedBox(height: 17),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 162,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Thấp nhất', style: label),
                          const SizedBox(height: 4),
                          Text(_celsius(stats.min), style: value),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cao nhất', style: label),
                          const SizedBox(height: 4),
                          Text(_celsius(stats.max), style: value),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (stats.isEmpty)
            const Positioned(
              left: 18,
              right: 18,
              top: 140,
              height: 158,
              child: _EmptyBox(
                color: _background,
                radius: 14,
                title: 'Chưa có dữ liệu nhiệt độ',
                titleSize: 16,
                titleTop: 34,
                message:
                    'Bật đo định kì để theo dõi nhiệt độ pin trong 24 giờ qua.',
                messageTop: 68,
                messageWidth: 266,
              ),
            )
          else ...[
            Positioned(
              left: 16,
              right: 20,
              top: 145,
              height: 141,
              child: _TemperatureChart(stats: stats),
            ),
            Positioned(
              left: 18,
              top: 296,
              child: Text(
                isSample
                    ? 'Dữ liệu minh họa · Nhiệt độ pin (°C)'
                    : 'Nhiệt độ pin (°C)',
                style: const TextStyle(
                  fontSize: 10,
                  height: _lineHeight,
                  color: _secondaryText,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TemperatureChart extends StatelessWidget {
  const _TemperatureChart({required this.stats});

  final TemperatureStats stats;

  static const _axisText = TextStyle(
    fontSize: 11,
    height: _lineHeight,
    color: _secondaryText,
  );

  @override
  Widget build(BuildContext context) {
    final totalMinutes = statsWindow.inMinutes.toDouble();
    final showDots = stats.points.length <= 24;

    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: totalMinutes,
          minY: 0,
          maxY: stats.axisMax - stats.axisMin,
          clipData: const FlClipData.none(),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              for (final y in [0.0, stats.axisMax - stats.axisMin])
                HorizontalLine(y: y, color: _divider, strokeWidth: 1),
            ],
          ),
          lineTouchData: const LineTouchData(enabled: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: stats.axisStep,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: _divider, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: stats.axisStep,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  space: 0,
                  child: SizedBox(
                    width: 28,
                    child: Text(
                      '${(value + stats.axisMin).round()}°',
                      style: _axisText,
                    ),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: totalMinutes / 2,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  space: 12,
                  child: Text(
                    _time(stats.from.add(Duration(minutes: value.round()))),
                    style: _axisText,
                  ),
                ),
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (final point in stats.points)
                  FlSpot(point.minute, point.temperature - stats.axisMin),
              ],
              color: _line,
              barWidth: 2.5,
              isStrokeCapRound: true,
              isStrokeJoinRound: true,
              dotData: FlDotData(
                show: showDots,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                      radius: 2.25,
                      color: _line,
                      strokeWidth: 1.5,
                      strokeColor: Colors.white,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _area.withValues(alpha: 0.48),
                    _area.withValues(alpha: 0.06),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Text(
            'Số lần đo',
            style: TextStyle(
              fontSize: 18,
              height: _lineHeight,
              fontWeight: FontWeight.w600,
              color: _primaryText,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            '$count lần',
            style: const TextStyle(
              fontSize: 13,
              height: _lineHeight,
              fontWeight: FontWeight.w600,
              color: _accentText,
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.stats});

  final TemperatureStats stats;

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return const SizedBox(
        height: 132,
        child: _EmptyBox(
          color: _card,
          radius: 20,
          title: 'Chưa có lần đo nào',
          titleSize: 14,
          titleTop: 32,
          message: 'Thời gian và nhiệt độ sẽ xuất hiện tại đây.',
          messageTop: 61,
          messageWidth: 282,
        ),
      );
    }

    final today = DateUtils.dateOnly(stats.to);
    final items = stats.newestFirst;

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            _HistoryRow(
              measurement: items[i],
              isToday: DateUtils.isSameDay(items[i].measuredAt, today),
              showDivider: i < items.length - 1,
            ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.measurement,
    required this.isToday,
    required this.showDivider,
  });

  final Measurement measurement;
  final bool isToday;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: _rowDivider))
            : null,
      ),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 49),
            child: Text(
              _time(measurement.measuredAt),
              style: const TextStyle(
                fontSize: 13,
                height: _lineHeight,
                fontWeight: FontWeight.w600,
                color: _primaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              isToday ? '· Hôm nay' : '· Hôm qua',
              style: const TextStyle(
                fontSize: 12,
                height: _lineHeight,
                color: _secondaryText,
              ),
            ),
          ),
          Text(
            _celsius(measurement.temperature),
            style: const TextStyle(
              fontSize: 14,
              height: _lineHeight,
              fontWeight: FontWeight.w600,
              color: _line,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({
    required this.color,
    required this.radius,
    required this.title,
    required this.titleSize,
    required this.titleTop,
    required this.message,
    required this.messageTop,
    required this.messageWidth,
  });

  final Color color;
  final double radius;
  final String title;
  final double titleSize;
  final double titleTop;
  final String message;
  final double messageTop;
  final double messageWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 12,
            right: 12,
            top: titleTop,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: titleSize,
                height: (titleSize + 8) / titleSize,
                fontWeight: FontWeight.w600,
                color: _primaryText,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: messageTop,
            child: Center(
              child: SizedBox(
                width: messageWidth,
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 20 / 13,
                    color: _secondaryText,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
