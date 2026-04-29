import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'diet_mapping_controller.dart';
import '../models/broiler_project_data.dart';
import '../models/temperature_standard.dart';
import '../services/broiler_firestore_service.dart';
import '../services/config_firestore_service.dart';
import 'user_session_controller.dart';
import 'history_controller.dart';
import '../models/activity_log.dart';
import '../models/trial_house.dart';

enum BroilerWorkflowStatus { drafted, inProgress, completed }

class BroilerController extends GetxController {
  final projectNameController = TextEditingController();
  final projectNameWarning = RxnString();
  final trialDateController = TextEditingController();
  final trialHouseController = TextEditingController();
  final strainController = TextEditingController();
  final hatcheryController = TextEditingController();
  final breedingFarmController = TextEditingController();
  final boxBatchCodeController = TextEditingController();
  final selectorController = TextEditingController();
  final docInDateController = TextEditingController();
  final docWeightController = TextEditingController();
  final weighing3WeeksController = TextEditingController();
  final weighing5WeeksController = TextEditingController();
  final numberOfBirdsController = TextEditingController();
  final dietController = TextEditingController();
  final replicationController = TextEditingController();

  final projects = <BroilerProjectData>[].obs;
  final selectedProjectId = RxnString();
  final selectedProjectName = RxnString();
  final selectedTrialHouse = RxnString();
  final selectedStrain = RxnString();
  final selectedHatchery = RxnString();
  final selectedDocInDate = RxnString();
  final projectStatuses = <String, BroilerWorkflowStatus>{}.obs;
  final projectLastOpenedSteps = <String, int>{}.obs;
  final projectSampleWeights = <String, List<double>>{}.obs;
  final projectSampleGroups = <String, List<List<double>>>{}.obs;
  final projectSampleGroupBluetoothFlags = <String, List<List<bool>>>{}.obs;
  final projectDocDistributions = <String, List<Map<String, dynamic>>>{}.obs;
  final projectAttachmentUrls = <String, List<String>>{}.obs;
  final projectBluetoothInputs = <String, bool>{}.obs;
  final projectSampleBluetoothInputs = <String, bool>{}.obs;
  final projectDistributionBluetoothInputs = <String, bool>{}.obs;
  final projectBoxValues = <String, Map<String, String>>{}.obs;
  final projectDietPenSelections = <String, Map<int, List<int>>>{}.obs;
  final projectDietInputValues = <String, Map<int, Map<String, String>>>{}.obs;

  final currentAge = 0.obs;
  final currentTemperatureStandard = Rxn<TemperatureStandard>();

  final frontTemp = '-'.obs;
  final middleTemp = '-'.obs;
  final rearTemp = '-'.obs;
  final minTempStat = 0.0.obs;
  final maxTempStat = 0.0.obs;
  final availableStrains = <String>[].obs;
  final availableHatcheries = <String>[].obs;
  final availableTrialHouses = <TrialHouse>[].obs;
  final availableTrialHouseNames = <String>[].obs;

  // Computed max pens based on selected trial house
  int get maxPens {
    final houseName = selectedTrialHouse.value;
    if (houseName == null || houseName.isEmpty) return 0;
    final house = availableTrialHouses.firstWhereOrNull(
      (h) => h.name == houseName,
    );
    return house?.pens ?? 0;
  }

  VoidCallback? _onStatusChangeCallback;
  BroilerFirestoreService get _firestoreService =>
      Get.find<BroilerFirestoreService>();
  ConfigFirestoreService get _configService =>
      Get.find<ConfigFirestoreService>();
  UserSessionController get _sessionController =>
      Get.find<UserSessionController>();
  StreamSubscription<Map<String, String>>? _statusSubscription;
  StreamSubscription<List<BroilerProjectData>>? _projectsSubscription;
  StreamSubscription<List<String>>? _strainsSubscription;
  StreamSubscription<List<String>>? _hatcheriesSubscription;
  StreamSubscription<List<TrialHouse>>? _trialHousesSubscription;
  final Map<String, Future<void>> _projectSyncQueue = <String, Future<void>>{};
  final Map<String, String> _migratedIdMap =
      <String, String>{}; // localId -> firestoreId

  @override
  void onInit() {
    super.onInit();
    
    projectNameController.addListener(_validateProjectName);
    docInDateController.addListener(updateCurrentAgeAndStandard);

    ever(_sessionController.userId, (userId) {
      if (userId.isNotEmpty) {
        _bindFirestoreStreams();
      } else {
        _statusSubscription?.cancel();
        _projectsSubscription?.cancel();
        projects.clear();
        projectStatuses.clear();
      }
    });

    // Initial load if already logged in
    if (_sessionController.userId.isNotEmpty) {
      _bindFirestoreStreams();
    }

    ever(selectedProjectId, (_) => _listenToTemperatureRecords());
    _loadAvailableStrains();
    _loadAvailableHatcheries();
    _loadAvailableTrialHouses();

    ever(selectedTrialHouse, (_) => _updateMaxPens());
    ever(availableTrialHouses, (_) => _updateMaxPens());
  }

