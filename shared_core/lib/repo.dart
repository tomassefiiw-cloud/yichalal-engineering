import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'config.dart';
import 'models.dart';

/// Single source of truth for all Supabase reads & writes.
/// Streams use Realtime subscriptions so both apps see live updates.
class Repo {
  Repo._();
  static final Repo instance = Repo._();
  static const _uuid = Uuid();

  late final SupabaseClient _sb;

  Future<void> init() async {
    await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
    _sb = Supabase.instance.client;
  }

  // ── Users / Profiles ───────────────────────────────────────────────
  Future<AppUser?> findUserByPhone(String phone) async {
    final rows = await _sb.from('profiles').select().eq('phone', phone).limit(1);
    return rows.isEmpty ? null : AppUser.fromRow(rows.first);
  }

  Future<AppUser?> findUserById(String id) async {
    final rows = await _sb.from('profiles').select().eq('id', id).limit(1);
    return rows.isEmpty ? null : AppUser.fromRow(rows.first);
  }

  Future<AppUser> upsertUser(AppUser u) async {
    final row = await _sb.from('profiles').upsert(u.toInsert()).select().single();
    return AppUser.fromRow(row);
  }

  Future<List<AppUser>> mechanics({bool onlyVerified = false}) async {
    var q = _sb.from('profiles').select().eq('role', 'mechanic');
    if (onlyVerified) q = q.eq('kyc_verified', true);
    final rows = await q;
    return rows.map((r) => AppUser.fromRow(r)).toList();
  }

  Future<List<AppUser>> allUsers() async {
    final rows = await _sb.from('profiles').select();
    return rows.map((r) => AppUser.fromRow(r)).toList();
  }

  // ── Vehicles ───────────────────────────────────────────────────────
  Future<Vehicle> upsertVehicle(Vehicle v) async {
    final row = await _sb.from('vehicles').upsert(v.toInsert()).select().single();
    return Vehicle.fromRow(row);
  }

  Future<List<Vehicle>> vehiclesOf(String ownerId) async {
    final rows = await _sb.from('vehicles').select().eq('owner_id', ownerId).order('created_at', ascending: false);
    return rows.map((r) => Vehicle.fromRow(r)).toList();
  }

  Future<Vehicle?> vehicle(String id) async {
    final rows = await _sb.from('vehicles').select().eq('id', id).limit(1);
    return rows.isEmpty ? null : Vehicle.fromRow(rows.first);
  }

  /// Realtime stream of a customer's vehicles — newest first.
  Stream<List<Vehicle>> vehiclesStreamOf(String ownerId) =>
      _sb.from('vehicles').stream(primaryKey: ['id']).eq('owner_id', ownerId)
          .order('created_at', ascending: false)
          .map((rows) => rows.map((r) => Vehicle.fromRow(r)).toList());

  // ── Bookings ───────────────────────────────────────────────────────
  Future<Booking> upsertBooking(Booking b) async {
    final row = await _sb.from('bookings').upsert(b.toInsert()).select().single();
    return Booking.fromRow(row);
  }

  Future<Booking?> booking(String id) async {
    final rows = await _sb.from('bookings').select().eq('id', id).limit(1);
    return rows.isEmpty ? null : Booking.fromRow(rows.first);
  }

  Stream<Booking?> bookingStream(String id) =>
      _sb.from('bookings').stream(primaryKey: ['id']).eq('id', id)
          .map((rows) => rows.isEmpty ? null : Booking.fromRow(rows.first));

  Stream<List<Booking>> bookingsForCustomer(String customerId) =>
      _sb.from('bookings').stream(primaryKey: ['id']).eq('customer_id', customerId)
          .order('created_at', ascending: false)
          .map((rows) => rows.map((r) => Booking.fromRow(r)).toList());

  Stream<List<Booking>> bookingsForMechanic(String mechanicId) =>
      _sb.from('bookings').stream(primaryKey: ['id']).eq('mechanic_id', mechanicId)
          .order('created_at', ascending: false)
          .map((rows) => rows.map((r) => Booking.fromRow(r)).toList());

  Stream<List<Booking>> pendingBookingsUnassigned() =>
      _sb.from('bookings').stream(primaryKey: ['id']).eq('status', 'pending')
          .order('created_at', ascending: false)
          .map((rows) => rows.map((r) => Booking.fromRow(r)).where((b) => b.mechanicId == null).toList());

  // ── Chats ──────────────────────────────────────────────────────────
  Future<ChatMessage> sendChat(String bookingId, String senderId, String text) async {
    final msg = ChatMessage(id: _uuid.v4(), bookingId: bookingId, senderId: senderId, text: text);
    await _sb.from('chats').insert(msg.toInsert());
    return msg;
  }

