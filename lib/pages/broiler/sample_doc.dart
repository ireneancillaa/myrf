import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'doc_distribution_input_page.dart';
import 'sample_doc_input_page.dart';

class SampleDocSection extends StatefulWidget {
  final bool readOnly;
  final TextEditingController boxHeaviestController;
  final TextEditingController boxAverageController;
  final TextEditingController boxLightestController;
  final List<double> docWeights;
  final Function(List<double>) onDocWeightsChanged;
  final List<List<double>> sampleGroups;
  final Function(List<List<double>>) onSampleGroupsChanged;
  final List<List<bool>> sampleBluetoothFlags;
  final Function(List<List<bool>>) onSampleBluetoothFlagsChanged;
  final List<Map<String, dynamic>> docDistributions;
  final Function(List<Map<String, dynamic>>) onDocDistributionsChanged;
  final List<String> initialAttachmentUrls;
  final Function(List<String>) onAttachmentUrlsChanged;
  final String? projectId;
  final bool sampleInputBluetooth;
  final Function(bool) onSampleInputBluetoothChanged;
  final bool distributionBluetooth;
  final Function(bool) onDistributionBluetoothChanged;
  final int dietReplication;
  final int totalPens;
  final Function(bool)? onUploadingStatusChanged;

  const SampleDocSection({
    super.key,
    this.readOnly = false,
    required this.boxHeaviestController,
    required this.boxAverageController,
    required this.boxLightestController,
    required this.docWeights,
    required this.onDocWeightsChanged,
    required this.sampleGroups,
    required this.onSampleGroupsChanged,
    required this.sampleBluetoothFlags,
    required this.onSampleBluetoothFlagsChanged,
    required this.docDistributions,
    required this.onDocDistributionsChanged,
    this.initialAttachmentUrls = const <String>[],
    required this.onAttachmentUrlsChanged,
    this.projectId,
    required this.sampleInputBluetooth,
    required this.onSampleInputBluetoothChanged,
    required this.distributionBluetooth,
    required this.onDistributionBluetoothChanged,
    required this.dietReplication,
    required this.totalPens,
    this.onUploadingStatusChanged,
  });

  @override
  State<SampleDocSection> createState() => _SampleDocSectionState();
}

class _SampleDocSectionState extends State<SampleDocSection> {
  static const double _sampleCardMinHeight = 70;
  static const Color _badgeTextColor = Color(0xFF22C55E);
  static const Color _badgeBorderColor = Color(0xFF86EFAC);
  static const Color _badgeBackgroundColor = Color(0xFFECFDF3);
  static const Color _badgeEmptyTextColor = Color(0xFF6F6F6F);

  final List<List<double>> _sampleDocWeights = [[], [], []];
  final List<List<bool>> _sampleDocBluetoothFlags = [[], [], []];
  final List<DateTime?> _sampleUpdatedAt = [null, null, null];
  late bool _sampleInputBluetooth;
  late bool _distributionBluetooth;
  final ImagePicker _imagePicker = ImagePicker();
  final List<_AttachmentItem> _attachments = [_AttachmentItem.empty()];

  @override
  void initState() {
    super.initState();
    _sampleInputBluetooth = widget.sampleInputBluetooth;
    _distributionBluetooth = widget.distributionBluetooth;
    _initializeAttachments();
    final hasGroupedData = widget.sampleGroups.any((item) => item.isNotEmpty);
    if (hasGroupedData) {
      for (int i = 0; i < _sampleDocWeights.length; i++) {
        _sampleDocWeights[i].addAll(
          i < widget.sampleGroups.length
              ? List<double>.from(widget.sampleGroups[i])
              : <double>[],
        );
        _sampleDocBluetoothFlags[i] = i < widget.sampleBluetoothFlags.length
            ? List<bool>.from(widget.sampleBluetoothFlags[i])
            : List<bool>.filled(_sampleDocWeights[i].length, false);
        if (_sampleDocBluetoothFlags[i].length < _sampleDocWeights[i].length) {
          _sampleDocBluetoothFlags[i].addAll(
            List<bool>.filled(
              _sampleDocWeights[i].length - _sampleDocBluetoothFlags[i].length,
              false,
            ),
          );
        }
        if (_sampleDocWeights[i].isNotEmpty) {
          _sampleUpdatedAt[i] = DateTime.now();
        }
      }
      return;
    }

    if (widget.docWeights.isNotEmpty) {
      for (int i = 0; i < widget.docWeights.length && i < 3; i++) {
        _sampleDocWeights[i].add(widget.docWeights[i]);
        _sampleDocBluetoothFlags[i].add(false);
        if (widget.docWeights[i] > 0) {
          _sampleUpdatedAt[i] = DateTime.now();
        }
      }
    }
  }

