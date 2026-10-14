class Car {
  final String id;
  final String plateNumber;
  final String brand;
  final String model;
  final String carType;

  Car({
    required this.id,
    required this.plateNumber,
    required this.brand,
    required this.model,
    required this.carType,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    String parseId(dynamic id) {
      if (id is String) return id;
      if (id is Map && id.containsKey('_id')) return id['_id'];
      return id.toString();
    }

    return Car(
      id: parseId(json['_id']),
      plateNumber: json['plate_number'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      carType: json['car_type'] ?? 'taxi',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'plate_number': plateNumber,
      'brand': brand,
      'model': model,
      'car_type': carType,
    };
  }
} 