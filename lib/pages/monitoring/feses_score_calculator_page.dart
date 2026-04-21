import 'package:flutter/material.dart';

class FesesScoreCalculatorPage extends StatefulWidget {
  const FesesScoreCalculatorPage({
    super.key,
    required this.fieldLabel,
    this.initialValues = const <double>[],
  });

  final String fieldLabel;
  final List<double> initialValues;

  @override
  State<FesesScoreCalculatorPage> createState() =>
      _FesesScoreCalculatorPageState();
}

class _FesesScoreCalculatorPageState extends State<FesesScoreCalculatorPage> {
  static const Color _primaryGreen = Color(0xFF22C55E);
  static const double _calculatorButtonHeight = 72;
  static const double _distributionFieldHeight = 50;

  final ScrollController _listScrollController = ScrollController();
  final List<TextEditingController> _controllers = [];
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
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

  TextEditingController get _activeController => _controllers[_activeIndex];

  void _appendToActive(String value) {
    var current = _activeController.text;

    if (value == '.') {
      if (current.contains('.')) return;
      if (current.isEmpty) current = '0';
      _activeController.text = '$current.';
      setState(() {});
      return;
    }

    _activeController.text = '$current$value';
    setState(() {});
  }

  void _removeLastChar() {
    if (_activeController.text.isEmpty) return;
    _activeController.text = _activeController.text.substring(
      0,
      _activeController.text.length - 1,
    );
    setState(() {});
  }

  void _clearActiveField() {
    _activeController.clear();
    setState(() {});
  }

  void _addPen() {
    setState(() {
      _controllers.add(TextEditingController());
      _activeIndex = _controllers.length - 1;
    });
    _scrollToBottom();
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

  String _formatWeight(String text) {
    final parsed = double.tryParse(text.trim());
    if (parsed == null) return '-';
    if (parsed % 1 == 0) {
      return parsed.toInt().toString();
    }
    return parsed.toStringAsFixed(3);
  }

  void _save() {
    final values = <double>[];
    for (final controller in _controllers) {
      final parsed = double.tryParse(controller.text.trim());
      if (parsed != null && parsed > 0) {
        values.add(parsed);
      }
    }

    Navigator.of(context).pop(values);
  }

  String _saveButtonLabel() => 'Save ${widget.fieldLabel}';

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

  Widget _buildPenListPanel() {
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
                margin: EdgeInsets.only(
                  bottom: index == _controllers.length - 1 ? 0 : 10,
                ),
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
                      'Pen ${index + 1} (g):',
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

            return Dismissible(
              key: ValueKey(_controllers[index]),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: EdgeInsets.only(
                  bottom: index == _controllers.length - 1 ? 0 : 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              confirmDismiss: (_) async {
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
              },
              child: row,
            );
          }),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
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
          _PadButtonSpec.icon(Icons.skip_next_rounded, onTap: _addPen),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7E7E7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        title: Text(
          widget.fieldLabel,
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
                    backgroundColor: _primaryGreen,
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
