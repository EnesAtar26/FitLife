import '../database/database_helper.dart';
import '../models/user_model.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../services/session_manager.dart';


class AuthService {
  final db = DatabaseHelper.instance;

  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<String?> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final existingUser = await db.getUserByEmail(email);

    if (existingUser != null) {
      return 'Bu email zaten kayıtlı';
    }

    final user = User(
      firstName: firstName,
      lastName: lastName,
      email: email,
      passwordHash: hashPassword(password),
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    final userId = await db.createUser(user);
    await SessionManager.saveUserId(userId);

    return null; // başarı
  }

  Future<User?> login({
    required String email,
    required String password,
  }) async {
    final user = await db.getUserByEmail(email);

    if (user == null) return null;

    final hashedInput = hashPassword(password);

    if (hashedInput != user.passwordHash) return null;
    await SessionManager.saveUserId(user.id!);
    return user;
  }

}