  /// Returns chat messages oldest → newest so the UI shows newest at bottom.
  Stream<List<ChatMessage>> chatStream(String bookingId) =>
      _sb.from('chats').stream(primaryKey: ['id']).eq('booking_id', bookingId)
          .order('ts', ascending: true)
          .map((rows) => rows.map((r) => ChatMessage.fromRow(r)).toList());

  // ── Wallet ─────────────────────────────────────────────────────────
  Future<void> creditWallet(String userId, double amount, String description) async {
    await _sb.from('wallet_txns').insert(WalletTxn(id: _uuid.v4(), userId: userId, amount: amount, description: description).toInsert());
    final u = await findUserById(userId);
    if (u != null) {
      await _sb.from('profiles').update({'wallet_balance': u.walletBalance + amount}).eq('id', userId);
    }
  }

  Stream<List<WalletTxn>> txnsStream(String userId) =>
      _sb.from('wallet_txns').stream(primaryKey: ['id']).eq('user_id', userId)
          .order('ts', ascending: false)
          .map((rows) => rows.map((r) => WalletTxn.fromRow(r)).toList());

  // ── Notifications ──────────────────────────────────────────────────
  Future<void> notify(String userId, String title, String body, {String? bookingId}) async {
    await _sb.from('notifications').insert(AppNotification(
      id: _uuid.v4(), userId: userId, title: title, body: body, bookingId: bookingId,
    ).toInsert());
  }

  Stream<List<AppNotification>> notificationsStream(String userId) =>
      _sb.from('notifications').stream(primaryKey: ['id']).eq('user_id', userId)
          .order('ts', ascending: false)
          .map((rows) => rows.map((r) => AppNotification.fromRow(r)).toList());

  Future<void> markNotificationRead(String id) async {
    await _sb.from('notifications').update({'read': true}).eq('id', id);
  }

  // ── Service records / diagnoses ───────────────────────────────────
  Future<void> addServiceRecord(String vehicleId, String title, String details, double cost, int? mileageAt) async {
    await _sb.from('service_records').insert({
      'id': _uuid.v4(), 'vehicle_id': vehicleId, 'title': title, 'details': details, 'cost': cost, 'mileage_at': mileageAt,
    });
  }

  Future<List<Map<String, dynamic>>> servicesOf(String vehicleId) async =>
      await _sb.from('service_records').select().eq('vehicle_id', vehicleId).order('date', ascending: false);

  Future<void> addDiagnosis(String vehicleId, String symptom, String probableCause, String severity, String estimatedRepair, double min, double max) async {
    await _sb.from('diagnoses').insert({
      'id': _uuid.v4(), 'vehicle_id': vehicleId, 'symptom': symptom,
      'probable_cause': probableCause, 'severity': severity, 'estimated_repair': estimatedRepair,
      'estimated_cost_min': min, 'estimated_cost_max': max,
    });
  }

  Future<List<Map<String, dynamic>>> diagnosesOf(String vehicleId) async =>
      await _sb.from('diagnoses').select().eq('vehicle_id', vehicleId).order('date', ascending: false);

  // ── Inventory ──────────────────────────────────────────────────────
  Future<void> upsertInventory(InventoryItem i) async {
    await _sb.from('inventory').upsert(i.toInsert());
  }
  Stream<List<InventoryItem>> inventoryStream(String mechanicId) =>
      _sb.from('inventory').stream(primaryKey: ['id']).eq('mechanic_id', mechanicId)
          .map((rows) => rows.map((r) => InventoryItem.fromRow(r)).toList());

  // ── Profile updates ────────────────────────────────────────────────
  Future<void> updateUserLocation(String userId, double lat, double lng) async {
    await _sb.from('profiles').update({'lat': lat, 'lng': lng}).eq('id', userId);
  }
  Future<void> updateUserOnline(String userId, bool online) async {
    await _sb.from('profiles').update({'is_online': online}).eq('id', userId);
  }
  /// Returns null if the Supabase project is properly set up, otherwise a
  /// human-readable error explaining what's missing.
  Future<String?> healthCheck() async {
    try {
      await _sb.from('profiles').select('id').limit(1);
      return null;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205') {
        return 'Server is not initialised. Please run supabase/schema.sql in your Supabase SQL editor (one-time setup).';
      }
      return 'Server error: ${e.message}';
    } catch (e) {
      return 'Cannot reach server. Check your internet connection.';
    }
  }

}
