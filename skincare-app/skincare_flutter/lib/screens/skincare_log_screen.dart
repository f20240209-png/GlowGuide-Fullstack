import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/conflict_warning_card.dart';

class SkincareLogScreen extends StatefulWidget {
  const SkincareLogScreen({super.key});

  @override
  State<SkincareLogScreen> createState() => _SkincareLogScreenState();
}

class _SkincareLogScreenState extends State<SkincareLogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Map<String, List<String>> _selectedProducts = {
    'morning': [],
    'evening': [],
    'night': [],
  };
  final Map<String, TextEditingController> _notesControllers = {
    'morning': TextEditingController(),
    'evening': TextEditingController(),
    'night': TextEditingController(),
  };

  final _productSearchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  bool _logSaved = false;
  Map<String, dynamic>? _savedLog;


  List<Map<String, dynamic>> _conflicts = [];
  bool _checkingConflicts = false;

  Future<void> _checkIngredientConflicts() async {
  // Gather all products from all slots
  final allProducts = [
    ..._selectedProducts['morning']!,
    ..._selectedProducts['evening']!,
    ..._selectedProducts['night']!,
  ];

  if (allProducts.length < 2) {
    setState(() => _conflicts = []);
    return;
  }

  setState(() => _checkingConflicts = true);

  try {
    final token = Provider.of<AuthProvider>(context, listen: false).token!;

    // Extract ingredient keywords from product names
    final ingredientKeywords = _extractIngredientKeywords(allProducts);

    if (ingredientKeywords.isEmpty) {
      setState(() => _conflicts = []);
      return;
    }

    final result = await ApiService.analyzeIngredients(token, ingredientKeywords);
    setState(() {
      _conflicts = List<Map<String, dynamic>>.from(result['conflicts'] ?? []);
    });
  } catch (e) {
    debugPrint('Conflict check error: $e');
  } finally {
    setState(() => _checkingConflicts = false);
  }
}

