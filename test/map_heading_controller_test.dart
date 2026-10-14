import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:taxi_driver_app/services/map_heading_controller.dart';

Position _position({
  required double heading,
  required double speed,
  double headingAccuracy = 8,
  double lat = 36.8,
  double lng = 10.18,
}) {
  return Position(
    longitude: lng,
    latitude: lat,
    timestamp: DateTime.now(),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: heading,
    headingAccuracy: headingAccuracy,
    speed: speed,
    speedAccuracy: 0.5,
  );
}

void main() {
  group('MapHeadingMath', () {
    test('shortestDelta handles the 0/360 wrap (350 → 10 is +20)', () {
      expect(MapHeadingMath.shortestDelta(350, 10), closeTo(20, 0.001));
      expect(MapHeadingMath.shortestDelta(10, 350), closeTo(-20, 0.001));
      expect(MapHeadingMath.shortestDelta(0, 90), closeTo(90, 0.001));
    });

    test('normalize keeps bearings in 0–360', () {
      expect(MapHeadingMath.normalize(-10), closeTo(350, 0.001));
      expect(MapHeadingMath.normalize(370), closeTo(10, 0.001));
    });
  });

  group('MapHeadingController', () {
    test('ignores heading changes inside the deadband', () {
      final controller = MapHeadingController();
      final origin = const LatLng(36.8, 10.18);

      controller.ingestPosition(
        _position(heading: 0, speed: 10),
        previous: null,
        current: origin,
      );
      controller.ingestPosition(
        _position(heading: 2, speed: 10),
        previous: origin,
        current: origin,
      );

      expect(controller.displayedHeading, closeTo(0, 0.001));
    });

    test('accepts a turn just beyond the deadband', () {
      final controller = MapHeadingController();
      final origin = const LatLng(36.8, 10.18);

      controller.ingestPosition(
        _position(heading: 0, speed: 10),
        previous: null,
        current: origin,
      );
      controller.ingestPosition(
        _position(heading: 8, speed: 10),
        previous: origin,
        current: origin,
      );

      controller.tick();
      expect(
        MapHeadingMath.shortestDelta(0, controller.displayedHeading),
        greaterThan(0),
      );
    });

    test('freezes heading when the vehicle is stopped', () {
      final controller = MapHeadingController();
      final origin = const LatLng(36.8, 10.18);

      controller.ingestPosition(
        _position(heading: 90, speed: 10),
        previous: null,
        current: origin,
      );
      controller.ingestPosition(
        _position(heading: 180, speed: 0.2),
        previous: origin,
        current: origin,
      );

      expect(controller.displayedHeading, closeTo(90, 0.001));
    });

    test('map rotation is heading-up (negative of displayed heading)', () {
      final controller = MapHeadingController();
      controller.ingestPosition(
        _position(heading: 90, speed: 10),
        previous: null,
        current: const LatLng(36.8, 10.18),
      );
      expect(controller.mapRotationDegrees, closeTo(-90, 0.001));
    });

    test('tick interpolates along the shortest path across 0°', () {
      final controller = MapHeadingController(
        config: const MapHeadingConfig(deadbandDegrees: 8, smoothing: 0.5),
      );
      final origin = const LatLng(36.8, 10.18);

      controller.ingestPosition(
        _position(heading: 350, speed: 10),
        previous: null,
        current: origin,
      );
      controller.ingestPosition(
        _position(heading: 10, speed: 10),
        previous: origin,
        current: origin,
      );

      controller.tick();
      final afterFirstTick = controller.displayedHeading;
      // 350 + 0.5 * 20 = 0, not 350 - 0.5 * 340
      expect(MapHeadingMath.shortestDelta(350, afterFirstTick), greaterThan(0));
      expect(afterFirstTick < 20 || afterFirstTick > 340, isTrue);
    });

    test('rejects unknown GPS heading (0 with accuracy 0)', () {
      final controller = MapHeadingController();
      controller.ingestPosition(
        _position(heading: 0, speed: 10, headingAccuracy: 0),
        previous: null,
        current: const LatLng(36.8, 10.18),
      );
      expect(controller.hasHeading, isFalse);
    });
  });
}
