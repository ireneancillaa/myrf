class BroilerProjectData {
  BroilerProjectData({
    required this.projectId,
    required this.projectName,
    required this.trialDate,
    required this.trialHouse,
    required this.strain,
    required this.hatchery,
    required this.breedingFarm,
    required this.boxBatchCode,
    required this.selector,
    required this.docInDate,
    required this.docWeight,
    required this.weighing3Weeks,
    required this.weighing5Weeks,
    required this.numberOfBirds,
    required this.diet,
    required this.replication,
    required this.dietReplication,
    this.updatedAt,
  });

  final String projectId;
  final String projectName;
  final String trialDate;
  final String trialHouse;
  final String strain;
  final String hatchery;
  final String breedingFarm;
  final String boxBatchCode;
  final String selector;
  final String docInDate;
  final String docWeight;
  final String weighing3Weeks;
  final String weighing5Weeks;
  final String numberOfBirds;
  final String diet;
  final String replication;
  final int? dietReplication;
  final DateTime? updatedAt;

  BroilerProjectData copyWith({
    String? projectId,
    String? projectName,
    String? trialDate,
    String? trialHouse,
    String? strain,
    String? hatchery,
    String? breedingFarm,
    String? boxBatchCode,
    String? selector,
    String? docInDate,
    String? docWeight,
    String? weighing3Weeks,
    String? weighing5Weeks,
    String? numberOfBirds,
    String? diet,
    String? replication,
    int? dietReplication,
    DateTime? updatedAt,
  }) {
    return BroilerProjectData(
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      trialDate: trialDate ?? this.trialDate,
      trialHouse: trialHouse ?? this.trialHouse,
      strain: strain ?? this.strain,
      hatchery: hatchery ?? this.hatchery,
      breedingFarm: breedingFarm ?? this.breedingFarm,
      boxBatchCode: boxBatchCode ?? this.boxBatchCode,
      selector: selector ?? this.selector,
      docInDate: docInDate ?? this.docInDate,
      docWeight: docWeight ?? this.docWeight,
      weighing3Weeks: weighing3Weeks ?? this.weighing3Weeks,
      weighing5Weeks: weighing5Weeks ?? this.weighing5Weeks,
      numberOfBirds: numberOfBirds ?? this.numberOfBirds,
      diet: diet ?? this.diet,
      replication: replication ?? this.replication,
      dietReplication: dietReplication ?? this.dietReplication,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get currentAge {
    try {
      final docIn = DateTime.tryParse(docInDate);
      if (docIn == null) return 0;
      final diff = DateTime.now().difference(docIn).inDays;
      return diff >= 0 ? diff + 1 : 0;
    } catch (_) {
      return 0;
    }
  }
}