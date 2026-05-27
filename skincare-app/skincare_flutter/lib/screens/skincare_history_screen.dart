import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class SkincareHistoryScreen extends StatefulWidget {
  const SkincareHistoryScreen({super.key});

  @override
  State<SkincareHistoryScreen> createState() => _SkincareHistoryScreenState();
}

class _SkincareHistoryScreenState extends State<SkincareHistoryScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    try {
      final result = await ApiService.getSkincareLogs(token);
      setState(() => _logs = List<Map<String, dynamic>>.from(result['logs']));
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr).toLocal();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final day = days[date.weekday - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$day, ${date.day} ${months[date.month - 1]} ${date.year} • $hour:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        title: const Text('Skincare History', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : _logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('No logs yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Start logging your skincare routine!', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    final products = List<String>.from(log['productsUsed']);
                    final timeOfDay = log['timeOfDay'] as String;
                    final notes = log['notes'] as String?;
                    final date = _formatDate(log['createdAt']);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.green.shade50, blurRadius: 10)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                                    const SizedBox(width: 8),
                                    Text(date, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    timeOfDay == 'combined' ? 'Full Day' : timeOfDay,
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Products
                                const Text('Products Used', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: products.map((p) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.green.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.spa, size: 12, color: Color(0xFF4CAF50)),
                                        const SizedBox(width: 4),
                                        Text(p, style: const TextStyle(fontSize: 12, color: Color(0xFF4CAF50))),
                                      ],
                                    ),
                                  )).toList(),
                                ),

                                // Notes
                                if (notes != null && notes.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(notes, style: const TextStyle(color: Colors.grey)),
                                ],

                                // Stats row
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _statChip(Icons.spa, '${products.length} products', const Color(0xFF4CAF50)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}