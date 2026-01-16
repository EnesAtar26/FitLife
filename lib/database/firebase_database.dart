import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseDatabaseService
{

  final String? uid;
  FirebaseDatabaseService({this.uid});

  final CollectionReference userCollection = FirebaseFirestore.instance.collection("users");

  Future updateUserData(String name, int age, bool isMale) async{
    return await userCollection.doc(uid).set({
      "Name" : name,
      "Age" : age,
      "isMale" : isMale
    });
  }
}