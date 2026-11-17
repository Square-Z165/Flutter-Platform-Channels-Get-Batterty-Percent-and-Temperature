import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:source_code/main.dart';
import 'package:source_code/theme/battery_palette.dart';
import 'package:source_code/widgets/mode_button.dart';

void main() {
  test('màu đổi theo dữ liệu trả về', () {
    BatteryStatus status(BatteryInfoMode? mode, {int? p, double? t}) =>
        batteryStatusFor(mode: mode, percent: p, temperature: t);

    expect(status(null, p: 82, t: 48), BatteryStatus.idle);
    expect(status(BatteryInfoMode.level), BatteryStatus.idle);
    expect(status(BatteryInfoMode.level, p: 82), BatteryStatus.normal);
    expect(status(BatteryInfoMode.level, p: 20), BatteryStatus.bad);
    expect(status(BatteryInfoMode.temperature), BatteryStatus.idle);
    expect(status(BatteryInfoMode.temperature, t: 32), BatteryStatus.normal);
    expect(status(BatteryInfoMode.temperature, t: 45), BatteryStatus.overheat);
  });

  testWidgets('bấm nút thì gọi Android và đổi màu theo kết quả', (tester) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      batteryChannel,
      (call) async {
        calls.add(call.method);
        return call.method == 'getPercent' ? 82 : 48.5;
      },
    );

    Color? background() =>
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor;

    await tester.pumpWidget(const BatteryApp());
    expect(background(), BatteryPalette.idle.background);
    expect(find.byType(ModeButton), findsNWidgets(2));
    expect(find.text('Chưa đo'), findsOneWidget);

    await tester.tap(find.byTooltip('Trạng thái pin'));
    await tester.pumpAndSettle();
    expect(background(), BatteryPalette.normal.background);
    expect(find.text('82%'), findsOneWidget);

    await tester.tap(find.byTooltip('Nhiệt độ pin'));
    await tester.pumpAndSettle();
    expect(background(), BatteryPalette.overheat.background);
    expect(find.text('49°C'), findsWidgets);

    expect(calls, ['getPercent', 'getTemperature']);
  });

  testWidgets('Android báo lỗi thì màn hình vẫn ở trạng thái chưa đo', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      batteryChannel,
      (call) async => throw Exception('lỗi'),
    );

    await tester.pumpWidget(const BatteryApp());
    await tester.tap(find.byTooltip('Nhiệt độ pin'));
    await tester.pumpAndSettle();

    expect(find.text('Chưa đo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
