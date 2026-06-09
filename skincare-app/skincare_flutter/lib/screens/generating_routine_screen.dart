import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../services/api_service.dart';
import 'home_screen.dart';

class GeneratingRoutineScreen extends StatefulWidget {
  const GeneratingRoutineScreen({super.key});

  @override
  State<GeneratingRoutineScreen> createState() =>
      _GeneratingRoutineScreenState();
}

class _GeneratingRoutineScreenState extends State<GeneratingRoutineScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  int _currentStep = 0;
  bool _isError = false;
  String _errorMessage = '';

  final List<Map<String, String>> _steps = [
    {
      
      'title': 'Reading your profile',
      'subtitle': 'Analyzing skin type and goals...'
    },
    {
      
      'title': 'Analyzing your products',
      'subtitle': 'Checking effectiveness for your goals...'
    },
    {
      
      'title': 'AI is thinking',
      'subtitle': 'Finding the best routine for you...'
    },
    {
      
      'title': 'Building your routine',
      'subtitle': 'Personalizing product recommendations...'
    },
    {
      
      'title': 'Almost done!',
      'subtitle': 'Finalizing your personalized plan...'
    },
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _progressController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    _progressController.forward();

    // Step timer
    _startStepTimer();

    // Generate recommendation
    _generateRecommendation();
  }

  void _startStepTimer() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _currentStep = 1);
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() => _currentStep = 2);
        Future.delayed(const Duration(seconds: 4), () {
          if (!mounted) return;
          setState(() => _currentStep = 3);
          Future.delayed(const Duration(seconds: 3), () {
            if (!mounted) return;
            setState(() => _currentStep = 4);
          });
        });
      });
    });
  }

  Future<void> _generateRecommendation() async {
    try {
      final token =
          Provider.of<app_auth.AuthProvider>(context, listen: false).token!;

      // Delete existing recommendation to force fresh generation
      await ApiService.refreshRecommendations(token);

      if (!mounted) return;

      // Navigate to home
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: _isError ? _buildErrorState() : _buildLoadingState(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const Spacer(),

        // Animated logo
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE91E8C), Color(0xFFFF6BB3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE91E8C).withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome,
                color: Colors.white, size: 56),
          ),
        ),

        const SizedBox(height: 40),

        const Text(
          'Generating Your\nPersonalized Routine',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Our AI is analyzing your skin profile\nand building the perfect routine for you',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 15,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 48),

        // Progress bar
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _progressAnimation.value,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFE91E8C)),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_progressAnimation.value * 100).toInt()}%',
                  style: const TextStyle(
                    color: Color(0xFFE91E8C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 40),

        // Steps
        ...List.generate(_steps.length, (index) {
          final isDone = index < _currentStep;
          final isCurrent = index == _currentStep;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDone
                  ? Colors.green.shade50
                  : isCurrent
                      ? const Color(0xFFFFF0F5)
                      : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDone
                    ? Colors.green.shade200
                    : isCurrent
                        ? const Color(0xFFE91E8C).withValues(alpha: 0.3)
                        : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                // Icon or checkmark
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDone
                        ? Colors.green
                        : isCurrent
                            ? const Color(0xFFE91E8C)
                            : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 18)
                        : isCurrent
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _steps[index]['icon']!,
                                style: const TextStyle(fontSize: 16),
                              ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _steps[index]['title']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDone
                              ? Colors.green.shade700
                              : isCurrent
                                  ? const Color(0xFFE91E8C)
                                  : Colors.grey,
                        ),
                      ),
                      if (isCurrent)
                        Text(
                          _steps[index]['subtitle']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        const Spacer(),

        Text(
          'This may take 10-20 seconds',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 80),
        const SizedBox(height: 24),
        const Text('Something went wrong',
            style:
                TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(
          'Failed to generate your routine. Please try again.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _isError = false;
              _currentStep = 0;
            });
            _startStepTimer();
            _progressController.reset();
            _progressController.forward();
            _generateRecommendation();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE91E8C),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(
                horizontal: 32, vertical: 14),
          ),
          child: const Text('Try Again',
              style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
      ],
    );
  }
}