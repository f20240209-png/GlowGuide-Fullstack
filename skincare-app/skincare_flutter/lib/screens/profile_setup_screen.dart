import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'generating_routine_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _ageController = TextEditingController();
  final _budgetController = TextEditingController();
  final _routineController = TextEditingController();
  String _gender = 'male';
  String _skinType = 'oily';
  List<String> _selectedGoals = [];
  List<String> _currentProducts = [];
  final _productController = TextEditingController();
  bool _isLoading = false;

  final List<String> _skinTypes = ['oily', 'dry', 'combination', 'sensitive', 'normal'];
  final List<String> _goals = ['acne-free', 'oil-control', 'detanning', 'anti-aging', 'brightening', 'hydration', 'even-skin-tone'];

  Future<void> _saveProfile() async {
    if (_ageController.text.isEmpty || _budgetController.text.isEmpty || _selectedGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    try {
      final data = await ApiService.createProfile(token, {
        'age': int.parse(_ageController.text),
        'gender': _gender,
        'skinType': _skinType,
        'skinGoals': _selectedGoals,
        'budget': double.parse(_budgetController.text),
        'currentProducts': _currentProducts,
        'currentRoutine': _routineController.text.isEmpty ? null : _routineController.text,
      });
      if (!mounted) return;
       if (data['profile'] != null) {
  Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => const GeneratingRoutineScreen()));
}else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Error'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Setup Your Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE91E8C),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Basic Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Age *',
                prefixIcon: const Icon(Icons.cake_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Gender *', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: ['male', 'female', 'other'].map((g) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _gender = g),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _gender == g ? const Color(0xFFE91E8C) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(g.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _gender == g ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Skin Type *', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _skinTypes.map((type) {
                return ChoiceChip(
                  label: Text(type),
                  selected: _skinType == type,
                  onSelected: (_) => setState(() => _skinType = type),
                  selectedColor: const Color(0xFFE91E8C),
                  labelStyle: TextStyle(color: _skinType == type ? Colors.white : Colors.black),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Skin Goals * (select all that apply)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _goals.map((goal) {
                final selected = _selectedGoals.contains(goal);
                return FilterChip(
                  label: Text(goal),
                  selected: selected,
                  onSelected: (val) {
                    setState(() {
                      if (val) _selectedGoals.add(goal);
                      else _selectedGoals.remove(goal);
                    });
                  },
                  selectedColor: const Color(0xFFE91E8C),
                  labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Budget (₹/month) *', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Budget in ₹',
                prefixIcon: const Icon(Icons.currency_rupee),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Current Products (Optional)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _productController,
                    decoration: InputDecoration(
                      labelText: 'Add a product',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    if (_productController.text.isNotEmpty) {
                      setState(() {
                        _currentProducts.add(_productController.text);
                        _productController.clear();
                      });
                    }
                  },
                  icon: const Icon(Icons.add_circle, color: Color(0xFFE91E8C), size: 36),
                ),
              ],
            ),
            if (_currentProducts.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _currentProducts.map((p) => Chip(
                  label: Text(p),
                  onDeleted: () => setState(() => _currentProducts.remove(p)),
                )).toList(),
              ),
            ],
            const SizedBox(height: 20),
            const Text('Current Routine (Optional)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _routineController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Describe your current routine...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E8C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save & Get AI Recommendations', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}