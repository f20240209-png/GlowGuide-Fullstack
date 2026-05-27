import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/conflict_warning_card.dart';

class RoutineScreen extends StatefulWidget {
  final Map<String, dynamic> recommendation;
  const RoutineScreen({super.key, required this.recommendation});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _conflicts = [];
  bool _analyzingIngredients = false;
  bool _analysisComplete = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _analyzeIngredients();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _analyzeIngredients() async {
    setState(() => _analyzingIngredients = true);
    try {
      final products = widget.recommendation['products'] as List;
      final allIngredients = <String>[];

      for (final product in products) {
        final ingredients = product['ingredients'] as String?;
        if (ingredients != null && ingredients.isNotEmpty) {
          final split = ingredients
              .split(',')
              .map((i) => i.trim().toLowerCase())
              .where((i) => i.isNotEmpty)
              .toList();
          allIngredients.addAll(split);
        }
      }

      if (allIngredients.isEmpty) {
        setState(() {
          _analysisComplete = true;
          _conflicts = [];
        });
        return;
      }

      if (!mounted) return;
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final result = await ApiService.analyzeIngredients(token, allIngredients);

      setState(() {
        _conflicts =
            List<Map<String, dynamic>>.from(result['conflicts'] ?? []);
        _analysisComplete = true;
      });
    } catch (e) {
      debugPrint('Ingredient analysis error: $e');
      setState(() => _analysisComplete = true);
    } finally {
      if (mounted) setState(() => _analyzingIngredients = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final routine = widget.recommendation['routine'];
    final products = widget.recommendation['products'] as List;
    final tips = widget.recommendation['tips'] as List?;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE91E8C),
        foregroundColor: Colors.white,
        title: const Text('Your Routine',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Routine'),
            Tab(text: 'Products'),
            Tab(text: 'Tips'),
            Tab(text: '⚠️ Check'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Routine Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('🌅 Morning Routine'),
                ...(routine['morning'] as List)
                    .map((step) => _routineCard(step)),
                const SizedBox(height: 16),
                _sectionTitle('🌙 Evening Routine'),
                ...(routine['evening'] as List)
                    .map((step) => _routineCard(step)),
                const SizedBox(height: 16),
                _sectionTitle('📅 Weekly Routine'),
                ...(routine['weekly'] as List)
                    .map((step) => _routineCard(step)),
              ],
            ),
          ),

          // Products Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: products.map((p) => _productCard(p)).toList(),
            ),
          ),

          // Tips Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tips != null) ...[
                  _sectionTitle('💡 Skincare Tips'),
                  ...tips.map((tip) => _tipCard(tip.toString())),
                ],
                const SizedBox(height: 16),
                if (widget.recommendation['dietAdvice'] != null) ...[
                  _sectionTitle('🥗 Diet Advice'),
                  _tipCard(widget.recommendation['dietAdvice']),
                ],
                const SizedBox(height: 16),
                if (widget.recommendation['warnings'] != null) ...[
                  _sectionTitle('⚠️ Warnings'),
                  _warningCard(widget.recommendation['warnings']),
                ],
              ],
            ),
          ),

          // Ingredient Conflict Check Tab
          _buildConflictTab(),
        ],
      ),
    );
  }

  Widget _buildConflictTab() {
    final highConflicts = _conflicts
        .where((c) => c['severityLevel'] == 'High')
        .toList();
    final medConflicts = _conflicts
        .where((c) => c['severityLevel'] == 'Medium')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _analysisComplete && _conflicts.isEmpty
                    ? [const Color(0xFF4CAF50), const Color(0xFF81C784)]
                    : _conflicts.isNotEmpty
                        ? [const Color(0xFFE53935), const Color(0xFFEF9A9A)]
                        : [const Color(0xFFE91E8C), const Color(0xFFFF6BB3)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: _analyzingIngredients
                ? const Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Analyzing ingredients...',
                          style:
                              TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  )
                : Row(
                    children: [
                      Icon(
                        _conflicts.isEmpty
                            ? Icons.check_circle
                            : Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _conflicts.isEmpty
                                  ? 'All Clear! ✅'
                                  : '${_conflicts.length} Conflict${_conflicts.length > 1 ? "s" : ""} Found',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _conflicts.isEmpty
                                  ? 'Your routine ingredients are fully compatible!'
                                  : 'Some ingredients in your routine may clash.',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),

          if (_analyzingIngredients)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFE91E8C)),
            )
          else if (_conflicts.isEmpty && _analysisComplete) ...[
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Icon(Icons.spa, size: 80, color: Colors.green.shade200),
                  const SizedBox(height: 16),
                  const Text('Perfect Routine!',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'No ingredient conflicts detected.\nYour AI-generated skincare routine is safe to use!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, height: 1.5),
                  ),
                ],
              ),
            ),
          ] else ...[
            if (highConflicts.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.dangerous, color: Colors.red, size: 18),
                  const SizedBox(width: 6),
                  Text('High Severity (${highConflicts.length})',
                      style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              ...highConflicts
                  .map((c) => ConflictWarningCard(conflict: c))
                  .toList(),
              const SizedBox(height: 16),
            ],

            if (medConflicts.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 18),
                  const SizedBox(width: 6),
                  Text('Medium Severity (${medConflicts.length})',
                      style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              ...medConflicts
                  .map((c) => ConflictWarningCard(conflict: c))
                  .toList(),
            ],
          ],

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _analyzingIngredients ? null : _analyzeIngredients,
              icon: const Icon(Icons.refresh),
              label: const Text('Re-analyze Ingredients'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE91E8C)),
                foregroundColor: const Color(0xFFE91E8C),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title,
          style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _routineCard(Map<String, dynamic> step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.pink.shade50, blurRadius: 8)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
                color: Color(0xFFE91E8C), shape: BoxShape.circle),
            child: Center(
                child: Text('${step['step']}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step['action'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(step['instruction'],
                    style: const TextStyle(color: Colors.grey)),
                if (step['duration'] != null)
                  Text('⏱ ${step['duration']}',
                      style: const TextStyle(
                          color: Color(0xFFE91E8C), fontSize: 12)),
                if (step['frequency'] != null)
                  Text('🔄 ${step['frequency']}',
                      style: const TextStyle(
                          color: Color(0xFFE91E8C), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.pink.shade50, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(product['name'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${product['price']}',
                      style: const TextStyle(
                          color: Color(0xFFE91E8C),
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  if (product['originalPrice'] != null &&
                      product['originalPrice'] != product['price'])
                    Text('₹${product['originalPrice']}',
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(product['brand'] ?? '',
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 13)),
              if (product['discount'] != null &&
                  product['discount'] != '0%') ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(product['discount'],
                      style: const TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(product['category'],
                    style: const TextStyle(
                        color: Color(0xFFE91E8C), fontSize: 12)),
              ),
              if (product['reviewCount'] != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 2),
                Text(
                    '${product['rating'] ?? ''} (${_formatCount(product['reviewCount'])} reviews)',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(product['reason'] ?? '',
              style:
                  const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 6),
          if (product['ingredients'] != null &&
              product['ingredients'].toString().isNotEmpty) ...[
            const Text('Key Ingredients:',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 2),
            Text(product['ingredients'].toString(),
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
          ],
          Row(
            children: [
              const Icon(Icons.shopping_cart_outlined,
                  size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(product['availableAt'] ?? 'Nykaa, Amazon',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCount(dynamic count) {
    if (count == null) return '';
    final n =
        count is int ? count : int.tryParse(count.toString()) ?? 0;
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
    return n.toString();
  }

  Widget _tipCard(String tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.pink.shade50, blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFFE91E8C)),
          const SizedBox(width: 8),
          Expanded(child: Text(tip)),
        ],
      ),
    );
  }

  Widget _warningCard(String warning) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(child: Text(warning)),
        ],
      ),
    );
  }
}