import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/temperature_standard.dart';
import '../models/trial_house.dart';

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

  Stream<List<String>> streamStrains() {
    return _firestore.collection('strain-rf').snapshots().map((snapshot) {
      final strains = snapshot.docs
          .map((doc) => doc.data())
          .where((data) => data['isactive'] == 'Y' || data['isActive'] == 'Y')
          .map((data) => data['name'] as String?)
          .where((name) => name != null && name.trim().isNotEmpty)
          .map((name) => name!.trim())
          .toList();
      strains.sort();
      return strains;
    });
  }

  Stream<List<String>> streamHatcheries() {
    return _firestore.collection('hatchery-rf').snapshots().map((snapshot) {
      final hatcheries = snapshot.docs
          .map((doc) => doc.data())
          .where((data) => data['isactive'] == 'Y' || data['isActive'] == 'Y')
          .map((data) => data['name'] as String?)
          .where((name) => name != null && name.trim().isNotEmpty)
          .map((name) => name!.trim())
          .toList();
      hatcheries.sort();
      return hatcheries;
    });
  }

  Stream<List<TrialHouse>> streamTrialHouses() {
    return _firestore.collection('trialHouse-rf').snapshots().map((snapshot) {
      final houses = snapshot.docs
          .map((doc) => doc.data())
          .where((data) => data['isactive'] == 'Y' || data['isActive'] == 'Y')
          .map((data) => TrialHouse.fromFirestore(data))
          .where((house) => house.name.isNotEmpty && house.pens > 0)
          .toList();
          
      houses.sort((a, b) => _naturalCompare(a.name, b.name));
      return houses;
    });
  }

  int _naturalCompare(String a, String b) {
    final regex = RegExp(r'(\d+)|([^\d]+)');
    final matchesA = regex.allMatches(a).map((m) => m.group(0)!).toList();
    final matchesB = regex.allMatches(b).map((m) => m.group(0)!).toList();

    for (var i = 0; i < matchesA.length && i < matchesB.length; i++) {
      final partA = matchesA[i];
      final partB = matchesB[i];

      final numA = int.tryParse(partA);
      final numB = int.tryParse(partB);

      if (numA != null && numB != null) {
        final cmp = numA.compareTo(numB);
        if (cmp != 0) return cmp;
      } else {
        final cmp = partA.compareTo(partB);
        if (cmp != 0) return cmp;
      }
    }
    return matchesA.length.compareTo(matchesB.length);
  }
}