  void _loadAvailableStrains() {
    _strainsSubscription?.cancel();
    _strainsSubscription = _configService.streamStrains().listen((strains) {
      if (strains.isNotEmpty) {
        availableStrains.assignAll(strains);
      } else {
        availableStrains.clear();
      }
    });
  }

  void _loadAvailableHatcheries() {
    _hatcheriesSubscription?.cancel();
    _hatcheriesSubscription = _configService.streamHatcheries().listen((hatcheries) {
      if (hatcheries.isNotEmpty) {
        availableHatcheries.assignAll(hatcheries);
      } else {
        availableHatcheries.clear();
      }
    });
  }

  void _loadAvailableTrialHouses() {
    _trialHousesSubscription?.cancel();
    _trialHousesSubscription = _configService.streamTrialHouses().listen((houses) {
      if (houses.isNotEmpty) {
        availableTrialHouses.assignAll(houses);
        availableTrialHouseNames.assignAll(houses.map((h) => h.name));
      } else {
        availableTrialHouses.clear();
        availableTrialHouseNames.clear();
      }
    });
  }

  void _updateMaxPens() {
    final houseName = selectedTrialHouse.value;
    if (houseName == null || houseName.isEmpty) return;

    final house = availableTrialHouses.firstWhereOrNull(
      (h) => h.name == houseName,
    );

    if (house != null && Get.isRegistered<DietMappingController>()) {
      Get.find<DietMappingController>().maxPens.value = house.pens;
      Get.find<DietMappingController>().syncFromValues(
        diet: dietController.text,
        replication: replicationController.text,
      );
    }
  }

  void _listenToTemperatureRecords() {
    final projectId = selectedProjectId.value;
    if (projectId == null || projectId.isEmpty) {
      _clearTemperatureValues();
      return;
    }

    final project = projects.firstWhereOrNull((p) => p.projectId == projectId);
    if (project == null) {
      _clearTemperatureValues();
      return;
    }

    frontTemp.value = project.frontTemp != null
        ? '${project.frontTemp}°C'
        : '-';
    middleTemp.value = project.middleTemp != null
        ? '${project.middleTemp}°C'
        : '-';
    rearTemp.value = project.rearTemp != null ? '${project.rearTemp}°C' : '-';

    minTempStat.value = project.minTemp ?? 0.0;
    maxTempStat.value = project.maxTemp ?? 0.0;
  }

  void _clearTemperatureValues() {
    frontTemp.value = '-';
    middleTemp.value = '-';
    rearTemp.value = '-';
    minTempStat.value = 0.0;
    maxTempStat.value = 0.0;
  }

  List<String> get projectNames =>
      projects.map((item) => item.projectName).toList();

  List<String> get inProgressProjectNames {
    return projects
        .where(
          (item) =>
              statusFor(item.projectId) == BroilerWorkflowStatus.inProgress,
        )
        .map((item) => item.projectName)
        .toList();
  }

  void selectProject(String? projectId) {
    if (projectId == null) return;
    final project = projects.firstWhereOrNull(
      (item) => item.projectId == projectId,
    );
    if (project == null) return;

    selectedProjectId.value = project.projectId;
    selectedProjectName.value = project.projectName;
    projectNameController.text = project.projectName;
    trialDateController.text = project.trialDate;
    trialHouseController.text = project.trialHouse;
    strainController.text = project.strain;
    hatcheryController.text = project.hatchery;
    breedingFarmController.text = project.breedingFarm;
    boxBatchCodeController.text = project.boxBatchCode;
    selectorController.text = project.selector;
    docInDateController.text = project.docInDate;
    docWeightController.text = project.docWeight;
    weighing3WeeksController.text = project.weighing3Weeks;
    weighing5WeeksController.text = project.weighing5Weeks;
    numberOfBirdsController.text = project.numberOfBirds;
    dietController.text = project.diet;
    replicationController.text = project.replication;
    selectedTrialHouse.value = project.trialHouse;
    selectedStrain.value = project.strain;
    selectedHatchery.value = project.hatchery;
    selectedDocInDate.value = project.docInDate;

    final dietMappingController = Get.isRegistered<DietMappingController>()
        ? Get.find<DietMappingController>()
        : Get.put(DietMappingController(), permanent: true);
    dietMappingController.syncFromValues(
      diet: project.diet,
      replication: project.replication,
    );
  }

