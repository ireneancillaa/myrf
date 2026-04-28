import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  project,
  weighing,
  feses,
  infeed,
  mortality,
  maleBirds,
}

class ActivityLog {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final ActivityType type;
  final String projectId;
  final String projectName;

  ActivityLog({
    this.id = '',
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
    required this.projectId,
    required this.projectName,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json, {String? id}) {
    ActivityType parseType(String? value) {
      switch (value) {
        case 'project':
          return ActivityType.project;
        case 'weighing':
          return ActivityType.weighing;
        case 'feses':
          return ActivityType.feses;
        case 'infeed':
          return ActivityType.infeed;
        case 'mortality':
          return ActivityType.mortality;
        case 'maleBirds':
          return ActivityType.maleBirds;
        default:
          return ActivityType.project;
      }
    }

    return ActivityLog(
      id: id ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: parseType(json['type']),
      projectId: json['projectId'] ?? '',
      projectName: json['projectName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'timestamp': timestamp,
      'type': type.name,
      'projectId': projectId,
      'projectName': projectName,
    };
  }
}
