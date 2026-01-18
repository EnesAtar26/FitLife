import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


class Food {
  final String name;
  final int calories;
  final double time;

  Food({
    required this.name,
    required this.calories,
    required this.time
  });

  Map<String, dynamic> toMap() {
    return {
      'Name': name,
      'Calories': calories,
      'Time' : time
    };
  }

  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      name: map['Name'],
      calories: (map['Calories'] as num).toInt(),
      time: (map['Time'] as num).toDouble(),
    );
  }
}

class Activity {
  final String name;
  final int duration;

  Activity({
    required this.name,
    required this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'Name': name,
      'Duration' : duration
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      name: map['Name'],
      duration: (map['Duration'] as num).toInt(),
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
      consumed: map['consumed'],
      target: map['target'],
      unit: map['unit'],
    );
  }
}

class SleepLog {
  final DateTime date;
  final int slepHour;
  final int target;

  SleepLog({
    required this.date,
    required this.slepHour,
    required this.target,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String().substring(0, 10),
      'slepHour': slepHour,
      'target': target,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory SleepLog.fromMap(Map<String, dynamic> map) {
    return SleepLog(
      date: DateTime.parse(map['date']),
      slepHour: map['slepHour'],
      target: map['target'],
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

    WaterLog w = WaterLog(date: DateTime.timestamp(), consumed: 0, target: 10, unit: "Bardak");
    await updateTodayWater(w);

    List<Food> foods = [];
    await updateFoodInfo(foods);

    List<Activity> activities = [];
    await updateActivityInfo(activities);

    SleepLog s = SleepLog(date: DateTime.timestamp(), slepHour: 0, target: 8);
    await updateTodaySleep(s);
  }


  Future<void> updateActivityInfo(List<Activity> activities) async {
    await activityCollection.doc(uid).set({
      'Activities': activities.map((e) => e.toMap()).toList(),
    }, SetOptions(merge: true));
  }

  Future<void> updateTodaySleep(SleepLog log) async {
    final dateId = log.date.toIso8601String().substring(0, 10);

    await sleepCollection
        .doc(dateId)
        .set(log.toMap(), SetOptions(merge: true));
  }


  Future<void> updateTodayWater(WaterLog log) async {
    final dateId = log.date.toIso8601String().substring(0, 10);

    await waterCollection
        .doc(dateId)
        .set(log.toMap(), SetOptions(merge: true));
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
}