  @override
  void didUpdateWidget(covariant SampleDocSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 1. Sync Bluetooth Settings
    if (oldWidget.sampleInputBluetooth != widget.sampleInputBluetooth) {
      setState(() => _sampleInputBluetooth = widget.sampleInputBluetooth);
    }
    if (oldWidget.distributionBluetooth != widget.distributionBluetooth) {
      setState(() => _distributionBluetooth = widget.distributionBluetooth);
    }

    // 2. Sync Sample Groups and Bluetooth Flags (Weights state)
    final oldGroupsSummary =
        oldWidget.sampleGroups.map((g) => g.join(',')).join('|');
    final newGroupsSummary =
        widget.sampleGroups.map((g) => g.join(',')).join('|');
    final oldFlagsSummary =
        oldWidget.sampleBluetoothFlags.map((f) => f.join(',')).join('|');
    final newFlagsSummary =
        widget.sampleBluetoothFlags.map((f) => f.join(',')).join('|');

    if (oldGroupsSummary != newGroupsSummary ||
        oldFlagsSummary != newFlagsSummary) {
      setState(() {
        for (int i = 0; i < 3; i++) {
          // Weights
          _sampleDocWeights[i]
            ..clear()
            ..addAll(
              i < widget.sampleGroups.length
                  ? List<double>.from(widget.sampleGroups[i])
                  : <double>[],
            );

          // Update timestamp if data just arrived
          if (_sampleDocWeights[i].isNotEmpty && _sampleUpdatedAt[i] == null) {
            _sampleUpdatedAt[i] = DateTime.now();
          } else if (_sampleDocWeights[i].isEmpty) {
            _sampleUpdatedAt[i] = null;
          }

          // Bluetooth Flags
          _sampleDocBluetoothFlags[i]
            ..clear()
            ..addAll(
              i < widget.sampleBluetoothFlags.length
                  ? List<bool>.from(widget.sampleBluetoothFlags[i])
                  : List<bool>.filled(_sampleDocWeights[i].length, false),
            );

          // Correct flag list length if mismatched
          if (_sampleDocBluetoothFlags[i].length <
              _sampleDocWeights[i].length) {
            _sampleDocBluetoothFlags[i].addAll(
              List<bool>.filled(
                _sampleDocWeights[i].length -
                    _sampleDocBluetoothFlags[i].length,
                false,
              ),
            );
          }
        }
      });
    }

    // 3. Sync Attachment URLs
    final oldUrls = oldWidget.initialAttachmentUrls
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final newUrls = widget.initialAttachmentUrls
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (oldUrls.join('|') != newUrls.join('|')) {
      final hasLocalOrUploading = _attachments.any(
        (item) => item.file != null || item.isUploading,
      );
      
      // Only sync from parent if we don't have local unsaved changes
      if (!hasLocalOrUploading) {
        setState(() {
          _attachments
            ..clear()
            ..addAll(
              newUrls.isEmpty
                  ? [_AttachmentItem.empty()]
                  : newUrls.map((url) => _AttachmentItem.remote(url)),
            );
        });
      } else {
        // Log that we skipped sync to avoid data loss
        debugPrint('SampleDocSection: Skipping sync from parent to avoid overwriting local uploads');
      }
    }
  }

