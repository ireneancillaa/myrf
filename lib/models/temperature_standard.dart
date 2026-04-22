class TemperatureStandard {
  final int age;
  final double min;
  final double max;
  final double front;
  final double middle;
  final double rear;

  TemperatureStandard({
    required this.age,
    required this.min,
    required this.max,
    required this.front,
    required this.middle,
    required this.rear,
  });

  factory TemperatureStandard.fromFirestore(Map<String, dynamic> data) {
    return TemperatureStandard(
      age: data['age'] ?? 0,
      min: (data['min'] ?? data['min_temp'] ?? 0).toDouble(),
      max: (data['max'] ?? data['max_temp'] ?? 0).toDouble(),
      front: (data['front'] ?? 0).toDouble(),
      middle: (data['middle'] ?? 0).toDouble(),
      rear: (data['rear'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'age': age,
      'min': min,
      'max': max,
      'front': front,
      'middle': middle,
      'rear': rear,
    };
  }
}
