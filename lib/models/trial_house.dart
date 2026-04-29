class TrialHouse {
  TrialHouse({
    required this.name,
    required this.pens,
  });

  final String name;
  final int pens;

  factory TrialHouse.fromFirestore(Map<String, dynamic> data) {
    return TrialHouse(
      name: (data['trialHouse'] as String?)?.trim() ?? '',
      pens: int.tryParse(data['penTrialhouse']?.toString() ?? '') ?? 0,
    );
  }
}
