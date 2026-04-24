import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class WeighingCalculatorPage extends StatefulWidget {
  const WeighingCalculatorPage({
    super.key,
    required this.calcType,
    this.initialDate = '',
    this.initialValues = const <double>[],
  });

  final String calcType; // feedAndBag, lastBirds, actualBirds, birdsWeight
  final String initialDate;
  final List<double> initialValues;

  @override
  State<WeighingCalculatorPage> createState() => _WeighingCalculatorPageState();
}

class _WeighingCalculatorPageState extends State<WeighingCalculatorPage> {
  static const double _calculatorButtonHeight = 72;
  static const double _distributionFieldHeight = 50;
  final ScrollController _listScrollController = ScrollController();
  final List<TextEditingController> _controllers = [];
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.calcType == 'boxWeight') {
      // 0: start pen, 1: end pen, 2: box count, 3: box weight
      for (int i = 0; i < 4; i++) {
        _controllers.add(TextEditingController());
      }
      _activeIndex = 0;
      return;
    }
    if (widget.initialValues.isEmpty) {
      _controllers.add(TextEditingController());
      _activeIndex = 0;
      return;
    }
    for (final value in widget.initialValues) {
      final isWhole = value % 1 == 0;
      _controllers.add(
        TextEditingController(
          text: isWhole ? value.toInt().toString() : value.toString(),
        ),
      );
    }
    _activeIndex = _controllers.length - 1;
    _scrollToBottom();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _listScrollController.dispose();
    super.dispose();
  }

  void _appendToActive(String value) {
    final controller = _controllers[_activeIndex];
    var current = controller.text;
    if (value == '.') {
      if (current.contains('.')) return;
      if (current.isEmpty) current = '0';
      controller.text = '$current.';
      setState(() {});
      return;
    }
    controller.text = '$current$value';
    setState(() {});
  }

  void _removeLastChar() {
    final controller = _controllers[_activeIndex];
    if (controller.text.isEmpty) return;
    controller.text = controller.text.substring(0, controller.text.length - 1);
    setState(() {});
  }

  void _clearActiveField() {
    _controllers[_activeIndex].clear();
    setState(() {});
  }

  void _addPen() {
    setState(() {
      _controllers.add(TextEditingController());
      _activeIndex = _controllers.length - 1;
    });
    _scrollToBottom();
  }

  Future<bool> _confirmDeleteField(int index) async {
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
                      'Delete Field?',
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pen ${index + 1} will be deleted. Continue?',
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

    if (_controllers.length == 1) {
      setState(() {
        _controllers.first.clear();
        _activeIndex = 0;
      });
      return false;
    }

    setState(() {
      _controllers.removeAt(index);
      if (_activeIndex == index) {
        _activeIndex = index >= _controllers.length
            ? _controllers.length - 1
            : index;
      } else if (_activeIndex > index) {
        _activeIndex -= 1;
      }
    });
    _scrollToActive();
    return true;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listScrollController.hasClients) return;
      _listScrollController.animateTo(
        _listScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _scrollToActive() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listScrollController.hasClients) return;
      const itemExtent = _distributionFieldHeight + 10;
      final offset = _activeIndex * itemExtent;
      _listScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatWeight(String text) {
    final parsed = double.tryParse(text.trim());
    if (parsed == null) return '-';
    if (parsed % 1 == 0) {
      return parsed.toInt().toStringAsFixed(0);
    }
    return parsed.toStringAsFixed(2);
  }

  String _saveButtonLabel() => 'Save ${_pageTitle()}';

  String _pageTitle() {
    switch (widget.calcType) {
      case 'feedAndBag':
        return 'Feed & Bag';
      case 'lastBirds':
        return 'Last Birds';
      case 'actualBirds':
        return 'Actual Birds';
      case 'birdsWeight':
        return 'Birds Weight';
      case 'boxWeight':
        return 'Box Weight';
      default:
        return 'Calculator';
    }
  }

  Future<void> _showScaleSelectionModal() async {
    final blockedMessage = await _bluetoothBlockedMessage();
    if (blockedMessage != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(blockedMessage)));
      return;
    }

    if (!mounted) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Scale Type',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildScaleOptionTile(
                    label: 'Hanging Scale',
                    imagePath: 'assets/hanging-scale.png',
                    onTap: () => Navigator.of(sheetContext).pop('hanging'),
                  ),
                  const SizedBox(height: 10),
                  _buildScaleOptionTile(
                    label: 'Bench Scale',
                    icon: Icons.monitor_weight_outlined,
                    onTap: () => Navigator.of(sheetContext).pop('bench'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) return;

    final message = selected == 'hanging'
        ? 'Hanging Scale selected'
        : 'Bench Scale selected';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String?> _bluetoothBlockedMessage() async {
    try {
      if (Platform.isAndroid) {
        final permissionStatuses = await <Permission>[
          Permission.bluetoothConnect,
          Permission.bluetoothScan,
        ].request();
        final hasDeniedPermission = permissionStatuses.values.any(
          (status) =>
              status.isDenied ||
              status.isPermanentlyDenied ||
              status.isRestricted,
        );
        if (hasDeniedPermission) {
          return 'Bluetooth permission has not been granted. Please allow Bluetooth access.';
        }
      }

      final state = await FlutterBluePlus.adapterState
          .where((item) => item != BluetoothAdapterState.unknown)
          .first;
      if (state != BluetoothAdapterState.on) {
        return 'Bluetooth is still off. Please turn on Bluetooth first.';
      }

      return null;
    } catch (_) {
      return 'Bluetooth status could not be read. Please try again shortly.';
    }
  }

  Widget _buildScaleOptionTile({
    required String label,
    IconData? icon,
    String? imagePath,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5EE),
                  shape: BoxShape.circle,
                ),
                child: imagePath != null
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(imagePath, fit: BoxFit.contain),
                      )
                    : Icon(icon, color: const Color(0xFF22C55E), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (widget.calcType == 'boxWeight') {
      final start = _controllers[0].text.trim();
      final end = _controllers[1].text.trim();
      final count = int.tryParse(_controllers[2].text.trim()) ?? 0;
      final weight = double.tryParse(_controllers[3].text.trim()) ?? 0.0;

      if (start.isEmpty || end.isEmpty || count == 0 || weight == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all fields correctly'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      Navigator.of(context).pop({
        'title': 'Pen $start - $end',
        'count': count,
        'weight': weight,
      });
      return;
    }

    final values = <double>[];
    final pens = <String>[];
    for (final controller in _controllers) {
      final text = controller.text.trim();
      if (text.isEmpty) continue;
      final parsed = double.tryParse(text);
      if (parsed != null && parsed > 0) {
        values.add(parsed);
        pens.add(
          parsed % 1 == 0 ? parsed.toInt().toString() : parsed.toString(),
        );
      }
    }

    Navigator.of(
      context,
    ).pop({'date': widget.initialDate, 'values': values, 'pens': pens});
  }

  @override
  Widget build(BuildContext context) {
    // final hasInput = _controllers.any((c) {
    //   final t = c.text.trim();
    //   final n = double.tryParse(t);
    //   return t.isNotEmpty && n != null && n > 0;
    // });
    return Scaffold(
      backgroundColor: const Color(0xFFE7E7E7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        actions: [
          IconButton(
            onPressed: _showScaleSelectionModal,
            icon: const Icon(Icons.bluetooth, color: Color(0xFF111827)),
            tooltip: 'Bluetooth',
          ),
        ],
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        title: Text(
          _pageTitle(),
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Expanded(child: _buildPenListPanel()),
              const SizedBox(height: 10),
              _buildKeypad(),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _saveButtonLabel(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPenListPanel() {
    if (widget.calcType == 'boxWeight') {
      return _buildBoxWeightInputPanel();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: _listScrollController,
        child: Column(
          children: List.generate(_controllers.length, (index) {
            final isActive = index == _activeIndex;
            final row = GestureDetector(
              onTap: () => setState(() => _activeIndex = index),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: _distributionFieldHeight,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFEAF4EA)
                      : const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFBDBDBD),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      (widget.calcType == 'feedAndBag' || widget.calcType == 'birdsWeight')
                        ? 'Pen ${index + 1} (kg):'
                        : 'Pen ${index + 1}:',
                      style: TextStyle(
                        color: isActive
                            ? const Color(0xFF0A992E)
                            : const Color(0xFF404040),
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatWeight(_controllers[index].text),
                      style: TextStyle(
                        color: isActive
                            ? const Color(0xFF0A992E)
                            : const Color(0xFF353535),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == _controllers.length - 1 ? 0 : 10,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Dismissible(
                  key: ValueKey(_controllers[index]),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    decoration: const BoxDecoration(color: Color(0xFFEF4444)),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  confirmDismiss: (_) => _confirmDeleteField(index),
                  child: row,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBoxWeightInputPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pen Range',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildBoxInputField(0, 'From')),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(child: _buildBoxInputField(1, 'To')),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          _buildBoxInputField(2, 'Box Count'),
          const SizedBox(height: 12),
          _buildBoxInputField(3, 'Box Weight (kg)'),
        ],
      ),
    );
  }

  Widget _buildBoxInputField(int index, String label) {
    final isActive = index == _activeIndex;
    return GestureDetector(
      onTap: () => setState(() => _activeIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEAF4EA) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFF22C55E) : const Color(0xFFE0E0E0),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFF22C55E) : Colors.grey[600],
                fontSize: 15,
              ),
            ),
            const Spacer(),
            Text(
              _controllers[index].text.isEmpty ? '-' : _controllers[index].text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final isActiveFilled =
        _controllers.isNotEmpty &&
        _controllers[_activeIndex].text.trim().isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildKeypadRow([
          _PadButtonSpec.text(
            '7',
            onTap: () => setState(() => _appendToActive('7')),
          ),
          _PadButtonSpec.text(
            '8',
            onTap: () => setState(() => _appendToActive('8')),
          ),
          _PadButtonSpec.text(
            '9',
            onTap: () => setState(() => _appendToActive('9')),
          ),
          _PadButtonSpec.icon(Icons.backspace_outlined, onTap: _removeLastChar),
        ]),
        const SizedBox(height: 10),
        _buildKeypadRow([
          _PadButtonSpec.text(
            '4',
            onTap: () => setState(() => _appendToActive('4')),
          ),
          _PadButtonSpec.text(
            '5',
            onTap: () => setState(() => _appendToActive('5')),
          ),
          _PadButtonSpec.text(
            '6',
            onTap: () => setState(() => _appendToActive('6')),
          ),
          const _PadButtonSpec._(label: ''),
        ]),
        const SizedBox(height: 10),
        _buildKeypadRow([
          _PadButtonSpec.text(
            '1',
            onTap: () => setState(() => _appendToActive('1')),
          ),
          _PadButtonSpec.text(
            '2',
            onTap: () => setState(() => _appendToActive('2')),
          ),
          _PadButtonSpec.text(
            '3',
            onTap: () => setState(() => _appendToActive('3')),
          ),
          _PadButtonSpec.icon(
            Icons.skip_next_rounded,
            onTap: (widget.calcType == 'boxWeight')
                ? (isActiveFilled
                    ? () {
                        setState(() {
                          _activeIndex = (_activeIndex + 1) % 4;
                        });
                      }
                    : null)
                : (isActiveFilled ? _addPen : null),
          ),
        ]),
        const SizedBox(height: 10),
        _buildKeypadRow([
          const _PadButtonSpec._(label: ''),
          _PadButtonSpec.text(
            '0',
            onTap: () => setState(() => _appendToActive('0')),
          ),
          _PadButtonSpec.text(
            '.',
            onTap: () => setState(() => _appendToActive('.')),
          ),
          _PadButtonSpec.icon(Icons.refresh_rounded, onTap: _clearActiveField),
        ]),
      ],
    );
  }

  Widget _buildKeypadRow(List<_PadButtonSpec> specs) {
    return Row(
      children: List.generate(specs.length * 2 - 1, (index) {
        if (index.isOdd) {
          return const SizedBox(width: 10);
        }
        final spec = specs[index ~/ 2];
        return Expanded(
          child: _PadButton(spec: spec, height: _calculatorButtonHeight),
        );
      }),
    );
  }
}

class _PadButtonSpec {
  const _PadButtonSpec._({
    this.label,
    this.icon,
    this.onTap,
    this.isAction = false,
  });

  const _PadButtonSpec.text(String label, {required VoidCallback? onTap})
    : this._(label: label, onTap: onTap);

  const _PadButtonSpec.icon(IconData icon, {required VoidCallback? onTap})
    : this._(icon: icon, onTap: onTap, isAction: true);

  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isAction;
}

class _PadButton extends StatelessWidget {
  const _PadButton({required this.spec, required this.height});

  final _PadButtonSpec spec;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDisabled = spec.onTap == null;
    final bgColor = spec.isAction
        ? (isDisabled ? const Color(0xFFE5E7EB) : const Color(0xFF22C55E))
        : const Color(0xFFF6F6F6);
    final borderColor = spec.isAction
        ? (isDisabled ? const Color(0xFFD1D5DB) : const Color(0xFF22C55E))
        : const Color(0xFFE0E0E0);
    return GestureDetector(
      onTap: spec.onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: spec.icon != null
            ? Icon(
                spec.icon,
                color: isDisabled ? const Color(0xFF9CA3AF) : Colors.white,
                size: 30,
              )
            : Text(
                spec.label!,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF222222),
                ),
              ),
      ),
    );
  }
}