  void _initializeAttachments() {
    final urls = widget.initialAttachmentUrls
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (urls.isEmpty) return;

    _attachments
      ..clear()
      ..addAll(urls.map((url) => _AttachmentItem.remote(url)));
  }

  void _notifyAttachmentUrlsChanged() {
    final urls = _attachments
        .map((item) => item.downloadUrl?.trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
    
    // Safety check: if we have attachments but urls is empty because all are still uploading,
    // don't notify yet to avoid clearing the controller's state.
    final hasActiveAttachments = _attachments.any((item) => item.hasPreview);
    if (hasActiveAttachments && urls.isEmpty && _uploadingCount > 0) {
      debugPrint('SampleDocSection: Delaying notification until uploads finish');
      return;
    }
    
    widget.onAttachmentUrlsChanged(urls);
  }

  void _updateAllDocWeights() {
    final allWeights = <double>[];
    for (final sample in _sampleDocWeights) {
      allWeights.addAll(sample);
    }
    widget.onDocWeightsChanged(allWeights);
    widget.onSampleGroupsChanged(
      _sampleDocWeights.map((item) => List<double>.from(item)).toList(),
    );
    widget.onSampleBluetoothFlagsChanged(
      _sampleDocBluetoothFlags.map((item) => List<bool>.from(item)).toList(),
    );
  }

  void _showImagePreview({
    required String url,
    required bool isLocal,
    File? file,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                maxScale: 5.0,
                child: _buildImageWidget(
                  url,
                  isLocal: isLocal,
                  file: file,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(
    String url, {
    required bool isLocal,
    File? file,
    required BoxFit fit,
  }) {
    if (isLocal && file != null) {
      return Image.file(file, fit: fit);
    }

    if (url.startsWith('data:image')) {
      try {
        final base64Data = url.split(',').last;
        return Image.memory(
          base64Decode(base64Data),
          fit: fit,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
        );
      } catch (e) {
        return const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        );
      }
    }

    return Image.network(
      url,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      },
    );
  }

  Future<void> _pickAttachmentFromGallery(int index) async {
    int targetIndex = index;
    try {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 20,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (pickedImage == null) return;

      if (index < 0) {
        if (_attachments.length >= 10) return;

        if (_attachments.isEmpty || _attachments.last.hasPreview) {
          setState(() {
            _attachments.add(_AttachmentItem.empty());
          });
        }
        targetIndex = _attachments.length - 1;
      }

      if (targetIndex < 0 || targetIndex >= _attachments.length) return;

      setState(() {
        _attachments[targetIndex] = _AttachmentItem(
          file: pickedImage,
          downloadUrl: _attachments[targetIndex].downloadUrl,
          isUploading: true,
        );
      });

      _notifyUploadingStatus(true);
      final uploadedUrl = await _uploadAttachmentToFirebase(pickedImage);
      if (!mounted || targetIndex < 0 || targetIndex >= _attachments.length) {
        _notifyUploadingStatus(false);
        return;
      }

      setState(() {
        _attachments[targetIndex] = _AttachmentItem(
          file: pickedImage,
          downloadUrl: uploadedUrl,
          isUploading: false,
        );
      });
      _notifyUploadingStatus(false);
      _notifyAttachmentUrlsChanged();
    } catch (e) {
      _notifyUploadingStatus(false);
      
      var errorMessage = 'Upload failed';
      var errorCode = 'unknown';

      if (e is FirebaseException) {
        errorCode = e.code;
        errorMessage = 'Upload failed: [${e.code}] ${e.message}';
      } else {
        errorMessage = 'Error: $e';
      }

      debugPrint('SampleDocSection: CRITICAL UPLOAD ERROR');
      debugPrint(' - Code: $errorCode');
      debugPrint(' - Message: $e');
      debugPrint(' - Project ID: ${widget.projectId}');
      
      if (targetIndex >= 0 && targetIndex < _attachments.length) {
        setState(() {
          _attachments[targetIndex] = _attachments[targetIndex].copyWith(
            isUploading: false,
          );
        });
      }
      
      _notifyAttachmentUrlsChanged();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 10), // Longer duration for debugging
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  int _uploadingCount = 0;
  void _notifyUploadingStatus(bool isStarting) {
    if (isStarting) {
      _uploadingCount++;
    } else {
      _uploadingCount = (_uploadingCount - 1).clamp(0, 10);
    }
    widget.onUploadingStatusChanged?.call(_uploadingCount > 0);
  }

  void _addAttachmentField() {
    if (_attachments.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 10 attachments allowed'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    setState(() {
      _attachments.add(_AttachmentItem.empty());
    });
  }

  Future<String> _uploadAttachmentToFirebase(XFile pickedImage) async {
    try {
      final imageFile = File(pickedImage.path);
      final bytes = await imageFile.readAsBytes();
      
      // Convert to Base64 String with Data URI prefix
      final base64String = base64Encode(bytes);
      final dataUri = 'data:image/jpeg;base64,$base64String';
      
      debugPrint('SampleDocSection: Image converted to Base64 (Size: ${bytes.length} bytes)');
      
      // Artificial delay to simulate processing but much faster than real upload
      await Future.delayed(const Duration(milliseconds: 300));
      
      return dataUri;
    } catch (e) {
      debugPrint('SampleDocSection: Error converting to Base64: $e');
      rethrow;
    }
  }

  Future<bool> _confirmRemoveAttachmentField(int index) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFDC2626),
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Delete Attachment Box?',
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Attachment box ${index + 1} will be removed. Continue?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 15,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFD1D5DB)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              foregroundColor: const Color(0xFF374151),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Delete',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ) ??
        false;

