import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/community_post_model.dart';

class QuestionDetailScreen extends StatefulWidget {
  final int postId;
  const QuestionDetailScreen({super.key, required this.postId});

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  static const Color _pink = Color(0xFFE91E8C);

  CommunityPostDetail? _post;
  bool _isLoading      = true;
  bool _isSubmitting   = false;
  bool _isAnonymous    = true;

  final _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPost();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _fetchPost() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final data  = await ApiService.getPostById(token, widget.postId);
      setState(() => _post = CommunityPostDetail.fromJson(data));
    } catch (_) {} finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAnswer() async {
    final ans = _answerController.text.trim();
    if (ans.length < 5) {
      _showSnack('Answer must be at least 5 characters.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final data  = await ApiService.answerPost(
        token,
        widget.postId,
        answer:      ans,
        isAnonymous: _isAnonymous,
      );

      if (data['message'] != null && data['answer'] != null) {
        _answerController.clear();
        _showSnack('Answer posted!');
        await _fetchPost();
      } else {
        _showSnack(data['message'] ?? 'Failed to post.', isError: true);
      }
    } catch (_) {
      _showSnack('Something went wrong.', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _likePost() async {
    try {
      final token = context.read<AuthProvider>().token!;
      await ApiService.likePost(token, widget.postId);
      await _fetchPost();
    } catch (_) {}
  }

  Future<void> _markHelpful(int answerId) async {
    try {
      final token = context.read<AuthProvider>().token!;
      await ApiService.markAnswerHelpful(token, answerId);
      await _fetchPost();
    } catch (_) {}
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
        title: const Text('Question',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _pink))
          : _post == null
              ? const Center(child: Text('Could not load question.'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildQuestionCard(),
                            const SizedBox(height: 20),
                            Text(
                              '${_post!.answers.length} Answer${_post!.answers.length != 1 ? 's' : ''}',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            if (_post!.answers.isEmpty)
                              _emptyAnswers()
                            else
                              ..._post!.answers
                                  .map((a) => _buildAnswerCard(a)),
                          ],
                        ),
                      ),
                    ),
                    _buildAnswerInput(),
                  ],
                ),
    );
  }

  Widget _buildQuestionCard() {
    final p = _post!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.pink.shade50, blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category + skin type
          Row(
            children: [
              _chip(p.category, _pink),
              if (p.skinType != null) ...[
                const SizedBox(width: 6),
                _chip(p.skinType!, Colors.purple),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Question
          Text(p.question,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),

          if (p.details != null && p.details!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(p.details!,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade700,
                    height: 1.5)),
          ],

          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),

          // Footer
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(p.author,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 12),
              Text(_timeAgo(p.createdAt),
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey)),
              const Spacer(),
              GestureDetector(
                onTap: _likePost,
                child: Row(
                  children: [
                    const Icon(Icons.favorite_border,
                        size: 18, color: _pink),
                    const SizedBox(width: 4),
                    Text('${p.likes}',
                        style: const TextStyle(
                            color: _pink, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerCard(CommunityAnswer answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.pink.shade50, blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(answer.answer,
              style: const TextStyle(fontSize: 13, height: 1.5)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Text(answer.author,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey)),
              const SizedBox(width: 10),
              Text(_timeAgo(answer.createdAt),
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey)),
              const Spacer(),
              GestureDetector(
                onTap: () => _markHelpful(answer.id),
                child: Row(
                  children: [
                    const Icon(Icons.thumb_up_outlined,
                        size: 15, color: Colors.green),
                    const SizedBox(width: 4),
                    Text('${answer.isHelpful} helpful',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.green)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10, offset: const Offset(0, -3))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Anonymous toggle
          Row(
            children: [
              const Icon(Icons.visibility_off_outlined,
                  size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              const Text('Answer anonymously',
                  style: TextStyle(fontSize: 13)),
              const Spacer(),
              Switch(
                value: _isAnonymous,
                onChanged: (v) => setState(() => _isAnonymous = v),
                activeColor: _pink,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _answerController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Share your advice...',
                    hintStyle: TextStyle(
                        color: Colors.grey.shade400, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFFFF0F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _pink, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _isSubmitting ? null : _submitAnswer,
                child: Container(
                  width: 48, height: 48,
                  decoration: const BoxDecoration(
                      color: _pink, shape: BoxShape.circle),
                  child: _isSubmitting
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyAnswers() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.chat_bubble_outline, size: 40, color: Colors.grey),
          const SizedBox(height: 10),
          Text('No answers yet. Be the first to help!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}