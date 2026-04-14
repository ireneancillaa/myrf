import 'package:flutter/material.dart';

class SampleDocInputPage extends StatefulWidget {
  const SampleDocInputPage({
    super.key,
    this.readOnly = false,
    required this.sampleNumber,
    required this.initialWeights,
  });

  final bool readOnly;
  final int sampleNumber;
  final List<double> initialWeights;

  @override
  State<SampleDocInputPage> createState() => _SampleDocInputPageState();
}

class _SampleDocInputPageState extends State<SampleDocInputPage> {
  static const double _calculatorButtonHeight = 72;
  static const double _docFieldHeight = 50;
  final List<TextEditingController> _controllers = [];
  final ScrollController _listScrollController = ScrollController();
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialWeights.isEmpty) {
      _controllers.add(TextEditingController());
      _activeIndex = 0;
    } else {
      for (final value in widget.initialWeights) {
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

  void _goNextField() {
    if (_activeIndex == _controllers.length - 1) {
      setState(() {
        _controllers.add(TextEditingController());
        _activeIndex += 1;
      });
      _scrollToBottom();
      return;
    }

    setState(() {
      _activeIndex += 1;
    });
  }

  bool _canGoNextField() {
    return _controllers[_activeIndex].text.trim().isNotEmpty;
  }

  void _clearActiveField() {
    _controllers[_activeIndex].clear();
    setState(() {});
  }

  void _deleteActiveField() {
    if (_controllers.length == 1) {
      _controllers.first.clear();
      setState(() {});
      return;
    }

    final removedIndex = _activeIndex;
    _controllers.removeAt(removedIndex);
    if (_activeIndex >= _controllers.length) {
      _activeIndex = _controllers.length - 1;
    }
    setState(() {});
    if (removedIndex >= _controllers.length) {
      _scrollToBottom();
    }
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

  void _saveSample() {
    final values = <double>[];
    for (final controller in _controllers) {
      final text = controller.text.trim();
      if (text.isEmpty) continue;
      final parsed = double.tryParse(text);
      if (parsed != null && parsed > 0) {
        values.add(parsed);
      }
    }
    Navigator.of(context).pop(values);
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
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        title: Text(
          'Sample ${widget.sampleNumber}',
          textAlign: TextAlign.center,
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
              Expanded(child: _buildDocListPanel()),
              const SizedBox(height: 10),
              _buildKeypad(),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: widget.readOnly
                      ? () => Navigator.of(context).pop()
                      : _saveSample,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    widget.readOnly
                        ? 'Close Sample ${widget.sampleNumber}'
                        : 'Save Sample ${widget.sampleNumber}',
                    style: const TextStyle(
                      fontSize: 20 / 1.1,
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

  Widget _buildDocListPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
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
            return GestureDetector(
              onTap: widget.readOnly
                  ? null
                  : () => setState(() => _activeIndex = index),
              child: Container(
                margin: EdgeInsets.only(
                  bottom: index == _controllers.length - 1 ? 0 : 10,
                ),
                constraints: const BoxConstraints(minHeight: _docFieldHeight),
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
                      'DOC ${index + 1} (g):',
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
                      _controllers[index].text.isEmpty
                          ? '-'
                          : _controllers[index].text,
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
            onTap: widget.readOnly ? null : () => _appendToActive('7'),
          ),
          _PadButtonSpec.text(
            '8',
            onTap: widget.readOnly ? null : () => _appendToActive('8'),
          ),
          _PadButtonSpec.text(
            '9',
            onTap: widget.readOnly ? null : () => _appendToActive('9'),
          ),
          _PadButtonSpec.icon(
            Icons.backspace_outlined,
            onTap: widget.readOnly ? null : _removeLastChar,
          ),
        ]),
        const SizedBox(height: 10),
        _buildKeypadRow([
          _PadButtonSpec.text(
            '4',
            onTap: widget.readOnly ? null : () => _appendToActive('4'),
          ),
          _PadButtonSpec.text(
            '5',
            onTap: widget.readOnly ? null : () => _appendToActive('5'),
          ),
          _PadButtonSpec.text(
            '6',
            onTap: widget.readOnly ? null : () => _appendToActive('6'),
          ),
          _PadButtonSpec.icon(
            Icons.skip_previous_rounded,
            onTap: widget.readOnly ? null : _deleteActiveField,
          ),
        ]),
        const SizedBox(height: 10),
        _buildKeypadRow([
          _PadButtonSpec.text(
            '1',
            onTap: widget.readOnly ? null : () => _appendToActive('1'),
          ),
          _PadButtonSpec.text(
            '2',
            onTap: widget.readOnly ? null : () => _appendToActive('2'),
          ),
          _PadButtonSpec.text(
            '3',
            onTap: widget.readOnly ? null : () => _appendToActive('3'),
          ),
          _PadButtonSpec.icon(
            Icons.skip_next_rounded,
            onTap: widget.readOnly
                ? null
                : (_canGoNextField() ? _goNextField : null),
          ),
        ]),
        const SizedBox(height: 10),
        _buildKeypadRow([
          const _PadButtonSpec._(label: ''),
          _PadButtonSpec.text(
            '0',
            onTap: widget.readOnly ? null : () => _appendToActive('0'),
          ),
          _PadButtonSpec.text(
            '.',
            onTap: widget.readOnly ? null : () => _appendToActive('.'),
          ),
          _PadButtonSpec.icon(
            Icons.refresh_rounded,
            onTap: widget.readOnly ? null : _clearActiveField,
          ),
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
