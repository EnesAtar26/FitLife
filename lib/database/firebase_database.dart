import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_6/models/activity_model.dart';



class Food {
  final DateTime date;
  final String name;
  final int calories;

  Food({
    required this.date,
    required this.name,
    required this.calories
  });

  Map<String, dynamic> toMap() {
    return {
      'Date' : date,
      'Name': name,
      'Calories': calories
    };
  }

  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      date: DateTime.parse(map['date']),
      name: map['Name'],
      calories: (map['Calories'] as num).toInt(),
    );
  }
}

class WaterLog {
  final DateTime date;
  final int consumed;   // örn: 1800
  final int target;     // örn: 2500
  final String unit;    // "ml" / "liter"

  WaterLog({
    required this.date,
    required this.consumed,
    required this.target,
    required this.unit,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String().substring(0, 10),
      'consumed': consumed,
      'target': target,
      'unit': unit,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory WaterLog.fromMap(Map<String, dynamic> map) {
    return WaterLog(
      date: DateTime.parse(map['date']),
      consumed: (map['consumed'] as num).toInt(),
      target: (map['target'] as num).toInt(),
      unit: map['unit'],
    );
  }
}

class SleepLog {
  final DateTime date;
  final double sleepHour;
  final double target;

  SleepLog({
    required this.date,
    required this.sleepHour,
    required this.target,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String().substring(0, 10),
      'sleepHour': sleepHour,
      'target': target,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory SleepLog.fromMap(Map<String, dynamic> map) {
    return SleepLog(
      date: DateTime.parse(map['date']),
      sleepHour: (map['sleepHour'] as num).toDouble(),
      target: (map['target'] as num).toDouble()
    );
  }
}


class FirebaseDatabaseService
{

  final String? uid;
  FirebaseDatabaseService({this.uid});


  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get userDoc =>
      _db.collection('users').doc(uid).collection('profile');

  CollectionReference get bodyCollection =>
  _db.collection('users').doc(uid).collection('body');

  CollectionReference get waterCollection =>
  _db.collection('users').doc(uid).collection('water');

  CollectionReference get sleepCollection =>
  _db.collection('users').doc(uid).collection('sleep');

  CollectionReference get activityCollection =>
  _db.collection('users').doc(uid).collection('activity');

  CollectionReference get foodCollection =>
  _db.collection('users').doc(uid).collection('food');

  CollectionReference get miscCollection =>
  _db.collection('users').doc(uid).collection('misc');

  CollectionReference get notificationWater =>
  _db.collection('users').doc(uid)
      .collection('notifications').doc('water').collection('logs');

  CollectionReference get notificationSleep =>
  _db.collection('users').doc(uid)
      .collection('notifications').doc('sleep').collection('logs');

  CollectionReference get notificationGeneral =>
  _db.collection('users').doc(uid)
      .collection('notifications').doc('general').collection('logs');



  Future<void> registerUserData(String name, String lastName) async{
    await updateAccountInfo(name, lastName, DateTime.timestamp(), "Belirtmek istemiyorum");
    await updateBodyInfo(20, 170, 80, false, false, "Az Hareketli");
    await updateNotificationSettingsInfo(true, false, true);
    await updateMiscInfo(0, 1000, 0, 1700);
    await updateWaterNotificationInfo(false, TimeOfDay.fromDateTime(DateTime.timestamp()), 3);
    await updateSleepNotificationInfo(false, TimeOfDay.fromDateTime(DateTime.timestamp()), 8, 0);
    await updateTodayWater(0, 8);
    await updateTodaySleep(0);

    List<Food> foods = [];
    await updateFoodInfo(foods);

    List<Activity> activities = [];
    await updateActivityInfo(activities);
  }


  Future<void> updateActivityInfo(List<Activity> activities) async {
    await activityCollection.doc(uid).set({
      'Activities': activities.map((e) => e.toMap()).toList(),
    }, SetOptions(merge: true));
  }

  Future<void> updateTodaySleep(double sleepHour) async {
    SleepLog s = SleepLog(date: DateTime.timestamp(), sleepHour: sleepHour, target: 8);
    final dateId = s.date.toIso8601String().substring(0, 10);

    await sleepCollection
        .doc(dateId)
        .set(s.toMap(), SetOptions(merge: true));
  }


  Future<void> updateTodayWater(int c, int t) async {
    WaterLog w = WaterLog(date: DateTime.timestamp(), consumed: c, target: t, unit: "Bardak");
    final dateId = w.date.toIso8601String().substring(0, 10);

    await waterCollection
        .doc(dateId)
        .set(w.toMap(), SetOptions(merge: true));
  }

  Future<void> updateFoodInfo(List<Food> foods) async {
    await foodCollection.doc(uid).set({
      'Foods': foods.map((e) => e.toMap()).toList(),
    }, SetOptions(merge: true));
  }


  Future updateSleepNotificationInfo(bool isEnabled, TimeOfDay sleepStartTime, int sleepHour, int sleepMinute) async{
    return await notificationSleep.doc(uid).set({
      "isEnabled" : isEnabled,
      "FirstNotificationTime" : {
        "hour": sleepStartTime.hour,
        "minute": sleepStartTime.minute,
      },
      "SleepHour" : sleepHour,
      "SleepMinute" : sleepMinute
    });
  }

  Future updateWaterNotificationInfo(bool isEnabled, TimeOfDay firstNotificationTime, int interval) async{
    return await notificationWater.doc(uid).set({
      "isEnabled" : isEnabled,
      "FirstNotificationTime" : {
        "hour": firstNotificationTime.hour,
        "minute": firstNotificationTime.minute,
      },
      "Interval" : interval
    });
  }

  Future updateMiscInfo(int steps, int steps_target, int streak, int calory_target) async{
    return await miscCollection.doc(uid).set({
      "Steps" : steps,
      "StepsTarget" : steps_target,
      "Streak" : streak,
      "CaloryTarget" : calory_target
    });
  }

  Future updateNotificationSettingsInfo(bool waterNtfy, bool activityNtfy, bool sleepNtfy) async{
    return await notificationGeneral.doc(uid).set({
      "WaterNtf" : waterNtfy,
      "SleepNtf" : sleepNtfy,
      "ActivityNtf" : activityNtfy
    });
  }

  Future updateBodyInfo(int age, double height, double weight, bool smoke, bool alcohol, String bodyType) async{
    return await bodyCollection.doc(uid).set({
      "Age" : age,
      "Height" : height,
      "Weight" : weight,
      "isSmoking" : smoke,
      "isUsingAlcohol" : alcohol,
      "BodyType" : bodyType
    });
  }

  // Only For Firestore
  Future updateAccountInfo(String name, String surname, DateTime birth, String gender) async{
    return await userDoc.doc(uid).set({
      "Name" : name,
      "Surname" : surname,
      "BirthDate" : birth,
      "Gender" : gender
    });
  }

  //------------------------------

  Future<List<double>> getWeeklySleep() async {
    final now = DateTime.now();
    final start =
    now.subtract(const Duration(days: 6)).toIso8601String().substring(0, 10);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sleep')
        .where('date', isGreaterThanOrEqualTo: start)
        .orderBy('date')
        .get();

    var sleeps = snapshot.docs
        .map((e) => SleepLog.fromMap(e.data()))
        .toList();

    return sleeps.map((item) => item.sleepHour).toList();
  }


}