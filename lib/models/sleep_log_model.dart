class SleepLog {
  final int? id;
  final int userId;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final String date;

  SleepLog({
    this.id,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'start_time': startTime,
      'end_time': endTime,
      'duration_minutes': durationMinutes,
      'date': date,
    };
  }

  factory SleepLog.fromMap(Map<String, dynamic> map) {
    return SleepLog(
      id: map['id'],
      userId: map['user_id'],
      startTime: map['start_time'],
      endTime: map['end_time'],
      durationMinutes: map['duration_minutes'],
      date: map['date'],
    );
  }
}
