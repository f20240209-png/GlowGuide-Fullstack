import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'generating_routine_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _ageController;
  late TextEditingController _budgetController;
  late TextEditingController _routineController;
  late String _gender;
  late String _skinType;
  late List<String> _selectedGoals;
  bool _isLoading = false;

  final List<String> _skinTypes = ['oily', 'dry', 'combination', 'sensitive', 'normal'];
  final List<String> _goals = ['acne-free', 'oil-control', 'detanning', 'anti-aging', 'brightening', 'hydration', 'even-skin-tone'];

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(text: widget.profile['age'].toString());
    _budgetController = TextEditingController(text: widget.profile['budget'].toString());
    _routineController = TextEditingController(text: widget.profile['currentRoutine'] ?? '');
    _gender = widget.profile['gender'];
    _skinType = widget.profile['skinType'];
    _selectedGoals = List<String>.from(widget.profile['skinGoals']);
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    try {
      final data = await ApiService.updateProfile(token, {
        'age': int.parse(_ageController.text),
        'gender': _gender,
        'skinType': _skinType,
        'skinGoals': _selectedGoals,
        'budget': double.parse(_budgetController.text),
        'currentRoutine': _routineController.text.isEmpty ? null : _routineController.text,
      });
      if (!mounted) return;
      if (data['profile'] != null) {
  Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => const GeneratingRoutineScreen()));
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
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Age',
                prefixIcon: const Icon(Icons.cake_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Gender', style: TextStyle(fontWeight: FontWeight.w500)),
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
                        color: _gender == g ? const Color(0xFF9C27B0) : Colors.grey.shade100,
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
            const SizedBox(height: 16),
            const Text('Skin Type', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _skinTypes.map((type) {
                return ChoiceChip(
                  label: Text(type),
                  selected: _skinType == type,
                  onSelected: (_) => setState(() => _skinType = type),
                  selectedColor: const Color(0xFF9C27B0),
                  labelStyle: TextStyle(color: _skinType == type ? Colors.white : Colors.black),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Skin Goals', style: TextStyle(fontWeight: FontWeight.w500)),
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
                  selectedColor: const Color(0xFF9C27B0),
                  labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Budget (₹/month)',
                prefixIcon: const Icon(Icons.currency_rupee),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _routineController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Current Routine',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27B0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Update Profile', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}