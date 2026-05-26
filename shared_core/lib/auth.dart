import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';
import 'repo.dart';

/// Auth state — phone+OTP based. OTP `123456` always accepted (dev/demo).
class Auth extends ChangeNotifier {
  static const _uuid = Uuid();
  static const _prefId = 'current_user_id';

  AppUser? currentUser;

  /// Restore from saved session on app startup.
  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_prefId);
    if (id != null) {
      currentUser = await Repo.instance.findUserById(id);
    }
    notifyListeners();
  }

  /// Verify OTP — returns matching user OR null if no account on this phone.
  /// Throws if the user exists but with a DIFFERENT role (cross-role login attempt).
  Future<AppUser?> verifyOtpAndLogin({required String phone, required String code, required UserRole expectedRole}) async {
    if (code.trim() != '123456') throw 'Invalid OTP. Use 123456 for demo.';
    final u = await Repo.instance.findUserByPhone(phone);
    if (u == null) return null;
    if (u.role != expectedRole) {
      throw 'This phone is registered as ${u.role.name}. Open the correct app.';
    }
    await _saveSession(u);
    return u;
  }

  /// Create an account (role-locked to whichever app is running).
  Future<AppUser> register({
    required String phone, required String fullName, String? email, required String address,
    required UserRole role, required List<EngineType> engineTypes,
    List<String> specialties = const [], String? tradeLicenseUrl, String? nationalIdUrl,
    List<String> workshopPhotoUrls = const [],
  }) async {
    final existing = await Repo.instance.findUserByPhone(phone);
    if (existing != null) {
      if (existing.role != role) throw 'This phone is already registered as ${existing.role.name}.';
      await _saveSession(existing);
      return existing;
    }
    final u = AppUser(
      id: _uuid.v4(), fullName: fullName, phone: phone, email: email,
      role: role, address: address, language: 'en', engineTypes: engineTypes,
      specialties: specialties, tradeLicenseUrl: tradeLicenseUrl, nationalIdUrl: nationalIdUrl,
      workshopPhotoUrls: workshopPhotoUrls,
      kycVerified: role == UserRole.customer, // customers auto-verified
    );
    final saved = await Repo.instance.upsertUser(u);
    await _saveSession(saved);
    return saved;
  }

  Future<void> refresh() async {
    if (currentUser == null) return;
    final u = await Repo.instance.findUserById(currentUser!.id);
    if (u != null) {
      currentUser = u;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefId);
    notifyListeners();
  }

  Future<void> _saveSession(AppUser u) async {
    currentUser = u;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefId, u.id);
    notifyListeners();
  }
}
