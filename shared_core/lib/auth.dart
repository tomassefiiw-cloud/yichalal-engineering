import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';
import 'repo.dart';

/// Auth state — phone+OTP based. OTP `123456` always accepted (dev/demo).
class Auth extends ChangeNotifier {
  static const _uuid = Uuid();
  static const _prefId = 'current_user_id';

  AppUser? currentUser;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_prefId);
    if (id != null) {
      try {
        currentUser = await Repo.instance.findUserById(id);
        // If user not found (deleted from DB), clear stale session so the
        // user lands on the auth screen instead of seeing FK errors later.
        if (currentUser == null) {
          await prefs.remove(_prefId);
        }
      } catch (_) {
        await prefs.remove(_prefId);
      }
    }
    notifyListeners();
  }

  /// Verify OTP — returns matching user OR null if no account on this phone.
  /// Throws if the user exists but with a DIFFERENT role (cross-role login attempt).
  Future<AppUser?> verifyOtpAndLogin({required String phone, required String code, required UserRole expectedRole}) async {
    if (code.trim() != '123456') throw 'Invalid OTP. Use 123456 for demo.';
    final AppUser? u;
    try {
      u = await Repo.instance.findUserByPhone(phone);
    } on PostgrestException catch (e) {
      throw _humanError(e);
    } catch (e) {
      throw 'Could not reach server. Check your internet connection.';
    }
    if (u == null) return null;
    if (u.role != expectedRole) {
      throw 'This phone is registered as ${u.role.name}. Open the correct app.';
    }
    await _saveSession(u);
    return u;
  }

  /// Create an account (role-locked to whichever app is running).
  ///
  /// The local session is only saved AFTER Supabase confirms the row is
  /// actually persisted. If the insert silently fails, we throw instead of
  /// leaving a phantom session that would later cause FK errors when the
  /// user tries to add a vehicle / book a service.
  Future<AppUser> register({
    required String phone, required String fullName, String? email, required String address,
    required UserRole role, required List<EngineType> engineTypes,
    List<String> specialties = const [], String? tradeLicenseUrl, String? nationalIdUrl,
    List<String> workshopPhotoUrls = const [],
  }) async {
    try {
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
      AppUser saved;
      try {
        saved = await Repo.instance.upsertUser(u);
      } on PostgrestException catch (e) {
        throw _humanError(e);
      }
      // Verify the row actually made it (defends against silent RLS rejects).
      final readBack = await Repo.instance.findUserById(saved.id);
      if (readBack == null) {
        throw 'Account could not be created. The server accepted the request but no row was stored — check Supabase RLS / schema.';
      }
      await _saveSession(readBack);
      return readBack;
    } on PostgrestException catch (e) {
      throw _humanError(e);
    } catch (e) {
      if (e is String) rethrow;
      throw 'Sign-up failed: $e';
    }
  }

  /// Re-create the current user's profile row in Supabase if missing.
  /// Returns true if the row exists (or was successfully recreated).
  /// Called automatically by repo when an FK error is detected on writes.
  Future<bool> ensureProfileExists() async {
    final u = currentUser;
    if (u == null) return false;
    try {
      final existing = await Repo.instance.findUserById(u.id);
      if (existing != null) return true;
      // Profile missing — recreate from in-memory user.
      await Repo.instance.upsertUser(u);
      // Verify it actually landed.
      final after = await Repo.instance.findUserById(u.id);
      return after != null;
    } catch (_) {
      return false;
    }
  }

  String _humanError(PostgrestException e) {
    final msg = e.message;
    if (e.code == 'PGRST205' || msg.contains("Could not find the table")) {
      return 'Server not initialised yet. Admin needs to run supabase/schema.sql once.';
    }
    if (msg.contains('duplicate key') && msg.contains('phone')) {
      return 'This phone number is already registered.';
    }
    return 'Server error: $msg';
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
