import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_driver_app/features/shifts/domain/shift_model.dart';
import 'package:taxi_driver_app/features/shifts/presentation/widgets/shift_card.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('fr')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('fr'), Locale('ar')],
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  final shift = ShiftModel(
    carId: 'c1',
    driverName: 'Mohamed Ali Ben Salah',
    phoneNumber: '+216 22 333 444',
    startTime: const TimeOfDay(hour: 22, minute: 0),
    endTime: const TimeOfDay(hour: 5, minute: 30),
  );

  for (final width in [300.0, 360.0, 430.0]) {
    testWidgets('ShiftCard lays out at ${width.toInt()}px', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(Padding(
        padding: const EdgeInsets.all(16),
        child: ShiftCard(shift: shift, onEdit: () {}, onDelete: () {}),
      )));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Mohamed Ali Ben Salah'), findsOneWidget);
      expect(find.text('7h30'), findsOneWidget);
    });
  }

  testWidgets('ShiftCard lays out in Arabic RTL', (tester) async {
    await tester.pumpWidget(_wrap(
      Padding(
        padding: const EdgeInsets.all(16),
        child: ShiftCard(shift: shift, onEdit: () {}, onDelete: () {}),
      ),
      locale: const Locale('ar'),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
