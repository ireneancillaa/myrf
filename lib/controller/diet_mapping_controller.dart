import 'package:get/get.dart';

class DietMappingController extends GetxController {
  final dietCount = RxnInt();
  final dietReplication = RxnInt();
  final dietPenSelections = <int, List<int>>{}.obs;

  List<int> dietPensFor(int dietNumber) {
    return List<int>.from(dietPenSelections[dietNumber] ?? const <int>[]);
  }

  Set<int> usedPensExcept(int dietNumber) {
    final usedPens = <int>{};
    for (final entry in dietPenSelections.entries) {
      if (entry.key == dietNumber) continue;
      usedPens.addAll(entry.value);
    }
    return usedPens;
  }

  void updateDietPens(int dietNumber, List<int> pens) {
    dietPenSelections[dietNumber] = List<int>.from(pens)..sort();
    dietPenSelections.refresh();
  }

  void syncFromValues({required String diet, required String replication}) {
    final nextDietCount = (int.tryParse(diet) ?? 1).clamp(1, 9999);
    final nextReplication = (int.tryParse(replication) ?? 1).clamp(1, 9999);

    dietCount.value = nextDietCount;
    dietReplication.value = nextReplication;

    // Keep pen selections valid when diet count changes.
    dietPenSelections.removeWhere((key, value) => key > nextDietCount);
    dietPenSelections.refresh();
  }
}
