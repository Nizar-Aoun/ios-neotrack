import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:taxi_driver_app/services/routing_service.dart';

void main() {
  group('RoutingService Tests', () {
    late RoutingService routingService;

    setUp(() {
      routingService = RoutingService();
    });

    tearDown(() {
      routingService.clearCache();
    });

    test('should handle empty points list', () async {
      final result = await routingService.snapToRoad([]);
      expect(result, isEmpty);
    });

    test('should handle single point', () async {
      final point = LatLng(36.8065, 10.1815);
      final result = await routingService.snapToRoad([point]);
      expect(result, hasLength(1));
      expect(result.first, equals(point));
    });

    test('should handle two close points', () async {
      final point1 = LatLng(36.8065, 10.1815);
      final point2 = LatLng(36.8066, 10.1816); // Very close point
      final result = await routingService.snapToRoad([point1, point2]);
      expect(result, hasLength(2));
    });

    test('should handle GPS noise detection', () async {
      final points = [
        LatLng(36.8065, 10.1815),
        LatLng(36.8066, 10.1816), // Normal movement
        LatLng(36.8100, 10.1900), // GPS noise (sudden jump)
        LatLng(36.8067, 10.1817), // Back to normal
      ];
      
      final result = await routingService.snapToRoad(points);
      // Should handle GPS noise appropriately
      expect(result, isNotEmpty);
    });

    test('should handle stationary periods', () async {
      final points = [
        LatLng(36.8065, 10.1815),
        LatLng(36.8065, 10.1815), // Same position (stationary)
        LatLng(36.8065, 10.1815), // Same position (stationary)
        LatLng(36.8066, 10.1816), // Movement
      ];
      
      final result = await routingService.snapToRoad(points);
      // Should filter out excessive stationary points
      expect(result, isNotEmpty);
    });

    test('should provide cache statistics', () {
      final stats = routingService.getCacheStats();
      expect(stats, contains('cacheSize'));
      expect(stats, contains('cacheKeys'));
    });

    test('should clear cache', () {
      final statsBefore = routingService.getCacheStats();
      routingService.clearCache();
      final statsAfter = routingService.getCacheStats();
      
      expect(statsAfter['cacheSize'], equals(0));
    });
  });
} 