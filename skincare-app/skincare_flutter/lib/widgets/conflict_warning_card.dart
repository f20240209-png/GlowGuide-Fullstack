import 'package:flutter/material.dart';

class ConflictWarningCard extends StatelessWidget {
  final Map<String, dynamic> conflict;

  const ConflictWarningCard({super.key, required this.conflict});

  @override
  Widget build(BuildContext context) {
    final isHigh = conflict['severityLevel'] == 'High';
    final bgColor = isHigh ? Colors.red.shade50 : Colors.orange.shade50;
    final borderColor = isHigh ? Colors.red.shade300 : Colors.orange.shade300;
    final iconColor = isHigh ? Colors.red : Colors.orange;
    final labelColor = isHigh ? Colors.red.shade700 : Colors.orange.shade700;
    final labelBg = isHigh ? Colors.red.shade100 : Colors.orange.shade100;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(
                isHigh ? Icons.dangerous : Icons.warning_amber_rounded,
                color: iconColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_capitalize(conflict['ingredientA'])} + ${_capitalize(conflict['ingredientB'])}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: iconColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: labelBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  conflict['severityLevel'],
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Ingredient chips
          Row(
            children: [
              _ingredientChip(conflict['ingredientA'], iconColor),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.close, size: 16, color: iconColor),
              ),
              _ingredientChip(conflict['ingredientB'], iconColor),
            ],
          ),
          const SizedBox(height: 10),
          // Warning message
          Text(
            conflict['warningMessage'],
            style: TextStyle(
              color: isHigh ? Colors.red.shade900 : Colors.orange.shade900,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ingredientChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        _capitalize(label),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}