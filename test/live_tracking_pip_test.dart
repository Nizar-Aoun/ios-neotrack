import 'package:flutter_test/flutter_test.dart';
import 'package:floating/floating.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Live Tracking PiP (floating package)', () {
    test('Rational.square meets Android PiP aspect ratio requirements', () {
      const square = Rational.square();
      expect(square.numerator, 1);
      expect(square.denominator, 1);
      expect(square.aspectRatio, 1.0);
      // Android allows 1/2.39 .. 2.39
      expect(square.aspectRatio, greaterThanOrEqualTo(1 / 2.39));
      expect(square.aspectRatio, lessThanOrEqualTo(2.39));
    });

    test('OnLeavePiP can be constructed with square aspect ratio', () {
      const args = OnLeavePiP(aspectRatio: Rational.square());
      expect(args.aspectRatio.numerator, 1);
      expect(args.aspectRatio.denominator, 1);
    });
  });
}