  void updateCurrentAgeAndStandard() {
    final docInStr = docInDateController.text.trim();
    if (docInStr.isEmpty) {
      currentAge.value = 0;
      currentTemperatureStandard.value = null;
      return;
    }

    try {
      final parts = docInStr.split('/');
      if (parts.length != 3) return;
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day == null || month == null || year == null) return;

      final docInDate = DateTime(year, month, day);
      final today = DateTime.now();
      final difference = today.difference(docInDate).inDays;
      // Age usually starts at Day 1
      currentAge.value = difference + 1;

      _fetchTemperatureStandard(currentAge.value);
    } catch (e) {
      debugPrint('Error calculating age: $e');
    }
  }

  void _validateProjectName() {
    final name = projectNameController.text.trim();
    if (name.isEmpty) {
      projectNameWarning.value = null;
      return;
    }

    final hasDuplicate = hasDuplicateDraftedProjectName(
      projectName: name,
      excludeProjectId: selectedProjectId.value,
    );

    if (hasDuplicate) {
      projectNameWarning.value =
          'Project name already exists in Drafted status.';
    } else {
      projectNameWarning.value = null;
    }
  }

  Future<void> _fetchTemperatureStandard(int age) async {
    final standard = await _configService.getTemperatureStandard(age);
    currentTemperatureStandard.value = standard;
  }

  void selectProjectByName(String? projectName) {
    if (projectName == null) return;
    final project = projects.firstWhereOrNull(
      (item) => item.projectName == projectName,
    );
    if (project == null) return;
    selectProject(project.projectId);
  }

  BroilerWorkflowStatus statusFor(String projectId) {
    return projectStatuses[projectId] ?? BroilerWorkflowStatus.drafted;
  }

  bool hasDuplicateDraftedProjectName({
    required String projectName,
    String? excludeProjectId,
  }) {
    final normalizedName = projectName.trim().toLowerCase();
    if (normalizedName.isEmpty) return false;

    final normalizedExcludeId = excludeProjectId?.trim() ?? '';
    for (final project in projects) {
      if (normalizedExcludeId.isNotEmpty &&
          project.projectId == normalizedExcludeId) {
        continue;
      }

      final isDrafted =
          statusFor(project.projectId) == BroilerWorkflowStatus.drafted;
      if (!isDrafted) continue;

      if (project.projectName.trim().toLowerCase() == normalizedName) {
        return true;
      }
    }

    return false;
  }

  void addStatusChangeListener(VoidCallback callback) {
    _onStatusChangeCallback = callback;
  }

  void _notifyStatusChange() {
    _onStatusChangeCallback?.call();
  }

  int lastOpenedStepFor(String projectId) {
    return projectLastOpenedSteps[projectId] ?? 0;
  }

  bool isReadOnly(String projectId) {
    final status = statusFor(projectId);
    return status == BroilerWorkflowStatus.inProgress ||
        status == BroilerWorkflowStatus.completed;
  }

  BroilerWorkflowStatus _statusFromFirestore(String value) {
    switch (value.trim().toLowerCase()) {
      case 'in_progress':
        return BroilerWorkflowStatus.inProgress;
      case 'completed':
        return BroilerWorkflowStatus.completed;
      default:
        return BroilerWorkflowStatus.drafted;
    }
  }

  String _statusToFirestore(BroilerWorkflowStatus status) {
    switch (status) {
      case BroilerWorkflowStatus.inProgress:
        return 'in_progress';
      case BroilerWorkflowStatus.completed:
        return 'completed';
      default:
        return 'drafted';
    }
  }

  void _bindFirestoreStreams() {
    final userId = _sessionController.userId.value;
    if (userId.isEmpty) {
      debugPrint('BroilerController: userId is empty, skipping streams');
      return;
    }

    debugPrint('BroilerController: Watching data for userId: $userId');
    debugPrint('BroilerController: Path: users/$userId/broiler_records');

    _statusSubscription?.cancel();
    _projectsSubscription?.cancel();

    _projectsSubscription = _firestoreService.watchProjects(userId).listen((
      remoteProjects,
    ) {
      projects.assignAll(remoteProjects);
      _listenToTemperatureRecords(); // Update temperature when projects list changes
    });

    _statusSubscription = _firestoreService.watchProjectStatuses(userId).listen(
      (remoteStatuses) {
        final mapped = <String, BroilerWorkflowStatus>{
          for (final entry in remoteStatuses.entries)
            entry.key: _statusFromFirestore(entry.value),
        };
        projectStatuses.assignAll(mapped);
      },
    );
  }

  String _createLocalProjectId() {
    return 'local_${DateTime.now().microsecondsSinceEpoch}';
  }

  void _enqueueProjectSync(String projectId, {bool showErrorSnackbar = true}) {
    final queueKey = projectId.trim();
    if (queueKey.isEmpty) return;

    final previousSync = _projectSyncQueue[queueKey] ?? Future<void>.value();
    final nextSync = previousSync.then((_) async {
      final saved = await _syncProjectToFirestore(queueKey);
      if (!saved && showErrorSnackbar) {
        Get.snackbar('Sync Failed', 'Data could not be synced to Firebase');
      }
    });

    _projectSyncQueue[queueKey] = nextSync;
    unawaited(
      nextSync.whenComplete(() {
        if (identical(_projectSyncQueue[queueKey], nextSync)) {
          _projectSyncQueue.remove(queueKey);
        }
      }),
    );
  }

  Future<bool> _syncProjectToFirestore(String projectId) async {
    // Check if this ID was migrated
    final actualProjectId = _migratedIdMap[projectId] ?? projectId;

    final data = projects.firstWhereOrNull(
      (item) => item.projectId == actualProjectId,
    );
    if (data == null) {
      debugPrint(
        'BroilerController: Sync aborted - project $actualProjectId not found in list (original search: $projectId)',
      );
      return false;
    }

    final userId = _sessionController.userId.value;
    if (userId.isEmpty) return false;

    try {
      final savedProjectId = await _firestoreService.upsertProjectRecord(
        userId: userId,
        projectId: data.projectId,
        data: data,
        status: _statusToFirestore(statusFor(data.projectId)),
        sampleWeights: List<double>.from(
          projectSampleWeights[data.projectId] ?? const <double>[],
        ),
        sampleGroups: List<List<double>>.generate(3, (index) {
          final groups =
              projectSampleGroups[data.projectId] ?? const <List<double>>[];
          return index < groups.length
              ? List<double>.from(groups[index])
              : <double>[];
        }),
        sampleGroupBluetoothFlags: List<List<bool>>.generate(3, (index) {
          final flags =
              projectSampleGroupBluetoothFlags[data.projectId] ??
              const <List<bool>>[];
          return index < flags.length
              ? List<bool>.from(flags[index])
              : <bool>[];
        }),
        docDistributions: List<Map<String, dynamic>>.from(
          projectDocDistributions[data.projectId] ??
              const <Map<String, dynamic>>[],
        ),
        attachmentUrls: List<String>.from(
          projectAttachmentUrls[data.projectId] ?? const <String>[],
        ),
        sampleInputBluetooth:
            projectSampleBluetoothInputs[data.projectId] ?? false,
        distributionBluetooth:
            projectDistributionBluetoothInputs[data.projectId] ?? false,
        boxHeaviest: (projectBoxValues[data.projectId]?['heaviest'] ?? ''),
        boxAverage: (projectBoxValues[data.projectId]?['average'] ?? ''),
        boxLightest: (projectBoxValues[data.projectId]?['lightest'] ?? ''),
        dietPens: {
          for (final entry
              in (projectDietPenSelections[data.projectId] ??
                      const <int, List<int>>{})
                  .entries)
            entry.key: List<int>.from(entry.value),
        },
        dietInputs: {
          for (final entry
              in (projectDietInputValues[data.projectId] ??
                      const <int, Map<String, String>>{})
                  .entries)
            entry.key: Map<String, String>.from(entry.value),
        },
      );

      if (savedProjectId != data.projectId) {
        debugPrint(
          'BroilerController: Migrating project ID from ${data.projectId} to $savedProjectId',
        );
        _migratedIdMap[data.projectId] = savedProjectId;

        final index = projects.indexWhere(
          (item) => item.projectId == projectId,
        );
        if (index >= 0) {
          projects[index] = data.copyWith(projectId: savedProjectId);
          projects.refresh();
        }

        projectStatuses[savedProjectId] =
            projectStatuses.remove(projectId) ?? BroilerWorkflowStatus.drafted;
        projectLastOpenedSteps[savedProjectId] =
            projectLastOpenedSteps.remove(projectId) ?? 0;
        projectSampleWeights[savedProjectId] =
            projectSampleWeights.remove(projectId) ?? const <double>[];
        projectSampleGroups[savedProjectId] =
            projectSampleGroups.remove(projectId) ??
            const <List<double>>[<double>[], <double>[], <double>[]];
        projectSampleGroupBluetoothFlags[savedProjectId] =
            projectSampleGroupBluetoothFlags.remove(projectId) ??
            const <List<bool>>[<bool>[], <bool>[], <bool>[]];
        projectDocDistributions[savedProjectId] =
            projectDocDistributions.remove(projectId) ??
            const <Map<String, dynamic>>[];
        projectAttachmentUrls[savedProjectId] =
            projectAttachmentUrls.remove(projectId) ?? const <String>[];
        projectBoxValues[savedProjectId] =
            projectBoxValues.remove(projectId) ??
            const <String, String>{
              'heaviest': '',
              'average': '',
              'lightest': '',
            };
        projectBluetoothInputs[savedProjectId] =
            projectBluetoothInputs.remove(projectId) ?? false;
        projectSampleBluetoothInputs[savedProjectId] =
            projectSampleBluetoothInputs.remove(projectId) ?? false;
        projectDistributionBluetoothInputs[savedProjectId] =
            projectDistributionBluetoothInputs.remove(projectId) ?? false;
        projectDietPenSelections[savedProjectId] =
            projectDietPenSelections.remove(projectId) ??
            const <int, List<int>>{};
        projectDietInputValues[savedProjectId] =
            projectDietInputValues.remove(projectId) ??
            const <int, Map<String, String>>{};

        if (selectedProjectId.value == projectId ||
            (selectedProjectId.value == null && projectId.isEmpty)) {
          selectedProjectId.value = savedProjectId;
        }
      }

      return true;
    } catch (error) {
      debugPrint('Firestore sync failed for $projectId: $error');
      return false;
    }
  }

  Map<int, List<int>> _parseDietPens(dynamic raw) {
    if (raw is! Map) return <int, List<int>>{};
    final parsed = <int, List<int>>{};
    for (final entry in raw.entries) {
      final key = int.tryParse('${entry.key}');
      if (key == null) continue;
      final value = entry.value;
      if (value is! List) continue;
      parsed[key] =
          value
              .map((item) => item is int ? item : int.tryParse('$item'))
              .whereType<int>()
              .toList()
            ..sort();
    }
    return parsed;
  }

  Map<int, Map<String, String>> _parseDietInputs(dynamic raw) {
    if (raw is! Map) return <int, Map<String, String>>{};
    final parsed = <int, Map<String, String>>{};
    for (final entry in raw.entries) {
      final key = int.tryParse('${entry.key}');
      if (key == null || entry.value is! Map) continue;
      final item = Map<String, dynamic>.from(entry.value as Map);
      parsed[key] = {
        'preStarter': (item['preStarter'] ?? '').toString(),
        'starter': (item['starter'] ?? '').toString(),
        'finisher': (item['finisher'] ?? '').toString(),
        'remarks': (item['remarks'] ?? '').toString(),
      };
    }
    return parsed;
  }

  List<double> _parseSampleWeights(dynamic raw) {
    if (raw is! List) return const <double>[];
    return raw
        .map((item) => item is num ? item.toDouble() : double.tryParse('$item'))
        .whereType<double>()
        .toList();
  }

  List<List<double>> _parseSampleGroups(dynamic raw) {
    if (raw is! Map) {
      return const <List<double>>[<double>[], <double>[], <double>[]];
    }
    return List<List<double>>.generate(3, (index) {
      final listRaw = raw['$index'];
      if (listRaw is! List) return <double>[];
      return listRaw
          .map(
            (item) => item is num ? item.toDouble() : double.tryParse('$item'),
          )
          .whereType<double>()
          .toList();
    });
  }

  List<List<bool>> _parseSampleGroupBluetoothFlags(
    dynamic raw,
    List<List<double>> sampleGroups,
  ) {
    if (raw is! Map) {
      return List<List<bool>>.generate(
        3,
        (index) => List<bool>.filled(
          index < sampleGroups.length ? sampleGroups[index].length : 0,
          false,
        ),
      );
    }

    return List<List<bool>>.generate(3, (index) {
      final listRaw = raw['$index'];
      final valuesLength = index < sampleGroups.length
          ? sampleGroups[index].length
          : 0;
      if (listRaw is! List) {
        return List<bool>.filled(valuesLength, false);
      }

      final parsed = listRaw.map((item) {
        if (item is bool) return item;
        final text = '$item'.trim().toLowerCase();
        return text == 'yes' || text == 'true';
      }).toList();

      if (parsed.length < valuesLength) {
        parsed.addAll(List<bool>.filled(valuesLength - parsed.length, false));
      } else if (parsed.length > valuesLength) {
        parsed.removeRange(valuesLength, parsed.length);
      }
      return parsed;
    });
  }

  List<Map<String, dynamic>> _parseDocDistributions(dynamic raw) {
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<String> _parseAttachmentUrls(dynamic raw) {
    if (raw is! List) return const <String>[];
    return raw
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<void> hydrateStepperDataFromFirestore(String projectId) async {
    final userId = _sessionController.userId.value;
    if (userId.isEmpty) return;

    try {
      final record = await _firestoreService.getProjectRecord(
        userId: userId,
        projectId: projectId,
      );
      if (record == null) return;

      final sampleWeights = _parseSampleWeights(record['sample_weights']);
      final sampleGroups = _parseSampleGroups(record['sample_groups']);
      final sampleGroupBluetoothFlags = _parseSampleGroupBluetoothFlags(
        record['sample_groups_bluetooth'],
        sampleGroups,
      );
      final docDistributions = _parseDocDistributions(
        record['doc_distributions'],
      );
      final attachmentUrls = _parseAttachmentUrls(record['attachment_urls']);
      final dietPens = _parseDietPens(record['diet_pen_selections']);
      final dietInputs = _parseDietInputs(record['diet_input_values']);

      projectSampleWeights[projectId] = sampleWeights;
      projectSampleGroups[projectId] = sampleGroups;
      projectSampleGroupBluetoothFlags[projectId] = sampleGroupBluetoothFlags;
      projectDocDistributions[projectId] = docDistributions;
      projectAttachmentUrls[projectId] = attachmentUrls;
      projectBoxValues[projectId] = {
        'heaviest': (record['box_heaviest'] ?? '').toString(),
        'average': (record['box_average'] ?? '').toString(),
        'lightest': (record['box_lightest'] ?? '').toString(),
      };
      final rawBluetooth = (record['is_bluetooth'] ?? '').toString();
      projectBluetoothInputs[projectId] =
          rawBluetooth.trim().toLowerCase() == 'yes';
      final rawSampleBluetooth =
          (record['sample_is_bluetooth'] ?? record['is_bluetooth'] ?? '')
              .toString();
      projectSampleBluetoothInputs[projectId] =
          rawSampleBluetooth.trim().toLowerCase() == 'yes';
      final rawDistributionBluetooth =
          (record['distribution_is_bluetooth'] ?? record['is_bluetooth'] ?? '')
              .toString();
      projectDistributionBluetoothInputs[projectId] =
          rawDistributionBluetooth.trim().toLowerCase() == 'yes';
      projectDietPenSelections[projectId] = dietPens;
      projectDietInputValues[projectId] = dietInputs;

      final dietMappingController = Get.isRegistered<DietMappingController>()
          ? Get.find<DietMappingController>()
          : Get.put(DietMappingController(), permanent: true);

      if (selectedProjectId.value == projectId) {
        dietMappingController.dietPenSelections.assignAll(dietPens);
        dietMappingController.loadDietInputValues(dietInputs);
        if ((dietController.text.trim().isNotEmpty) &&
            (replicationController.text.trim().isNotEmpty)) {
          dietMappingController.syncFromValues(
            diet: dietController.text,
            replication: replicationController.text,
          );
        }
      }
    } catch (error) {
      debugPrint('Failed to hydrate stepper data for $projectId: $error');
    }
  }

  Future<void> markDrafted(String projectId, {int step = 1}) {
    final actualId = _migratedIdMap[projectId] ?? projectId;

    projectStatuses[actualId] = BroilerWorkflowStatus.drafted;
    projectStatuses.refresh();
    updateLastOpenedStep(actualId, step);
    _notifyStatusChange();
    
    // Update directly to Firestore to bypass sync queue delay
    _firestoreService.updateProjectStatus(
      userId: _sessionController.userId.value,
      projectId: actualId,
      status: _statusToFirestore(BroilerWorkflowStatus.drafted),
    );

    _enqueueProjectSync(actualId);

    HistoryController.log(
      title: 'Project Drafted',
      description: 'Project was moved to draft status.',
      type: ActivityType.project,
      projectId: actualId,
    );

    return Future<void>.value();
  }

  Future<void> markInProgress(String projectId) async {
    final actualId = _migratedIdMap[projectId] ?? projectId;

    projectStatuses[actualId] = BroilerWorkflowStatus.inProgress;
    projectStatuses.refresh();
    _notifyStatusChange();
    updateLastOpenedStep(actualId, 2);

    // Update directly to Firestore to bypass sync queue delay
    _firestoreService.updateProjectStatus(
      userId: _sessionController.userId.value,
      projectId: actualId,
      status: _statusToFirestore(BroilerWorkflowStatus.inProgress),
    );

    _enqueueProjectSync(actualId);

    HistoryController.log(
      title: 'Project Finalized',
      description: 'Project is now active and ready for monitoring.',
      type: ActivityType.project,
      projectId: actualId,
    );
  }

  Future<void> markCompleted(String projectId) {
    final actualId = _migratedIdMap[projectId] ?? projectId;

    projectStatuses[actualId] = BroilerWorkflowStatus.completed;

    final index = projects.indexWhere((item) => item.projectId == actualId);
    if (index != -1) {
      final oldProject = projects[index];
      projects[index] = oldProject.copyWith();
    }

    projects.refresh();
    projectStatuses.refresh();
    _notifyStatusChange();

    // Update directly to Firestore to bypass sync queue delay
    _firestoreService.updateProjectStatus(
      userId: _sessionController.userId.value,
      projectId: actualId,
      status: _statusToFirestore(BroilerWorkflowStatus.completed),
    );

    _enqueueProjectSync(actualId);

    HistoryController.log(
      title: 'Project Completed',
      description: 'Project monitoring is finished and marked as completed.',
      type: ActivityType.project,
      projectId: actualId,
    );

    return Future<void>.value();
  }

  void updateLastOpenedStep(String projectId, int step) {
    projectLastOpenedSteps[projectId] = step.clamp(0, 2);
  }

  Future<bool> saveStepperData({
    required String projectId,
    required List<double> sampleWeights,
    required List<List<double>> sampleGroups,
    required List<List<bool>> sampleBluetoothFlags,
    required List<Map<String, dynamic>> docDistributions,
    required List<String> attachmentUrls,
    required bool sampleInputBluetooth,
    required bool distributionBluetooth,
    required String boxHeaviest,
    required String boxAverage,
    required String boxLightest,
    required Map<int, List<int>> dietPens,
    required Map<int, Map<String, String>> dietInputs,
  }) {
    projectSampleWeights[projectId] = List<double>.from(sampleWeights);
    projectSampleGroups[projectId] = List<List<double>>.generate(
      3,
      (index) => index < sampleGroups.length
          ? List<double>.from(sampleGroups[index])
          : <double>[],
    );
    projectSampleGroupBluetoothFlags[projectId] = List<List<bool>>.generate(
      3,
      (index) => index < sampleBluetoothFlags.length
          ? List<bool>.from(sampleBluetoothFlags[index])
          : <bool>[],
    );
    projectDocDistributions[projectId] = List<Map<String, dynamic>>.from(
      docDistributions,
    );

    final normalizedAttachmentUrls = attachmentUrls
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    // Defensive logic: prevent accidental data loss
    final previousUrls = projectAttachmentUrls[projectId];
    if (normalizedAttachmentUrls.isEmpty &&
        (previousUrls?.isNotEmpty ?? false)) {
      debugPrint(
        'BroilerController: PROTECTED SYNC - Preserving ${previousUrls!.length} attachments for $projectId (prevented empty list overwrite).',
      );
    } else {
      if (previousUrls != null &&
          previousUrls.isNotEmpty &&
          normalizedAttachmentUrls.isEmpty) {
        debugPrint(
          'BroilerController: INTENTIONAL CLEAR - Project $projectId attachments cleared.',
        );
      }
      projectAttachmentUrls[projectId] = normalizedAttachmentUrls;
    }
    projectSampleBluetoothInputs[projectId] = sampleInputBluetooth;
    projectDistributionBluetoothInputs[projectId] = distributionBluetooth;
    projectBluetoothInputs[projectId] =
        sampleInputBluetooth || distributionBluetooth;
    projectBoxValues[projectId] = {
      'heaviest': boxHeaviest,
      'average': boxAverage,
      'lightest': boxLightest,
    };
    projectDietPenSelections[projectId] = {
      for (final entry in dietPens.entries)
        entry.key: List<int>.from(entry.value),
    };
    projectDietInputValues[projectId] = {
      for (final entry in dietInputs.entries)
        entry.key: Map<String, String>.from(entry.value),
    };

    debugPrint(
      'BroilerController: Stepper data updated for $projectId. Attachments: ${attachmentUrls.length}',
    );
    _enqueueProjectSync(projectId);
    return Future<bool>.value(true);
  }

  void clearForm() {
    projectNameController.clear();
    trialDateController.clear();
    trialHouseController.clear();
    strainController.clear();
    hatcheryController.clear();
    breedingFarmController.clear();
    boxBatchCodeController.clear();
    selectorController.clear();
    docInDateController.clear();
    docWeightController.clear();
    weighing3WeeksController.clear();
    weighing5WeeksController.clear();
    numberOfBirdsController.clear();
    dietController.clear();
    replicationController.clear();

    selectedProjectId.value = null;
    selectedProjectName.value = null;
    selectedTrialHouse.value = null;
    selectedStrain.value = null;
    selectedHatchery.value = null;
    selectedDocInDate.value = null;
  }

  Future<bool> saveProject() async {
    final projectName = projectNameController.text.trim();
    final trialDate = trialDateController.text.trim();
    final docWeight = docWeightController.text.trim();
    final docInDate = docInDateController.text.trim();
    final trialHouse = trialHouseController.text.trim();
    final diet = dietController.text.trim();
    final replication = replicationController.text.trim();

    if (projectName.isEmpty) {
      Get.snackbar('Project Name / Chick Cycle', 'This field is required');
      return false;
    }
    if (trialDate.isEmpty) {
      Get.snackbar('Date Trial', 'This field is required');
      return false;
    }
    if (docWeight.isEmpty) {
      Get.snackbar('DOC Weight (Kg)', 'This field is required');
      return false;
    }
    if (docInDate.isEmpty) {
      Get.snackbar('DOC In', 'This field is required');
      return false;
    }
    if (trialHouse.isEmpty) {
      Get.snackbar('Map of Trial House', 'This field is required');
      return false;
    }
    if (diet.isEmpty) {
      Get.snackbar('Diet', 'This field is required');
      return false;
    }
    if (replication.isEmpty) {
      Get.snackbar('Replication', 'This field is required');
      return false;
    }

    final replicationNumber = (int.tryParse(replication) ?? 1).clamp(1, 9999);
    final selectedId = selectedProjectId.value?.trim() ?? '';
    final currentProjectId = selectedId.isNotEmpty
        ? selectedId
        : _createLocalProjectId();

    if (hasDuplicateDraftedProjectName(
      projectName: projectName,
      excludeProjectId: currentProjectId,
    )) {
      Get.snackbar(
        'Duplicate Name',
        'Project name already exists in Drafted status.',
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
      return false;
    }

    final data = BroilerProjectData(
      projectId: currentProjectId,
      projectName: projectName,
      trialDate: trialDate,
      trialHouse: trialHouse,
      strain: strainController.text.trim(),
      hatchery: hatcheryController.text.trim(),
      breedingFarm: breedingFarmController.text.trim(),
      boxBatchCode: boxBatchCodeController.text.trim(),
      selector: selectorController.text.trim(),
      docInDate: docInDate,
      docWeight: docWeight,
      weighing3Weeks: weighing3WeeksController.text.trim(),
      weighing5Weeks: weighing5WeeksController.text.trim(),
      numberOfBirds: numberOfBirdsController.text.trim(),
      diet: diet,
      replication: replication,
      dietReplication: replicationNumber,
    );

    final existingIndex = projects.indexWhere(
      (item) => item.projectId == currentProjectId,
    );
    if (existingIndex >= 0) {
      projects[existingIndex] = data;
      HistoryController.log(
        title: 'Project Updated',
        description: 'Project "$projectName" has been updated.',
        type: ActivityType.project,
        projectId: currentProjectId,
      );
    } else {
      projects.add(data);
      HistoryController.log(
        title: 'Project Created',
        description: 'New project "$projectName" has been drafted.',
        type: ActivityType.project,
        projectId: currentProjectId,
      );
    }

    final dietMappingController = Get.isRegistered<DietMappingController>()
        ? Get.find<DietMappingController>()
        : Get.put(DietMappingController(), permanent: true);
    dietMappingController.syncFromValues(diet: diet, replication: replication);

    selectedProjectId.value = currentProjectId;
    selectedProjectName.value = projectName;
    _enqueueProjectSync(currentProjectId, showErrorSnackbar: true);
    Get.snackbar('Draft', 'Project saved to drafts');

    return true;
  }

  Future<bool> saveProjectAsDraft() async {
    final projectName = projectNameController.text.trim();
    if (projectName.isEmpty) return false;

    final replication = replicationController.text.trim();
    final replicationNumber = (int.tryParse(replication) ?? 1).clamp(1, 9999);
    final selectedId = selectedProjectId.value?.trim() ?? '';
    final currentProjectId = selectedId.isNotEmpty
        ? selectedId
        : _createLocalProjectId();

    final data = BroilerProjectData(
      projectId: currentProjectId,
      projectName: projectName,
      trialDate: trialDateController.text.trim(),
      trialHouse: trialHouseController.text.trim(),
      strain: strainController.text.trim(),
      hatchery: hatcheryController.text.trim(),
      breedingFarm: breedingFarmController.text.trim(),
      boxBatchCode: boxBatchCodeController.text.trim(),
      selector: selectorController.text.trim(),
      docInDate: docInDateController.text.trim(),
      docWeight: docWeightController.text.trim(),
      weighing3Weeks: weighing3WeeksController.text.trim(),
      weighing5Weeks: weighing5WeeksController.text.trim(),
      numberOfBirds: numberOfBirdsController.text.trim(),
      diet: dietController.text.trim(),
      replication: replication,
      dietReplication: replicationNumber,
    );

    if (hasDuplicateDraftedProjectName(
      projectName: projectName,
      excludeProjectId: currentProjectId,
    )) {
      return false;
    }

    final existingIndex = projects.indexWhere(
      (item) => item.projectId == currentProjectId,
    );
    if (existingIndex >= 0) {
      projects[existingIndex] = data;
    } else {
      projects.add(data);
    }

    final dietMappingController = Get.isRegistered<DietMappingController>()
        ? Get.find<DietMappingController>()
        : Get.put(DietMappingController(), permanent: true);
    dietMappingController.syncFromValues(
      diet: dietController.text.trim(),
      replication: replication,
    );

    selectedProjectId.value = currentProjectId;
    selectedProjectName.value = projectName;
    _enqueueProjectSync(currentProjectId, showErrorSnackbar: false);
    return true;
  }

  Future<bool> deleteDraftedProject(String projectId) async {
    if (statusFor(projectId) != BroilerWorkflowStatus.drafted) {
      return false;
    }

    final userId = _sessionController.userId.value;
    if (userId.isEmpty) return false;

    try {
      await _firestoreService.deleteProjectRecord(
        userId: userId,
        projectId: projectId,
      );
    } catch (error) {
      debugPrint('Failed to delete project $projectId: $error');
      Get.snackbar('Delete Failed', 'Project could not be deleted');
      return false;
    }

    projects.removeWhere((item) => item.projectId == projectId);
    projectStatuses.remove(projectId);
    projectLastOpenedSteps.remove(projectId);
    projectSampleWeights.remove(projectId);
    projectSampleGroups.remove(projectId);
    projectDocDistributions.remove(projectId);
    projectAttachmentUrls.remove(projectId);
    projectBoxValues.remove(projectId);
    projectDietPenSelections.remove(projectId);
    projectDietInputValues.remove(projectId);

    if (selectedProjectId.value == projectId) {
      clearForm();
    }

    HistoryController.log(
      title: 'Project Deleted',
      description: 'Project has been removed.',
      type: ActivityType.project,
    );

    Get.snackbar('Deleted', 'Draft project removed');
    return true;
  }

  @override
  void onClose() {
    _statusSubscription?.cancel();
    _projectsSubscription?.cancel();
    _strainsSubscription?.cancel();
    _hatcheriesSubscription?.cancel();
    _trialHousesSubscription?.cancel();
    projectNameController.dispose();
    trialDateController.dispose();
    trialHouseController.dispose();
    strainController.dispose();
    hatcheryController.dispose();
    breedingFarmController.dispose();
    boxBatchCodeController.dispose();
    selectorController.dispose();
    docInDateController.dispose();
    docWeightController.dispose();
    weighing3WeeksController.dispose();
    weighing5WeeksController.dispose();
    numberOfBirdsController.dispose();
    dietController.dispose();
    replicationController.dispose();
    super.onClose();
  }
}