List<String> _extractIngredientKeywords(List<String> productNames) {
  final keywords = <String>[];
  final text = productNames.join(' ').toLowerCase();

  // Check for common active ingredients in product names
  final ingredientMap = {
    'retinol': ['retinol', 'retin'],
    'vitamin c': ['vitamin c', 'vit c', 'ascorbic', 'vitc'],
    'niacinamide': ['niacinamide', 'niacin'],
    'aha': ['aha', 'glycolic', 'lactic', 'mandelic', 'alpha hydroxy'],
    'bha': ['bha', 'salicylic', 'beta hydroxy'],
    'salicylic acid': ['salicylic'],
    'glycolic acid': ['glycolic'],
    'lactic acid': ['lactic'],
    'benzoyl peroxide': ['benzoyl'],
    'hyaluronic acid': ['hyaluronic', 'ha serum'],
    'kojic acid': ['kojic'],
    'niacinamide': ['niacinamide'],
    'peptides': ['peptide'],
    'copper peptides': ['copper peptide'],
    'spf': ['spf', 'sunscreen', 'sun screen'],
    'alpha arbutin': ['arbutin'],
  };

  for (final entry in ingredientMap.entries) {
    if (entry.value.any((keyword) => text.contains(keyword))) {
      keywords.add(entry.key);
    }
  }

  return keywords;
}

  // Past reports
  List<Map<String, dynamic>> _pastLogs = [];
  bool _logsLoading = true;

  Uint8List? _photoBytes;
  String _currentSlot = 'morning';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPastLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _productSearchController.dispose();
    for (final c in _notesControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPastLogs() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    try {
      final result = await ApiService.getSkincareLogs(token);
      setState(() => _pastLogs = List<Map<String, dynamic>>.from(result['logs']));
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _logsLoading = false);
    }
  }

  String _getCompliment(Map<String, List<String>> products) {
    final totalProducts = products.values.expand((e) => e).length;
    final sessions = products.values.where((p) => p.isNotEmpty).length;
    if (sessions == 3 && totalProducts >= 6) {
      return "🏆 Skincare Champion! You completed all 3 sessions with $totalProducts products. Your skin is going to love you for this!";
    } else if (sessions == 3) {
      return "⭐ Amazing! You did all 3 skincare sessions today. Consistency is the secret to glowing skin!";
    } else if (sessions == 2) {
      return "💪 Great job! Two solid sessions today. Your skin is already thanking you!";
    } else if (sessions == 1 && totalProducts >= 3) {
      return "🌱 Good start! $totalProducts products used. Every step counts on the journey to healthy skin!";
    } else {
      return "💧 Nice work! You showed up for your skin today. Keep going!";
    }
  }

  Future<void> _searchProducts(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await ApiService.searchProducts(query);
      setState(() =>
          _searchResults = List<Map<String, dynamic>>.from(results['products']));
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _isSearching = false);
    }
  }

 Future<void> _pickPhoto() async {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Upload Photo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    await _getImage(ImageSource.camera);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE91E8C).withValues(alpha: 0.3)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.camera_alt, color: Color(0xFFE91E8C), size: 36),
                        SizedBox(height: 8),
                        Text('Camera', style: TextStyle(
                          color: Color(0xFFE91E8C),
                          fontWeight: FontWeight.w600,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    await _getImage(ImageSource.gallery);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE91E8C).withValues(alpha: 0.3)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.photo_library, color: Color(0xFFE91E8C), size: 36),
                        SizedBox(height: 8),
                        Text('Gallery', style: TextStyle(
                          color: Color(0xFFE91E8C),
                          fontWeight: FontWeight.w600,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

Future<void> _getImage(ImageSource source) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: source,
    imageQuality: 85,
  );
  if (picked != null) {
    final bytes = await picked.readAsBytes();
    setState(() => _photoBytes = bytes);
  }
}

  Future<void> _saveLog() async {
    final hasAny = _selectedProducts.values.any((p) => p.isNotEmpty);
    if (!hasAny) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add products for at least one time slot'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    try {
      final allProducts = [
        ..._selectedProducts['morning']!.map((p) => 'Morning: $p'),
        ..._selectedProducts['evening']!.map((p) => 'Evening: $p'),
        ..._selectedProducts['night']!.map((p) => 'Night: $p'),
      ];
      final notes = [
        if (_notesControllers['morning']!.text.isNotEmpty) 'Morning: ${_notesControllers['morning']!.text}',
        if (_notesControllers['evening']!.text.isNotEmpty) 'Evening: ${_notesControllers['evening']!.text}',
        if (_notesControllers['night']!.text.isNotEmpty) 'Night: ${_notesControllers['night']!.text}',
      ].join('\n');

      String? photoBase64;
      if (_photoBytes != null) photoBase64 = base64Encode(_photoBytes!);

      await ApiService.createSkincareLog(token, {
        'timeOfDay': 'combined',
        'productsUsed': allProducts,
        'notes': notes.isEmpty ? null : notes,
        'photo': photoBase64,
      });

      if (!mounted) return;
      setState(() {
        _logSaved = true;
        _savedLog = {
          'products': Map<String, List<String>>.from({
            'morning': List<String>.from(_selectedProducts['morning']!),
            'evening': List<String>.from(_selectedProducts['evening']!),
            'night': List<String>.from(_selectedProducts['night']!),
          }),
          'photo': _photoBytes,
          'date': DateTime.now().toString(),
        };
      });

      await _loadPastLogs();
      _tabController.animateTo(1);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Skincare log saved! 🌟'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr).toLocal();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final day = days[date.weekday - 1];
    return '$day, ${date.day} ${months[date.month - 1]} ${date.year} • ${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        title: const Text('Skincare Logger', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.spa), text: 'Log Routine'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Daily Report'),
            Tab(icon: Icon(Icons.photo_library), text: 'Past Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLogTab(),
          _buildReportTab(),
          _buildPastReportsTab(),
        ],
      ),
    );
  }

  Widget _buildLogTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Time Slot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Fill one or more — all are optional', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              _timeSlotButton('morning', '🌅', 'Morning'),
              const SizedBox(width: 8),
              _timeSlotButton('evening', '🌆', 'Evening'),
              const SizedBox(width: 8),
              _timeSlotButton('night', '🌙', 'Night'),
            ],
          ),
          const SizedBox(height: 24),

          Text('Products Used — ${_currentSlot[0].toUpperCase()}${_currentSlot.substring(1)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _productSearchController,
            onChanged: _searchProducts,
            decoration: InputDecoration(
              labelText: 'Type to search products...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? const Padding(padding: EdgeInsets.all(12),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),

          if (_searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
              ),
              child: Column(
                children: _searchResults.map((product) => ListTile(
                  leading: const Icon(Icons.spa, color: Color(0xFF4CAF50)),
                  title: Text(product['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text('${product['brand']} • ₹${product['price']}'),
                  trailing: const Icon(Icons.add_circle_outline, color: Color(0xFF4CAF50)),
                  onTap: () {
                    final productName = '${product['name']} by ${product['brand']}';
                    if (!_selectedProducts[_currentSlot]!.contains(productName)) {
                      setState(() {
                        _selectedProducts[_currentSlot]!.add(productName);
                        _searchResults = [];
                        _productSearchController.clear();
                      });
                      _checkIngredientConflicts();
                    }
                  },
                )).toList(),
              ),
            ),

          if (_selectedProducts[_currentSlot]!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _selectedProducts[_currentSlot]!.map((p) => Chip(
                label: Text(p, style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.green.shade50,
                avatar: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.red),
                onDeleted: () => setState(() => _selectedProducts[_currentSlot]!.remove(p)),
              )).toList(),
            ),
          ],

          const SizedBox(height: 20),
          Text('Notes for ${_currentSlot[0].toUpperCase()}${_currentSlot.substring(1)} (Optional)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesControllers[_currentSlot],
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'How did your skin feel?',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          const Text('Upload Photo (Optional)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Show your skin progress!', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200, width: 2),
              ),
              child: _photoBytes != null
                  ? Column(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(14),
                            topRight: Radius.circular(14),
                          ),
                          child: Image.memory(_photoBytes!, width: double.infinity, fit: BoxFit.contain),
                        ),
                        TextButton.icon(
                          onPressed: _pickPhoto,
                          icon: const Icon(Icons.refresh, color: Color(0xFF4CAF50)),
                          label: const Text('Change Photo', style: TextStyle(color: Color(0xFF4CAF50))),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.add_a_photo, size: 48, color: Colors.green.shade300),
                          const SizedBox(height: 8),
                          const Text('Tap to upload photo', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
            ),
          ),
         // Conflict warnings
