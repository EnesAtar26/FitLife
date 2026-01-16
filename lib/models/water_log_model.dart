class WaterLog {
  final int? id;
  final int userId;
  final String date;
  final int amountGlasses;
  final String timestamp;

  WaterLog({
    this.id,
    required this.userId,
    required this.date,
    required this.amountGlasses,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': date,
      'amount_glasses': amountGlasses,
      'timestamp': timestamp,
    };
  }

  factory WaterLog.fromMap(Map<String, dynamic> map) {
    return WaterLog(
      id: map['id'],
      userId: map['user_id'],
      date: map['date'],
      amountGlasses: map['amount_glasses'],
      timestamp: map['timestamp'],
    );
  }
}