    if (!confirmed) return false;

    setState(() {
      if (index < 0 || index >= _attachments.length) return;
      _attachments.removeAt(index);
      if (_attachments.isEmpty) {
        _attachments.add(_AttachmentItem.empty());
      }
    });
    _notifyAttachmentUrlsChanged();

    return true;
  }

  Future<void> _openSampleInputPage(int sampleIndex) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => SampleDocInputPage(
          readOnly: widget.readOnly,
          sampleNumber: sampleIndex + 1,
          initialWeights: List<double>.from(_sampleDocWeights[sampleIndex]),
          initialBluetoothFlags: List<bool>.from(
            _sampleDocBluetoothFlags[sampleIndex],
          ),
        ),
      ),
    );

    if (result == null) return;

    final valuesRaw = result['values'];
    final values = valuesRaw is List
        ? valuesRaw
              .map(
                (item) =>
                    item is num ? item.toDouble() : double.tryParse('$item'),
              )
              .whereType<double>()
              .toList()
        : <double>[];
    final flagsRaw = result['bluetoothFlags'];
    final bluetoothFlags = flagsRaw is List
        ? flagsRaw.map((item) => item == true).toList()
        : <bool>[];

    setState(() {
      _sampleDocWeights[sampleIndex]
        ..clear()
        ..addAll(values);
      _sampleDocBluetoothFlags[sampleIndex]
        ..clear()
        ..addAll(bluetoothFlags);
      if (_sampleDocBluetoothFlags[sampleIndex].length <
          _sampleDocWeights[sampleIndex].length) {
        _sampleDocBluetoothFlags[sampleIndex].addAll(
          List<bool>.filled(
            _sampleDocWeights[sampleIndex].length -
                _sampleDocBluetoothFlags[sampleIndex].length,
            false,
          ),
        );
      }
      _sampleUpdatedAt[sampleIndex] = values.isEmpty ? null : DateTime.now();
      _sampleInputBluetooth = _sampleDocBluetoothFlags.any(
        (group) => group.any((item) => item),
      );
    });
    widget.onSampleInputBluetoothChanged(_sampleInputBluetooth);
    _updateAllDocWeights();
  }

  Future<void> _openDocDistributionInputPage() async {
    final initialValues = _distributionValuesFromState();
    final initialBluetoothFlags = _distributionBluetoothFlagsFromState();
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => DocDistributionInputPage(
          readOnly: widget.readOnly,
          initialValues: initialValues,
          initialBluetoothFlags: initialBluetoothFlags,
          totalPens: widget.totalPens,
        ),
      ),
    );

    if (result == null) return;

    final valuesRaw = result['values'];
    final values = valuesRaw is List
        ? valuesRaw
              .map(
                (item) =>
                    item is num ? item.toDouble() : double.tryParse('$item'),
              )
              .whereType<double>()
              .toList()
        : <double>[];
    final flagsRaw = result['bluetoothFlags'];
    final bluetoothFlags = flagsRaw is List
        ? flagsRaw.map((item) => item == true).toList()
        : <bool>[];

    final now = DateTime.now().toIso8601String();
    final next = <Map<String, dynamic>>[];
    for (int index = 0; index < values.length; index++) {
      final value = values[index];
      if (value <= 0) continue;
      next.add({
        'pen': index + 1,
        'valueKg': value,
        'updatedAt': now,
        'isBluetooth': (index < bluetoothFlags.length && bluetoothFlags[index])
            ? 'yes'
            : 'no',
      });
    }

    _distributionBluetooth = next.any(
      (item) => (item['isBluetooth'] ?? '').toString().toLowerCase() == 'yes',
    );
    widget.onDistributionBluetoothChanged(_distributionBluetooth);
    widget.onDocDistributionsChanged(next);
    setState(() {});
  }

  List<bool> _distributionBluetoothFlagsFromState() {
    int maxPen = 0;
    for (final item in widget.docDistributions) {
      final penRaw = item['pen'];
      final pen = penRaw is int ? penRaw : int.tryParse('$penRaw');
      if (pen != null && pen > maxPen) {
        maxPen = pen;
      }
    }

    if (maxPen <= 0) return <bool>[];
    final flags = List<bool>.filled(maxPen, false);
    for (final item in widget.docDistributions) {
      final penRaw = item['pen'];
      final pen = penRaw is int ? penRaw : int.tryParse('$penRaw');
      if (pen == null || pen < 1 || pen > maxPen) continue;
      final raw = (item['isBluetooth'] ?? '').toString().toLowerCase();
      flags[pen - 1] = raw == 'yes' || raw == 'true';
    }
    return flags;
  }

  List<double> _distributionValuesFromState() {
    int maxPen = 0;
    for (final item in widget.docDistributions) {
      final penRaw = item['pen'];
      final pen = penRaw is int ? penRaw : int.tryParse('$penRaw');
      if (pen != null && pen > maxPen) {
        maxPen = pen;
      }
    }

    final length = maxPen > 0 ? maxPen : 0;
    final values = List<double>.filled(length, 0);

    for (final item in widget.docDistributions) {
      final penRaw = item['pen'];
      final valueRaw = item['valueKg'] ?? item['value'] ?? item['kg'];
      final pen = penRaw is int ? penRaw : int.tryParse('$penRaw');
      final value = valueRaw is num
          ? valueRaw.toDouble()
          : double.tryParse('$valueRaw');

      if (pen == null || value == null || pen < 1 || pen > length) continue;
      values[pen - 1] = value;
    }

    return values;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAttachmentSection(),
            const SizedBox(height: 16),
            const Text(
              'Sample DOC',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF22C55E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Input the amount of DOC arrived at the farm (3 samples required)',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            _buildBoxSummaryRow(),
            const SizedBox(height: 18),
            ...List.generate(3, (index) => _buildSampleStatusCard(index)),
            const SizedBox(height: 28),
            const Text(
              'DOC Distribution',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF22C55E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Distribute DOC to each pen per kg',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            _buildDocDistributionStatusCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentSection() {
    const borderRadius = 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Add Attachment',
                style: TextStyle(
                  fontSize: 20,
                  color: Color(0xFF22C55E),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: _attachments.length < 10 ? _addAttachmentField : null,
              icon: Icon(
                Icons.add_circle_outline,
                color: _attachments.length < 10
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF9CA3AF),
                size: 28,
              ),
              tooltip: 'Add attachment',
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(_attachments.length, (index) {
          final attachment = _attachments[index];
          final hasLocal = attachment.file != null;
          final hasRemote =
              (attachment.downloadUrl?.trim().isNotEmpty ?? false) && !hasLocal;
          final hasPreview = hasLocal || hasRemote;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == _attachments.length - 1 ? 0 : 12,
            ),
            child: Dismissible(
              key: ValueKey('attachment_box_${attachment.hashCode}_$index'),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => _confirmRemoveAttachmentField(index),
              background: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              child: Stack(
                children: [
                  InkWell(
                    onTap: !hasPreview
                        ? () => _pickAttachmentFromGallery(index)
                        : () => _showImagePreview(
                              url: hasRemote ? attachment.downloadUrl! : '',
                              isLocal: hasLocal,
                              file: hasLocal ? File(attachment.file!.path) : null,
                            ),
                    borderRadius: BorderRadius.circular(borderRadius),
                    child: CustomPaint(
                      painter: _DashedRoundedRectPainter(
                        color: const Color(0xFFB8B8B8),
                        strokeWidth: 1,
                        dashWidth: 10,
                        dashGap: 10,
                        radius: borderRadius,
                      ),
                      child: Container(
                        width: double.infinity,
                        height: 230,
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(borderRadius),
                        ),
                        child: !hasPreview
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 72,
                                    color: Color(0xFF6B7280),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Tap to upload from gallery',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF7A7A7A),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    _buildImageWidget(
                                      attachment.downloadUrl ?? '',
                                      isLocal: hasLocal,
                                      file: hasLocal
                                          ? File(attachment.file!.path)
                                          : null,
                                      fit: BoxFit.cover,
                                    ),
                                    if (attachment.isUploading)
                                      Container(
                                        color: const Color(0x77000000),
                                        alignment: Alignment.center,
                                        child: const SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.8,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        color: const Color(0x88000000),
                                        child: Text(
                                          attachment.isUploading
                                              ? 'Uploading...'
                                              : 'Tap to view fullscreen',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                  if (hasPreview && !attachment.isUploading)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: GestureDetector(
                        onTap: () => _pickAttachmentFromGallery(index),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => _confirmRemoveAttachmentField(index),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDocDistributionStatusCard() {
    final hasData = widget.docDistributions.isNotEmpty;
    final totalDistribution = widget.docDistributions.fold<double>(0, (
      sum,
      item,
    ) {
      final rawValue = item['valueKg'] ?? item['value'] ?? item['kg'];
      final value = rawValue is num
          ? rawValue.toDouble()
          : double.tryParse('$rawValue') ?? 0;
      return sum + value;
    });
    final titleColor = hasData
        ? const Color(0xFF22C55E)
        : const Color(0xFF6F6F6F);
    final updatedAt = _resolveDistributionUpdatedAt();
    final updatedAtText = updatedAt == null ? '-' : _formatDateTime(updatedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _openDocDistributionInputPage,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: _sampleCardMinHeight),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasData
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFE0E0E0),
              width: hasData ? 1.4 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: hasData
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF8A8A8A),
                  ),
                  color: hasData ? const Color(0xFF22C55E) : Colors.transparent,
                ),
                child: hasData
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DOC Distribution',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                        color: titleColor,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          updatedAtText,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildWeightBadge(
                totalDistribution,
                hasData: hasData,
                unit: 'kg',
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime? _resolveDistributionUpdatedAt() {
    if (widget.docDistributions.isEmpty) {
      return null;
    }

    final first = widget.docDistributions.first;
    final raw = first['updatedAt'] ?? first['updated_at'] ?? first['timestamp'];

    if (raw is DateTime) {
      return raw;
    }
    if (raw is String) {
      return DateTime.tryParse(raw);
    }

    return DateTime.now();
  }

  Widget _buildSampleStatusCard(int index) {
    final hasData = _sampleDocWeights[index].isNotEmpty;
    final totalWeight = _sampleDocWeights[index].fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final isLastSample = index == _sampleDocWeights.length - 1;
    final titleColor = hasData
        ? const Color(0xFF22C55E)
        : const Color(0xFF6F6F6F);
    final updatedAtText = _sampleUpdatedAt[index] == null
        ? '-'
        : _formatDateTime(_sampleUpdatedAt[index]!);

    return Container(
      margin: EdgeInsets.only(bottom: isLastSample ? 0 : 16),
      child: InkWell(
        onTap: () => _openSampleInputPage(index),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: _sampleCardMinHeight),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasData
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFE0E0E0),
              width: hasData ? 1.4 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: hasData
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF8A8A8A),
                  ),
                  color: hasData ? const Color(0xFF22C55E) : Colors.transparent,
                ),
                child: hasData
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sample ${index + 1}',
                      style: TextStyle(
                        fontSize: 38 / 2,
                        fontWeight: FontWeight.w500,
                        color: titleColor,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          updatedAtText,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildWeightBadge(totalWeight, hasData: hasData, unit: 'g'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeightBadge(
    double value, {
    required bool hasData,
    required String unit,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 72, minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _badgeBackgroundColor,
        border: Border.all(color: _badgeBorderColor),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _formatWeightValue(value, hasData: hasData, unit: unit),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: hasData ? _badgeTextColor : _badgeEmptyTextColor,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildBoxSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _buildBoxInputCard(
            title: 'Heaviest',
            controller: widget.boxHeaviestController,
            icon: Icons.arrow_upward,
            color: const Color(0xFFF34235),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBoxInputCard(
            title: 'Average',
            controller: widget.boxAverageController,
            icon: Icons.remove,
            color: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBoxInputCard(
            title: 'Lightest',
            controller: widget.boxLightestController,
            icon: Icons.arrow_downward,
            color: const Color(0xFF1E88E5),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime value) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = monthNames[value.month - 1];
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$day $month ${value.year} - $hour:$minute:$second';
  }

  String _formatTotalWeight(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  String _formatWeightValue(
    double value, {
    required bool hasData,
    required String unit,
  }) {
    if (!hasData) return '-';
    return '${_formatTotalWeight(value)}$unit';
  }

  Widget _buildBoxInputCard({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 24 / 2,
              color: color,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d{0,1}(\.\d{0,2})?'),
                ),
              ],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 34 / 2,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: '0.00',
                hintStyle: TextStyle(
                  color: color.withValues(alpha: 0.35),
                  fontSize: 34 / 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentItem {
  const _AttachmentItem({
    this.file,
    this.downloadUrl,
    this.isUploading = false,
  });

  final XFile? file;
  final String? downloadUrl;
  final bool isUploading;

  bool get hasPreview => file != null || (downloadUrl != null && downloadUrl!.isNotEmpty);

  _AttachmentItem copyWith({
    XFile? file,
    String? downloadUrl,
    bool? isUploading,
  }) {
    return _AttachmentItem(
      file: file ?? this.file,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      isUploading: isUploading ?? this.isUploading,
    );
  }

  factory _AttachmentItem.empty() => const _AttachmentItem();

  factory _AttachmentItem.remote(String url) =>
      _AttachmentItem(downloadUrl: url.trim());

  @override
  String toString() =>
      'AttachmentItem(file: ${file != null}, url: ${downloadUrl != null}, uploading: $isUploading)';
}

class _DashedRoundedRectPainter extends CustomPainter {
  const _DashedRoundedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashGap,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashGap != dashGap ||
        oldDelegate.radius != radius;
  }
}
