import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class DietMappingController extends GetxController {
  final dietCount = RxnInt();
  final dietReplication = RxnInt();
  final maxPens = 0.obs;
  final dietPenSelections = <int, List<int>>{}.obs;
  final dietInputValues = <int, Map<String, String>>{}.obs;
  final copiedDietInputs = Rxn<Map<String, String>>();

  VoidCallback? _onChangeCallback;

  void addChangeListener(VoidCallback callback) {
    _onChangeCallback = callback;
  }

  void _notifyChanges() {
    _onChangeCallback?.call();
  }

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
    _notifyChanges();
  }

  String dietInputFor(int dietNumber, String fieldKey) {
    return dietInputValues[dietNumber]?[fieldKey] ?? '';
  }

  void updateDietInput(int dietNumber, String fieldKey, String value) {
    final nextValues = Map<String, String>.from(
      dietInputValues[dietNumber] ?? const <String, String>{},
    );
    nextValues[fieldKey] = value;
    dietInputValues[dietNumber] = nextValues;
    dietInputValues.refresh();
    _notifyChanges();
  }

  void loadDietInputValues(Map<int, Map<String, String>> values) {
    dietInputValues.assignAll({
      for (final entry in values.entries)
        entry.key: Map<String, String>.from(entry.value),
    });
    dietInputValues.refresh();
    _notifyChanges();
  }

  bool get hasCopiedDietInputs => copiedDietInputs.value != null;

  void copyDietInputsFrom(int dietNumber) {
    final source = Map<String, String>.from(
      dietInputValues[dietNumber] ?? const <String, String>{},
    );
    copiedDietInputs.value = {
      'preStarter': (source['preStarter'] ?? ''),
      'starter': (source['starter'] ?? ''),
      'finisher': (source['finisher'] ?? ''),
      'remarks': (source['remarks'] ?? ''),
    };
  }

  bool pasteDietInputsTo(int dietNumber) {
    final source = copiedDietInputs.value;
    if (source == null) return false;

    dietInputValues[dietNumber] = {
      'preStarter': (source['preStarter'] ?? ''),
      'starter': (source['starter'] ?? ''),
      'finisher': (source['finisher'] ?? ''),
      'remarks': (source['remarks'] ?? ''),
    };
    dietInputValues.refresh();
    _notifyChanges();
    return true;
  }

  void clearRuntimeState() {
    dietPenSelections.clear();
    dietInputValues.clear();
    copiedDietInputs.value = null;
    dietCount.value = null;
    dietReplication.value = null;
  }

  void syncFromValues({required String diet, required String replication}) {
    final nextDietCount = (int.tryParse(diet) ?? 1).clamp(1, 9999);
    final nextReplication = (int.tryParse(replication) ?? 1).clamp(1, 9999);

    dietCount.value = nextDietCount;
    dietReplication.value = nextReplication;

    // Keep pen selections valid when diet count changes.
    dietPenSelections.removeWhere((key, value) => key > nextDietCount);
    // Remove pens that exceed maxPens
    for (final key in dietPenSelections.keys) {
      final pens = dietPenSelections[key]!;
      dietPenSelections[key] = pens.where((p) => p <= maxPens.value).toList();
    }
    dietPenSelections.refresh();
    dietInputValues.removeWhere((key, value) => key > nextDietCount);
    dietInputValues.refresh();
  }
}
