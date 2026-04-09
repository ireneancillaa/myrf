import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SampleDocSection extends StatefulWidget {
  final TextEditingController boxHeaviestController;
  final TextEditingController boxAverageController;
  final TextEditingController boxLightestController;
  final List<double> docWeights;
  final Function(List<double>) onDocWeightsChanged;
  final List<Map<String, dynamic>> docDistributions;
  final Function(List<Map<String, dynamic>>) onDocDistributionsChanged;
  final int dietReplication;
  final int totalPens;

  const SampleDocSection({
    super.key,
    required this.boxHeaviestController,
    required this.boxAverageController,
    required this.boxLightestController,
    required this.docWeights,
    required this.onDocWeightsChanged,
    required this.docDistributions,
    required this.onDocDistributionsChanged,
    required this.dietReplication,
    required this.totalPens,
  });

  @override
  State<SampleDocSection> createState() => _SampleDocSectionState();
}

class _SampleDocSectionState extends State<SampleDocSection> {
  static const double _fieldTextSize = 14;
  static const double _fieldHintSize = 14;
  static const double _fieldHeight = 50;

  final _distributionWeightController = TextEditingController();
  String? _selectedPenForDistribution;
  String? _selectedReplicationForDistribution;
  final List<List<double>> _sampleDocWeights = [[], [], []];
  final List<TextEditingController> _docWeightControllers = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      _docWeightControllers.add(TextEditingController());
    }
    if (widget.docWeights.isNotEmpty) {
      for (int i = 0; i < widget.docWeights.length && i < 3; i++) {
        _sampleDocWeights[i].add(widget.docWeights[i]);
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _docWeightControllers) {
      controller.dispose();
    }
    _distributionWeightController.dispose();
    super.dispose();
  }

  void _addDocWeight(int sampleIndex) {
    final weight = double.tryParse(_docWeightControllers[sampleIndex].text);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid weight'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _sampleDocWeights[sampleIndex].add(weight);
    _updateAllDocWeights();
    _docWeightControllers[sampleIndex].clear();
  }

  void _removeDocWeight(int sampleIndex, int weightIndex) {
    _sampleDocWeights[sampleIndex].removeAt(weightIndex);
    _updateAllDocWeights();
  }

  void _updateAllDocWeights() {
    final allWeights = <double>[];
    for (final sample in _sampleDocWeights) {
      allWeights.addAll(sample);
    }
    widget.onDocWeightsChanged(allWeights);
  }

  bool get _allSamplesCompleted {
    return _sampleDocWeights[0].isNotEmpty &&
        _sampleDocWeights[1].isNotEmpty &&
        _sampleDocWeights[2].isNotEmpty;
  }

  void _showAllWeightsDialog(int sampleIndex) {
    final weights = _sampleDocWeights[sampleIndex];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sample ${sampleIndex + 1} - All Weights'),
        content: SizedBox(
          width: double.maxFinite,
          child: weights.isEmpty
              ? const Center(child: Text('No weights added'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: weights.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF22C55E),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text('${weights[index].toStringAsFixed(2)} g'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _removeDocWeight(sampleIndex, index);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _addDistribution() {
    if (_selectedPenForDistribution == null ||
        _distributionWeightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final weight = double.tryParse(_distributionWeightController.text);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid weight'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newDistribution = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'penNumber': _selectedPenForDistribution,
      'replication': _selectedReplicationForDistribution ?? '1',
      'weight': weight,
    };

    widget.onDocDistributionsChanged([
      ...widget.docDistributions,
      newDistribution,
    ]);
    _distributionWeightController.clear();
    setState(() {
      _selectedPenForDistribution = null;
      _selectedReplicationForDistribution = null;
    });
  }

  void _removeDistribution(int index) {
    final newDistributions = List<Map<String, dynamic>>.from(
      widget.docDistributions,
    );
    newDistributions.removeAt(index);
    widget.onDocDistributionsChanged(newDistributions);
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
            ...List.generate(3, (index) => _buildSampleSection(index)),
            const SizedBox(height: 24),
            if (_allSamplesCompleted) ...[
              const Divider(height: 32),
              const SizedBox(height: 16),
              _buildDocDistributionSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSampleSection(int index) {
    final hasData = _sampleDocWeights[index].isNotEmpty;
    final isLastSample = index == _sampleDocWeights.length - 1;

    return Container(
      margin: EdgeInsets.only(bottom: isLastSample ? 0 : 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: hasData
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF22C55E).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasData ? Icons.check : Icons.edit,
                      color: hasData ? Colors.white : const Color(0xFF22C55E),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sample ${index + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (hasData)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_sampleDocWeights[index].length} weights',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF22C55E),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildBoxInputCard(
                      title: 'Heaviest',
                      controller: widget.boxHeaviestController,
                      icon: Icons.arrow_upward,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBoxInputCard(
                      title: 'Average',
                      controller: widget.boxAverageController,
                      icon: Icons.remove,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBoxInputCard(
                      title: 'Lightest',
                      controller: widget.boxLightestController,
                      icon: Icons.arrow_downward,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'DOC Weights',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: _fieldHeight,
                      child: TextFormField(
                        controller: _docWeightControllers[index],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(fontSize: _fieldTextSize),
                        decoration: const InputDecoration(
                          labelText: 'Weight (g)',
                          hintText: 'Weight (g)',
                          hintStyle: TextStyle(
                            fontSize: _fieldHintSize,
                            color: Color(0xFF9CA3AF),
                          ),
                          labelStyle: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                          prefixIcon: Icon(Icons.scale),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF22C55E)),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                        ),
                        onFieldSubmitted: (_) => _addDocWeight(index),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: _fieldHeight,
                    width: _fieldHeight,
                    child: ElevatedButton(
                      onPressed: () => _addDocWeight(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.add, size: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_sampleDocWeights[index].isNotEmpty) ...[
                GestureDetector(
                  onTap: () => _showAllWeightsDialog(index),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.visibility,
                          color: Color(0xFF22C55E),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_sampleDocWeights[index].length} weights added',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'No weights added yet',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocDistributionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DOC Distribution',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF22C55E),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Distribute DOC to each pen per kg',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedReplicationForDistribution,
                style: const TextStyle(fontSize: _fieldTextSize),
                decoration: InputDecoration(
                  labelText: 'Replication',
                  hintText: 'Replication',
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                  hintStyle: const TextStyle(
                    fontSize: _fieldHintSize,
                    color: Color(0xFF9CA3AF),
                  ),
                  prefixIcon: const Icon(Icons.repeat),
                  filled: true,
                  fillColor: Colors.white,
                  border: const OutlineInputBorder(),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF22C55E)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                ),
                items: List.generate(
                  widget.dietReplication,
                  (index) => DropdownMenuItem(
                    value: '${index + 1}',
                    child: Text('${index + 1}'),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedReplicationForDistribution = value;
                    _selectedPenForDistribution = null;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedPenForDistribution,
                style: const TextStyle(fontSize: _fieldTextSize),
                decoration: InputDecoration(
                  labelText: 'Pen Number',
                  hintText: 'Pen Number',
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                  hintStyle: const TextStyle(
                    fontSize: _fieldHintSize,
                    color: Color(0xFF9CA3AF),
                  ),
                  prefixIcon: const Icon(Icons.tag),
                  filled: true,
                  fillColor: Colors.white,
                  border: const OutlineInputBorder(),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF22C55E)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                ),
                items: List.generate(
                  widget.totalPens,
                  (index) => DropdownMenuItem(
                    value: 'Pen ${index + 1}',
                    child: Text('${index + 1}'),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedPenForDistribution = value;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 4,
              child: SizedBox(
                height: _fieldHeight,
                child: TextFormField(
                  controller: _distributionWeightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(fontSize: _fieldTextSize),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d{0,1}(\.\d{0,2})?'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    hintText: 'Weight (kg)',
                    labelStyle: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                    prefixIcon: Icon(Icons.scale),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF22C55E)),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                  ),
                  onFieldSubmitted: (_) => _addDistribution(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 56,
              width: 56,
              child: ElevatedButton(
                onPressed: _addDistribution,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Icon(Icons.add, size: 28),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (widget.docDistributions.isNotEmpty) ...[
          Text(
            'Distributions (${widget.docDistributions.length})',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Column(
                children: widget.docDistributions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final dist = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.share,
                          color: Color(0xFF22C55E),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        dist['penNumber'].toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Rep: ${dist['replication']} | ${dist['weight'].toStringAsFixed(2)} kg',
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => _removeDistribution(index),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'No distributions added yet',
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBoxInputCard({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'^\d{0,1}(\.\d{0,2})?'),
              ),
            ],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            decoration: InputDecoration(
              filled: false,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: '0.00',
              hintStyle: TextStyle(color: color.withOpacity(0.3), fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
