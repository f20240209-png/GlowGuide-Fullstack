import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'profile_setup_screen.dart';
import 'routine_screen.dart';
import 'skincare_log_screen.dart';
import 'edit_profile_screen.dart';
import '../widgets/consistency_heatmap_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _recommendation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    try {
      final profile = await ApiService.getProfile(token);
      if (profile['id'] != null) {
        setState(() => _profile = profile);
        final rec = await ApiService.getRecommendations(token);
        if (rec['recommendation'] != null) {
          setState(() => _recommendation = rec['recommendation']);
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE91E8C),
        title: const Text('GlowGuide', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await auth.logout();
              if (!mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE91E8C)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
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
                        Text('Hello, ${auth.userName}! 👋',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Ready for your skincare routine?',
                            style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_profile == null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.pink.shade50, blurRadius: 10)],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.person_add, size: 60, color: Color(0xFFE91E8C)),
                          const SizedBox(height: 12),
                          const Text('Complete Your Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Set up your skin profile to get AI-powered recommendations',
                              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSetupScreen())),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE91E8C),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Setup Profile', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Text('What would you like to do?',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // 3 Option Boxes
                    Row(
                      children: [
                        Expanded(
                          child: _optionBox(
                            icon: Icons.person_outlined,
                            title: 'Edit Profile',
                            subtitle: 'Update your skin info',
                            color: const Color(0xFF9C27B0),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EditProfileScreen(profile: _profile!)),
                            ).then((_) => _loadData()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _optionBox(
                            icon: Icons.auto_awesome,
                            title: 'My Routine',
                            subtitle: 'View AI recommendations',
                            color: const Color(0xFFE91E8C),
                            onTap: _recommendation != null
                                ? () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => RoutineScreen(recommendation: _recommendation!)),
                                    )
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Start Skincare Box (full width)
                    _optionBoxWide(
                      icon: Icons.spa,
                      title: 'Start Your Skincare',
                      subtitle: 'Log today\'s routine, products used & upload photo',
                      color: const Color(0xFF4CAF50),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SkincareLogScreen()),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick stats
                    const Text('Your Skin Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.pink.shade50, blurRadius: 10)],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _profileChip(Icons.face, _profile!['skinType']),
                          _profileChip(Icons.monetization_on, '₹${_profile!['budget']}'),
                          _profileChip(Icons.flag, '${(_profile!['skinGoals'] as List).length} Goals'),
                        ],
                      ),
                    ),
                        const SizedBox(height: 24),
                    const Text('Monthly Consistency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const ConsistencyHeatmapWidget(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _optionBox({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _optionBoxWide({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _profileChip(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFE91E8C)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}