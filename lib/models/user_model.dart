class User {
  final int? id;
  final String firstName;
  final String lastName;
  final String email;
  final String passwordHash;
  final int? age;
  final int? heightCm;
  final int? weightKg;
  final String? gender;
  final String? goalType;
  final int? dailyStepGoal;
  final int? dailyCalorieGoal;
  final int? dailyWaterGoal;
  final int? sleepGoalMinutes;
  final String? createdAt;
  final String? updatedAt;
  //final int? streakCount;   EKLENMELİ DB NASIL BİLMİYORUM

  User({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.passwordHash,
    this.age,
    this.heightCm,
    this.weightKg,
    this.gender,
    this.goalType,
    this.dailyStepGoal,
    this.dailyCalorieGoal,
    this.dailyWaterGoal,
    this.sleepGoalMinutes,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password_hash': passwordHash,
      'age': age,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'gender': gender,
      'goal_type': goalType,
      'daily_step_goal': dailyStepGoal,
      'daily_calorie_goal': dailyCalorieGoal,
      'daily_water_goal': dailyWaterGoal,
      'sleep_goal_minutes': sleepGoalMinutes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      email: map['email'],
      passwordHash: map['password_hash'],
      age: map['age'],
      heightCm: map['height_cm'],
      weightKg: map['weight_kg'],
      gender: map['gender'],
      goalType: map['goal_type'],
      dailyStepGoal: map['daily_step_goal'],
      dailyCalorieGoal: map['daily_calorie_goal'],
      dailyWaterGoal: map['daily_water_goal'],
      sleepGoalMinutes: map['sleep_goal_minutes'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
}
