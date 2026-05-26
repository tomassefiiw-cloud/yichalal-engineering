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
        if (currentUser == null) {
          // session id is stale — clear so user lands on auth screen
          await prefs.remove(_prefId);
        }
      } catch (_) {
        await prefs.remove(_prefId);
      }
    }
    notifyListeners();
  }

  /// Verify OTP. Returns matching user OR null if no account on this phone.
  /// Throws if the user exists but with a DIFFERENT role.
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

  /// Create an account. Role-locked to whichever app is running.
  ///
  /// Persists the profile to Supabase AND verifies the row landed before
  /// saving the local session — so a phantom session that would later cause
  /// FK errors when adding a vehicle is impossible.
  Future<AppUser> register({
    required String phone, required String fullName, String? email, required String address,
    required UserRole role, required List<EngineType> engineTypes,
    List<String> specialties = const [], String? tradeLicenseUrl, String? nationalIdUrl,
    List<String> workshopPhotoUrls = const [],
  }) async {
    try {
      // If a profile already exists for this phone, just resume that session.
      final existing = await Repo.instance.findUserByPhone(phone);
      if (existing != null) {
        if (existing.role != role) {
          throw 'This phone is already registered as ${existing.role.name}.';
        }
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
      // Verify row actually persisted (defends against silent RLS rejects).
      final readBack = await Repo.instance.findUserById(saved.id);
      if (readBack == null) {
        throw 'Account could not be created on the server. Please run supabase/schema.sql in your Supabase project.';
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

  /// Make sure the current user's profile row really exists in Supabase.
  ///
  /// 3-step strategy (handles every failure mode I've seen in production):
  ///   1. Look up by id           → if found, done.
  ///   2. Look up by PHONE        → if found, sync local session to that
  ///      row's id and return true. (Handles case where the local session
  ///      drifted away from the actual server id — e.g. user re-signed-up
  ///      on a different device.)
  ///   3. Insert a fresh row      → upsert in-memory user, verify it landed.
  ///
  /// Returns true if the profile is confirmed to exist on the server after
  /// this call, false otherwise.
  Future<bool> ensureProfileExists() async {
    final u = currentUser;
    if (u == null) return false;
    try {
      // Step 1: by id
      var existing = await Repo.instance.findUserById(u.id);
      if (existing != null) return true;

      // Step 2: by phone — maybe the server id is different from ours
      existing = await Repo.instance.findUserByPhone(u.phone);
      if (existing != null) {
        // Adopt the server's row id so future writes (vehicles, bookings)
        // pass FK checks. Update local session to match.
        await _saveSession(existing);
        return true;
      }

      // Step 3: create fresh
      await Repo.instance.upsertUser(u);
      final after = await Repo.instance.findUserById(u.id);
      if (after != null) return true;
      // Fall back: maybe the id was reassigned — look up by phone again
      final byPhone = await Repo.instance.findUserByPhone(u.phone);
      if (byPhone != null) {
        await _saveSession(byPhone);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  String _humanError(PostgrestException e) {
    final msg = e.message;
    if (e.code == 'PGRST205' || msg.contains("Could not find the table")) {
      return 'Server is not initialised. Admin needs to run supabase/schema.sql in the Supabase SQL editor.';
    }
    if (msg.contains('duplicate key') && msg.contains('phone')) {
      return 'This phone number is already registered.';
    }
    return 'Server error: $msg';
  }

  Future<void> refresh() async {
    if (currentUser == null) return;
    try {
      final u = await Repo.instance.findUserById(currentUser!.id);
      if (u != null) {
        currentUser = u;
        notifyListeners();
      }
    } catch (_) {/* network blip — keep cached user */}
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
