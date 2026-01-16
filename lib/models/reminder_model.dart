class Reminder {
  final int? id;
  final int userId;
  final String type;
  final String timeOfDay;
  final int isActive;

  Reminder({
    this.id,
    required this.userId,
    required this.type,
    required this.timeOfDay,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'time_of_day': timeOfDay,
      'is_active': isActive,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      userId: map['user_id'],
      type: map['type'],
      timeOfDay: map['time_of_day'],
      isActive: map['is_active'],
    );
  }
}
