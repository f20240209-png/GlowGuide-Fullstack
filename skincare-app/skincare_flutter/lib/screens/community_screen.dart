import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/community_post_model.dart';
import 'ask_question_screen.dart';
import 'question_detail_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Constants ────────────────────────────────────────────────────────────
  static const Color _pink      = Color(0xFFE91E8C);
  static const Color _pinkLight = Color(0xFFFFF0F5);

  static const List<String> _categories = [
    'All', 'Acne', 'Oily', 'Dry', 'Sensitive',
    'Anti-aging', 'Brightening', 'Hydration',
  ];

  // ── State ────────────────────────────────────────────────────────────────
  List<CommunityPost> _allPosts  = [];
  List<CommunityPost> _myPosts   = [];
  bool   _loadingAll  = true;
  bool   _loadingMine = true;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAll();
    _fetchMine();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Fetch ────────────────────────────────────────────────────────────────
  Future<void> _fetchAll({String? category}) async {
    setState(() => _loadingAll = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final data  = await ApiService.getCommunityPosts(
        token,
        category: category == 'All' || category == null ? null : category.toLowerCase(),
      );
      setState(() {
        _allPosts = (data['posts'] as List)
            .map((p) => CommunityPost.fromJson(p as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {} finally {
      setState(() => _loadingAll = false);
    }
  }

  Future<void> _fetchMine() async {
    setState(() => _loadingMine = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final data  = await ApiService.getMyPosts(token);
      setState(() {
        _myPosts = (data['posts'] as List)
            .map((p) => CommunityPost.fromJson(p as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {} finally {
      setState(() => _loadingMine = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pinkLight,
      appBar: AppBar(
        backgroundColor: _pink,
        foregroundColor: Colors.white,
        title: const Text('Community',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Ask'),
            Tab(text: 'Answer Others'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAskTab(),
          _buildAnswerTab(),
        ],
      ),
    );
  }

  // ── Ask Tab ──────────────────────────────────────────────────────────────
  Widget _buildAskTab() {
    return RefreshIndicator(
      color: _pink,
      onRefresh: _fetchMine,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prompt card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE91E8C), Color(0xFFFF6BB3)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💬 Got a skin question?',
                      style: TextStyle(color: Colors.white, fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text(
                    'Post it anonymously and get real advice from the community.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AskQuestionScreen()),
                    ).then((_) => _fetchMine()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _pink,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('+ Ask a Question',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Your Questions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            if (_loadingMine)
              const Center(child: CircularProgressIndicator(color: _pink))
            else if (_myPosts.isEmpty)
              _emptyState("You haven't asked anything yet.",
                  "Your questions will appear here.")
            else
              ..._myPosts.map((p) => _postCard(p, showAnswerBtn: false)),
          ],
        ),
      ),
    );
  }

  // ── Answer Tab ───────────────────────────────────────────────────────────
  Widget _buildAnswerTab() {
    return Column(
      children: [
        // Category filter chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final selected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedCategory = cat);
                      _fetchAll(category: cat);
                    },
                    selectedColor: _pink,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    backgroundColor: Colors.grey.shade100,
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Posts list
        Expanded(
          child: RefreshIndicator(
            color: _pink,
            onRefresh: () => _fetchAll(category: _selectedCategory),
            child: _loadingAll
                ? const Center(child: CircularProgressIndicator(color: _pink))
                : _allPosts.isEmpty
                    ? _emptyState(
                        'No questions yet.', 'Be the first to ask!')
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _allPosts.length,
                        itemBuilder: (_, i) =>
                            _postCard(_allPosts[i], showAnswerBtn: true),
                      ),
          ),
        ),
      ],
    );
  }

  // ── Post card ────────────────────────────────────────────────────────────
  Widget _postCard(CommunityPost post, {required bool showAnswerBtn}) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => QuestionDetailScreen(postId: post.id)),
      ).then((_) {
        _fetchAll(category: _selectedCategory);
        _fetchMine();
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.pink.shade50, blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category + skin type chips
            Row(
              children: [
                _chip(post.category, _pink),
                if (post.skinType != null) ...[
                  const SizedBox(width: 6),
                  _chip(post.skinType!, Colors.purple),
                ],
                const Spacer(),
                Text(_timeAgo(post.createdAt),
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
            const SizedBox(height: 10),

            // Question
            Text(post.question,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),

            // Footer
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(post.author,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 16),
                const Icon(Icons.chat_bubble_outline,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${post.answerCount} answers',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
                const Spacer(),
                if (showAnswerBtn)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.pink.shade200),
                    ),
                    child: const Text('Answer',
                        style: TextStyle(
                            color: _pink,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ],
        ),
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

  Widget _emptyState(String title, String sub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(Icons.chat_bubble_outline,
                size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(sub,
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}