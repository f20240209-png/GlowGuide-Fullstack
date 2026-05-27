class HeatmapDay {
  final String date;       // "2026-05-01"
  final int    dayNumber;  // 1–31
  final int    status;     // 0, 1, or 2

  const HeatmapDay({
    required this.date,
    required this.dayNumber,
    required this.status,
  });

  factory HeatmapDay.fromJson(Map<String, dynamic> json) {
    return HeatmapDay(
      date:      json['date']      as String,
      dayNumber: json['dayNumber'] as int,
      status:    json['status']    as int,
    );
  }
}