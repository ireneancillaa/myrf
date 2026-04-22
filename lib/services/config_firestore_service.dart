import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/temperature_standard.dart';

class ConfigFirestoreService {
  ConfigFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String temperatureCollection = 'temperature_configs';

  Future<TemperatureStandard?> getTemperatureStandard(int age) async {
    try {
      final querySnapshot = await _firestore
          .collection(temperatureCollection)
          .where('age', isEqualTo: age)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return TemperatureStandard.fromFirestore(querySnapshot.docs.first.data());
    } catch (e) {
      return null;
    }
  }

  // Helper to pre-populate standards if needed (optional)
  Future<void> saveTemperatureStandard(TemperatureStandard standard) async {
    await _firestore
        .collection(temperatureCollection)
        .doc('age_${standard.age}')
        .set(standard.toFirestore());
  }
}