if (_checkingConflicts) ...[
  const SizedBox(height: 16),
  Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      children: [
        SizedBox(
          width: 18, height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE91E8C)),
        ),
        SizedBox(width: 12),
        Text('Checking ingredient compatibility...',
            style: TextStyle(color: Colors.grey)),
      ],
    ),
  ),
] else if (_conflicts.isNotEmpty) ...[
  const SizedBox(height: 16),
  // Warning header
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${_conflicts.length} ingredient conflict${_conflicts.length > 1 ? 's' : ''} detected in your routine!',
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ),
  ),
  const SizedBox(height: 8),
  // Show each conflict card
  ..._conflicts.map((c) => ConflictWarningCard(conflict: c)).toList(),
] else if (_conflicts.isEmpty &&
    (_selectedProducts.values.expand((e) => e).length >= 2)) ...[
  const SizedBox(height: 16),
  Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.green.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.green.shade200),
    ),
    child: const Row(
      children: [
        Icon(Icons.check_circle, color: Colors.green, size: 22),
        SizedBox(width: 10),
        Text('All ingredients are compatible! ✅',
            style: TextStyle(
                color: Colors.green, fontWeight: FontWeight.bold)),
      ],
    ),
  ),
],


          const SizedBox(height: 24),
          const Text('Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _summaryCard('🌅', 'Morning', _selectedProducts['morning']!),
          const SizedBox(height: 8),
          _summaryCard('🌆', 'Evening', _selectedProducts['evening']!),
          const SizedBox(height: 8),
          _summaryCard('🌙', 'Night', _selectedProducts['night']!),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveLog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save & Generate Report 🌟', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildReportTab() {
    if (!_logSaved || _savedLog == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('No report yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Log your routine first to see your daily report', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Go to Log', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final products = _savedLog!['products'] as Map<String, List<String>>;
    final photo = _savedLog!['photo'] as Uint8List?;
    final now = DateTime.now();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instagram style photo card
          if (photo != null) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.green.shade50, blurRadius: 12)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFF4CAF50),
                          radius: 20,
                          child: Icon(Icons.spa, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('My Skincare', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('${now.day} ${months[now.month - 1]} ${now.year}',
                                style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Today', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  Image.memory(photo, width: double.infinity, fit: BoxFit.contain),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite, color: Colors.red, size: 22),
                        const SizedBox(width: 6),
                        const Icon(Icons.spa, color: Color(0xFF4CAF50), size: 22),
                        const SizedBox(width: 6),
                        Text('${products.values.expand((e) => e).length} products used',
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Report header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF81C784)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Skincare Report 📊',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${now.day} ${months[now.month - 1]} ${now.year} • ${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}',
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Compliment
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Text(_getCompliment(products), style: const TextStyle(fontSize: 15, height: 1.5)),
          ),
          const SizedBox(height: 20),

          const Text('Products Used Today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (products['morning']!.isNotEmpty) ...[
            _reportSlotCard('🌅', 'Morning', products['morning']!, const Color(0xFFFF9800)),
            const SizedBox(height: 12),
          ],
          if (products['evening']!.isNotEmpty) ...[
            _reportSlotCard('🌆', 'Evening', products['evening']!, const Color(0xFF9C27B0)),
            const SizedBox(height: 12),
          ],
          if (products['night']!.isNotEmpty) ...[
            _reportSlotCard('🌙', 'Night', products['night']!, const Color(0xFF3F51B5)),
            const SizedBox(height: 12),
          ],

          // Ingredient conflict warnings in report
if (_conflicts.isNotEmpty) ...[
  const SizedBox(height: 20),
  const Text('⚠️ Ingredient Warnings',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  const SizedBox(height: 4),
  const Text(
    'These ingredient combinations were detected in your routine today.',
    style: TextStyle(color: Colors.grey, fontSize: 13),
  ),
  const SizedBox(height: 12),
  ..._conflicts.map((c) => ConflictWarningCard(conflict: c)).toList(),
] else if (_logSaved) ...[
  const SizedBox(height: 20),
  Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.green.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.green.shade200),
    ),
    child: const Row(
      children: [
        Icon(Icons.check_circle, color: Colors.green),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'No ingredient conflicts in today\'s routine! ✅',
            style: TextStyle(
                color: Colors.green, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  ),
],

          const SizedBox(height: 20),
          const Text('Today\'s Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statBox(
                '${products.values.expand((e) => e).length}',
                'Products Used', Icons.spa, const Color(0xFF4CAF50),
              )),
              const SizedBox(width: 12),
              Expanded(child: _statBox(
                '${products.values.where((p) => p.isNotEmpty).length}',
                'Sessions Done', Icons.check_circle, const Color(0xFFE91E8C),
              )),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildPastReportsTab() {
    if (_logsLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
    }
    if (_pastLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('No past reports yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Your skincare history will appear here', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pastLogs.length,
      itemBuilder: (context, index) {
        final log = _pastLogs[index];
        final products = List<String>.from(log['productsUsed']);
        final notes = log['notes'] as String?;
        final date = _formatDate(log['createdAt']);
        final hasPhoto = log['photo'] != null;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.green.shade50, blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instagram-style header
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFF4CAF50),
                      radius: 20,
                      child: Icon(Icons.spa, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('My Skincare', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${products.length} products',
                          style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 12)),
                    ),
                  ],
                ),
              ),

              // Photo if exists
             // Photo if exists
              if (hasPhoto && log['photo'] != null) ...[
                Builder(builder: (context) {
                  try {
                    final bytes = base64Decode(log['photo'] as String);
                    return Image.memory(bytes, width: double.infinity, fit: BoxFit.contain);
                  } catch (e) {
                    return const SizedBox.shrink();
                  }
                }),
              ],

              // Products
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Like row
                    Row(
                      children: [
                        const Icon(Icons.favorite, color: Colors.red, size: 20),
                        const SizedBox(width: 6),
                        const Icon(Icons.spa, color: Color(0xFF4CAF50), size: 20),
                        const SizedBox(width: 6),
                        Text('${products.length} products used',
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Products list
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: products.map((p) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.spa, size: 10, color: Color(0xFF4CAF50)),
                            const SizedBox(width: 4),
                            Text(p, style: const TextStyle(fontSize: 11, color: Color(0xFF4CAF50))),
                          ],
                        ),
                      )).toList(),
                    ),

                    // Notes
                    if (notes != null && notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(notes, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Uint8List?> _fetchPhoto(String photoPath) async {
    // Photo is stored as file path on server
    // For now return null — we'll handle this with base64 in future
    return null;
  }

  Widget _timeSlotButton(String slot, String emoji, String label) {
    final isSelected = _currentSlot == slot;
    final hasProducts = _selectedProducts[slot]!.isNotEmpty;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentSlot = slot),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: hasProducts ? Border.all(color: const Color(0xFF4CAF50), width: 2) : null,
            boxShadow: [BoxShadow(color: Colors.green.shade50, blurRadius: 8)],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              )),
              if (hasProducts)
                Text('${_selectedProducts[slot]!.length} products',
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white70 : const Color(0xFF4CAF50),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(String emoji, String label, List<String> products) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              products.isEmpty ? 'No products added' : '${products.length} products',
              style: TextStyle(color: products.isEmpty ? Colors.grey : const Color(0xFF4CAF50)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportSlotCard(String emoji, String label, List<String> products, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          ]),
          const SizedBox(height: 8),
          ...products.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Icon(Icons.check_circle, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(p, style: const TextStyle(fontSize: 13))),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _statBox(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}