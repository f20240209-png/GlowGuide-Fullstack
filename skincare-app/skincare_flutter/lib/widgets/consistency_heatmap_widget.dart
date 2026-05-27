import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/heatmap_day_model.dart';

class ConsistencyHeatmapWidget extends StatefulWidget {
  const ConsistencyHeatmapWidget({super.key});

  @override
  State<ConsistencyHeatmapWidget> createState() => _ConsistencyHeatmapWidgetState();
}

class _ConsistencyHeatmapWidgetState extends State<ConsistencyHeatmapWidget> {
  // ── State ─────────────────────────────────────────────────────────────────
  late int _year;
  late int _month;
  List<HeatmapDay> _days = [];
  int _currentStreak = 0;
  bool _isLoading = true;
  String? _error;

  // ── Constants ─────────────────────────────────────────────────────────────
  static const Color _primaryPink = Color(0xFFE91E8C);
  static const Color _lightPink   = Color(0xFFFF69B4);
  static const Color _deepPink    = Color(0xFFAD1457);
  static const Color _emptyGrey   = Color(0xFFE0E0E0);

static const double _cellSize = 24.0; // Perfect for laptop mouse clicks!
static const double _spacing = 6.0;  //circle diameter reference

  static const List<String> _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  static const List<String> _monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year  = now.year;
    _month = now.month;
    _fetchHeatmap();
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────
  Future<void> _fetchHeatmap() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception('Not authenticated');

      final result = await ApiService.getMonthlyHeatmap(token, _year, _month);
      setState(() {
        // FIX: Safely parse the list to prevent Dart TypeErrors
        _days = (result['heatmapData'] as List)
            .map((e) => e is HeatmapDay ? e : HeatmapDay.fromJson(e))
            .toList();
            
        // FIX: Safely cast streak (in case API returns a string or double)
        _currentStreak = (result['currentStreak'] as num).toInt();
        _isLoading     = false;
      });
    } catch (e) {
      setState(() {
        _error     = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Month Navigation ──────────────────────────────────────────────────────
  void _changeMonth(int delta) {
    setState(() {
      _month += delta;
      if (_month > 12) { _month = 1;  _year++; }
      if (_month < 1)  { _month = 12; _year--; }
    });
    _fetchHeatmap();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Color _colorForStatus(int status) {
    switch (status) {
      case 2:  return _deepPink;
      case 1:  return _lightPink;
      default: return _emptyGrey;
    }
  }

  // Monday = 1, Sunday = 7 → offset = weekday - 1
  int get _firstDayOffset => DateTime(_year, _month, 1).weekday - 1;

  bool _isToday(String dateStr) {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return dateStr == todayStr;
  }

  String _statusLabel(int status) {
    switch (status) {
      case 2:  return 'Morning + Evening ✓';
      case 1:  return '1 session ✓';
      default: return 'No sessions';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.shade50,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildStreakBadge(),
          const SizedBox(height: 16),
          _buildBody(),
          const SizedBox(height: 10),
          _buildLegend(),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Consistency',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            _arrowButton(Icons.chevron_left,  () => _changeMonth(-1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '${_monthNames[_month]} $_year',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _primaryPink,
                ),
              ),
            ),
            _arrowButton(Icons.chevron_right, () => _changeMonth(1)),
          ],
        ),
      ],
    );
  }

  Widget _arrowButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 20, color: _primaryPink),
      ),
    );
  }

  // ── Streak Badge ──────────────────────────────────────────────────────────
  Widget _buildStreakBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _lightPink),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87),
              children: [
                TextSpan(
                  text: '$_currentStreak',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _primaryPink,
                  ),
                ),
                const TextSpan(
                  text: ' day streak',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(color: _primaryPink)),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.grey),
              const SizedBox(height: 4),
              Text(
                'Could not load data',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              TextButton(
                onPressed: _fetchHeatmap,
                child: const Text('Retry', style: TextStyle(color: _primaryPink)),
              ),
            ],
          ),
        ),
      );
    }

    return _buildCalendarGrid();
  }

  // ── Calendar Grid ─────────────────────────────────────────────────────────
  // ── Calendar Grid ─────────────────────────────────────────────────────────
  Widget _buildCalendarGrid() {
    final int offset     = _firstDayOffset;
    final int totalCells = offset + _days.length;

    // Calculate the exact width so it doesn't stretch across the whole screen
    final double exactGridWidth = (7 * _cellSize) + (6 * _spacing);

    return Center(
      child: SizedBox(
        width: exactGridWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekday labels perfectly aligned above columns
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _weekdayLabels.map((label) {
                return SizedBox(
                  width: _cellSize,
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 8),

            // Compact Wrap grid instead of a stretching GridView
            Wrap(
              spacing: _spacing,
              runSpacing: _spacing,
              children: List.generate(totalCells, (index) {
                // Empty placeholder space for accurate day alignment
                if (index < offset) {
                  return const SizedBox(width: _cellSize, height: _cellSize);
                }

                final day     = _days[index - offset];
                final isToday = _isToday(day.date);

                return Tooltip(
                  message: '${day.date}: ${_statusLabel(day.status)}',
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _cellSize,
                    height: _cellSize,
                    decoration: BoxDecoration(
                      color: _colorForStatus(day.status),
                      shape: BoxShape.circle, // Change to BoxShape.rectangle if you want GitHub squares instead!
                      border: isToday
                          ? Border.all(color: _primaryPink, width: 1.5)
                          : null,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ── Legend ────────────────────────────────────────────────────────────────
  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Less', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(width: 6),
        _legendCircle(_emptyGrey),
        const SizedBox(width: 4),
        _legendCircle(_lightPink),
        const SizedBox(width: 4),
        _legendCircle(_deepPink),
        const SizedBox(width: 6),
        Text('More', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _legendCircle(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}