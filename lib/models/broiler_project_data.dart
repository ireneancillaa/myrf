class BroilerProjectData {
  BroilerProjectData({
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
}
