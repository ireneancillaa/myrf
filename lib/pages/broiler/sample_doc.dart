import 'package:flutter/material.dart';

class SampleDocSection extends StatelessWidget {
  const SampleDocSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 420,
      child: Center(
        child: Text(
          'Sample DOC Page',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF22C55E),
          ),
        ),
      ),
    );
  }
}
