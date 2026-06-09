import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class AskQuestionScreen extends StatefulWidget {
  const AskQuestionScreen({super.key});

  @override
  State<AskQuestionScreen> createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends State<AskQuestionScreen> {
  static const Color _pink = Color(0xFFE91E8C);

  final _questionController = TextEditingController();
  final _detailsController  = TextEditingController();

  String  _selectedCategory = 'Acne';
  String? _selectedSkinType;
  bool    _isAnonymous      = true;
  bool    _isLoading        = false;

  static const List<String> _categories = [
    'Acne', 'Oily', 'Dry', 'Sensitive',
    'Anti-aging', 'Brightening', 'Hydration', 'General',
  ];

  static const List<String> _skinTypes = [
    'Oily', 'Dry', 'Combination', 'Sensitive', 'Normal',
  ];

  @override
  void dispose() {
    _questionController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final q = _questionController.text.trim();
    if (q.length < 10) {
      _showSnack('Question must be at least 10 characters.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final data  = await ApiService.createPost(
        token,
        question:    q,
        details:     _detailsController.text.trim().isEmpty
            ? null
            : _detailsController.text.trim(),
        category:    _selectedCategory.toLowerCase(),
        skinType:    _selectedSkinType?.toLowerCase(),
        isAnonymous: _isAnonymous,
      );

      if (!mounted) return;
      if (data['message'] != null && data['post'] != null) {
        _showSnack('Question posted!');
        Navigator.pop(context);
      } else {
        _showSnack(data['message'] ?? 'Failed to post.', isError: true);
      }
    } catch (e) {
      _showSnack('Something went wrong.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        backgroundColor: _pink,
        foregroundColor: Colors.white,
        title: const Text('Ask a Question',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question field
            _label('Your Question *'),
            const SizedBox(height: 8),
            TextField(
              controller: _questionController,
              maxLines: 3,
              maxLength: 300,
              decoration: _inputDec(
                hint: 'e.g. Why does my skin get oily after cleansing?',
              ),
            ),
            const SizedBox(height: 16),

            // Details field
            _label('More Details (Optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsController,
              maxLines: 4,
              decoration: _inputDec(
                hint: 'Add more context — products you use, how long the issue has been there, etc.',
              ),
            ),
            const SizedBox(height: 20),

            // Category
            _label('Category *'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final sel = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(cat),
                  selected: sel,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                  selectedColor: _pink,
                  backgroundColor: Colors.grey.shade100,
                  labelStyle: TextStyle(
                    color: sel ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Skin type
            _label('Your Skin Type (Optional)'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skinTypes.map((st) {
                final sel = st == _selectedSkinType;
                return ChoiceChip(
                  label: Text(st),
                  selected: sel,
                  onSelected: (_) => setState(() =>
                      _selectedSkinType = sel ? null : st),
                  selectedColor: Colors.purple,
                  backgroundColor: Colors.grey.shade100,
                  labelStyle: TextStyle(
                    color: sel ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Anonymous toggle
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.visibility_off_outlined,
                      color: Colors.grey, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Post Anonymously',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('Others will see "Anonymous" instead of your name',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAnonymous,
                    onChanged: (v) => setState(() => _isAnonymous = v),
                    activeColor: _pink,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pink,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Post Question',
                        style: TextStyle(color: Colors.white,
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14));

  InputDecoration _inputDec({required String hint}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _pink, width: 1.5),
    ),
  );
}