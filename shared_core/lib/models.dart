// ignore_for_file: constant_identifier_names
enum UserRole { customer, mechanic, admin }
enum EngineType { gasoline, diesel, hybrid, electric }
enum ServiceType { emergency_roadside, at_home, workshop, scheduled_maintenance, detailing, custom }
enum BookingStatus { pending, accepted, enroute, inprogress, completed, cancelled, declined }
enum PaymentMethod { telebirr, cbe_birr, amole, cash, wallet }
enum PaymentStatus { unpaid, held_in_escrow, paid, refunded }

String labelOf(ServiceType t) {
  switch (t) {
    case ServiceType.emergency_roadside: return 'Emergency Roadside';
    case ServiceType.at_home: return 'At-Home Repair';
    case ServiceType.workshop: return 'Workshop Visit';
    case ServiceType.scheduled_maintenance: return 'Scheduled Maintenance';
    case ServiceType.detailing: return 'Detailing';
    case ServiceType.custom: return 'Custom Job';
  }
}

class AppUser {
  final String id;
  final String fullName, phone;
  final String? email;
  final UserRole role;
  final String address, language;
  final List<EngineType> engineTypes;
  final bool kycVerified;
  final String? tradeLicenseUrl, nationalIdUrl;
  final List<String> workshopPhotoUrls, specialties;
  final double walletBalance;
  final double? lat, lng;
  final bool isOnline;
  final DateTime createdAt;

  AppUser({
    required this.id, required this.fullName, required this.phone, required this.role,
    this.email, this.address = '', this.language = 'en',
    this.engineTypes = const [], this.kycVerified = false,
    this.tradeLicenseUrl, this.nationalIdUrl,
    this.workshopPhotoUrls = const [], this.specialties = const [],
    this.walletBalance = 0, this.lat, this.lng, this.isOnline = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toInsert() => {
    'id': id, 'full_name': fullName, 'phone': phone, 'email': email,
    'role': role.name, 'address': address, 'language': language,
    'engine_types': engineTypes.map((e) => e.name).toList(),
    'kyc_verified': kycVerified,
    'trade_license_url': tradeLicenseUrl, 'national_id_url': nationalIdUrl,
    'workshop_photo_urls': workshopPhotoUrls,
    'specialties': specialties,
    'wallet_balance': walletBalance, 'lat': lat, 'lng': lng,
    'is_online': isOnline,
  };

  AppUser copyWith({String? fullName, String? email, String? address, String? language,
      bool? kycVerified, double? walletBalance, double? lat, double? lng, bool? isOnline,
      List<String>? specialties, List<EngineType>? engineTypes}) =>
    AppUser(
      id: id, fullName: fullName ?? this.fullName, phone: phone, email: email ?? this.email,
      role: role, address: address ?? this.address, language: language ?? this.language,
      engineTypes: engineTypes ?? this.engineTypes,
      kycVerified: kycVerified ?? this.kycVerified,
      tradeLicenseUrl: tradeLicenseUrl, nationalIdUrl: nationalIdUrl,
      workshopPhotoUrls: workshopPhotoUrls, specialties: specialties ?? this.specialties,
      walletBalance: walletBalance ?? this.walletBalance, lat: lat ?? this.lat, lng: lng ?? this.lng,
      isOnline: isOnline ?? this.isOnline, createdAt: createdAt,
    );

  static AppUser fromRow(Map<String, dynamic> m) => AppUser(
    id: m['id'], fullName: m['full_name'] ?? '', phone: m['phone'] ?? '',
    email: m['email'], role: UserRole.values.firstWhere((r) => r.name == (m['role'] ?? 'customer'), orElse: () => UserRole.customer),
    address: m['address'] ?? '', language: m['language'] ?? 'en',
    engineTypes: ((m['engine_types'] as List?) ?? []).map((e) => EngineType.values.firstWhere((x) => x.name == e, orElse: () => EngineType.gasoline)).toList(),
    kycVerified: m['kyc_verified'] ?? false,
    tradeLicenseUrl: m['trade_license_url'], nationalIdUrl: m['national_id_url'],
    workshopPhotoUrls: ((m['workshop_photo_urls'] as List?) ?? []).cast<String>(),
    specialties: ((m['specialties'] as List?) ?? []).cast<String>(),
    walletBalance: (m['wallet_balance'] ?? 0).toDouble(),
    lat: m['lat'] is num ? (m['lat'] as num).toDouble() : null,
    lng: m['lng'] is num ? (m['lng'] as num).toDouble() : null,
    isOnline: m['is_online'] ?? true,
    createdAt: DateTime.tryParse(m['created_at'] ?? '') ?? DateTime.now(),
  );
}

class Vehicle {
  final String id, ownerId, make, model, plateNumber;
  final int year;
  final String? vin, color, photoUrl;
  final EngineType engineType;
  final int? mileage;
  final DateTime createdAt;
  Vehicle({required this.id, required this.ownerId, required this.make, required this.model, required this.year,
    required this.engineType, required this.plateNumber, this.vin, this.color, this.mileage, this.photoUrl, DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now();
  String get title => '$year $make $model';
  Map<String, dynamic> toInsert() {
    // Only include non-null optional columns so a missing/cached-out optional
    // column in Supabase (e.g. photo_url) doesn't break the insert.
    final m = <String, dynamic>{
      'id': id, 'owner_id': ownerId, 'make': make, 'model': model, 'year': year,
      'engine_type': engineType.name, 'plate_number': plateNumber,
    };
    if (vin != null && vin!.trim().isNotEmpty) m['vin'] = vin;
    if (color != null && color!.trim().isNotEmpty) m['color'] = color;
    if (mileage != null) m['mileage'] = mileage;
    if (photoUrl != null && photoUrl!.trim().isNotEmpty) m['photo_url'] = photoUrl;
    return m;
  }
  static Vehicle fromRow(Map<String, dynamic> m) => Vehicle(
    id: m['id'], ownerId: m['owner_id'], make: m['make'] ?? '', model: m['model'] ?? '',
    year: m['year'] ?? DateTime.now().year, vin: m['vin'],
    engineType: EngineType.values.firstWhere((x) => x.name == (m['engine_type'] ?? 'gasoline'), orElse: () => EngineType.gasoline),
    plateNumber: m['plate_number'] ?? '', color: m['color'], mileage: m['mileage'], photoUrl: m['photo_url'],
    createdAt: DateTime.tryParse(m['created_at'] ?? '') ?? DateTime.now());
}

class Booking {
  final String id, customerId, vehicleId, description, address;
  final String? mechanicId, review, mechanicReply;
  final ServiceType serviceType;
  final List<String> photoUrls;
  final DateTime scheduledAt, createdAt, updatedAt;
  final double lat, lng, laborCost, partsCost, serviceFee, total, rating;
  final BookingStatus status;
  final PaymentMethod? paymentMethod;
  final PaymentStatus paymentStatus;

  Booking({required this.id, required this.customerId, this.mechanicId, required this.vehicleId,
    required this.serviceType, required this.description, this.photoUrls = const [],
    required this.scheduledAt, required this.address, required this.lat, required this.lng,
    this.status = BookingStatus.pending, this.paymentMethod, this.paymentStatus = PaymentStatus.unpaid,
    this.laborCost = 0, this.partsCost = 0, this.serviceFee = 0, this.total = 0,
    this.rating = 0, this.review, this.mechanicReply, DateTime? createdAt, DateTime? updatedAt})
    : createdAt = createdAt ?? DateTime.now(), updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toInsert() => {
    'id': id, 'customer_id': customerId, 'mechanic_id': mechanicId, 'vehicle_id': vehicleId,
    'service_type': serviceType.name, 'description': description, 'photo_urls': photoUrls,
    'scheduled_at': scheduledAt.toUtc().toIso8601String(),
    'address': address, 'lat': lat, 'lng': lng, 'status': status.name,
    'payment_method': paymentMethod?.name, 'payment_status': paymentStatus.name,
    'labor_cost': laborCost, 'parts_cost': partsCost, 'service_fee': serviceFee,
    'total': total, 'rating': rating, 'review': review, 'mechanic_reply': mechanicReply,
  };

  Booking copyWith({String? mechanicId, BookingStatus? status, PaymentMethod? paymentMethod,
      PaymentStatus? paymentStatus, double? laborCost, double? partsCost, double? serviceFee,
      double? total, double? rating, String? review, String? mechanicReply}) =>
    Booking(id: id, customerId: customerId, mechanicId: mechanicId ?? this.mechanicId,
      vehicleId: vehicleId, serviceType: serviceType, description: description, photoUrls: photoUrls,
      scheduledAt: scheduledAt, address: address, lat: lat, lng: lng,
      status: status ?? this.status, paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      laborCost: laborCost ?? this.laborCost, partsCost: partsCost ?? this.partsCost,
      serviceFee: serviceFee ?? this.serviceFee, total: total ?? this.total,
      rating: rating ?? this.rating, review: review ?? this.review, mechanicReply: mechanicReply ?? this.mechanicReply,
      createdAt: createdAt, updatedAt: DateTime.now());

  static Booking fromRow(Map<String, dynamic> m) => Booking(
    id: m['id'], customerId: m['customer_id'], mechanicId: m['mechanic_id'],
    vehicleId: m['vehicle_id'],
    serviceType: ServiceType.values.firstWhere((x) => x.name == (m['service_type'] ?? 'workshop'), orElse: () => ServiceType.workshop),
    description: m['description'] ?? '',
    photoUrls: ((m['photo_urls'] as List?) ?? []).cast<String>(),
    scheduledAt: DateTime.tryParse(m['scheduled_at'] ?? '')?.toLocal() ?? DateTime.now(),
    address: m['address'] ?? '', lat: (m['lat'] ?? 0).toDouble(), lng: (m['lng'] ?? 0).toDouble(),
    status: BookingStatus.values.firstWhere((x) => x.name == (m['status'] ?? 'pending'), orElse: () => BookingStatus.pending),
    paymentMethod: m['payment_method'] == null ? null : PaymentMethod.values.firstWhere((x) => x.name == m['payment_method'], orElse: () => PaymentMethod.cash),
    paymentStatus: PaymentStatus.values.firstWhere((x) => x.name == (m['payment_status'] ?? 'unpaid'), orElse: () => PaymentStatus.unpaid),
    laborCost: (m['labor_cost'] ?? 0).toDouble(), partsCost: (m['parts_cost'] ?? 0).toDouble(),
    serviceFee: (m['service_fee'] ?? 0).toDouble(), total: (m['total'] ?? 0).toDouble(),
    rating: (m['rating'] ?? 0).toDouble(), review: m['review'], mechanicReply: m['mechanic_reply'],
    createdAt: DateTime.tryParse(m['created_at'] ?? '')?.toLocal() ?? DateTime.now(),
    updatedAt: DateTime.tryParse(m['updated_at'] ?? '')?.toLocal() ?? DateTime.now());
}

class ChatMessage {
  final String id, bookingId, senderId, text;
  final DateTime ts;
  ChatMessage({required this.id, required this.bookingId, required this.senderId, required this.text, DateTime? ts})
    : ts = ts ?? DateTime.now();
  Map<String, dynamic> toInsert() => {'id': id, 'booking_id': bookingId, 'sender_id': senderId, 'text': text};
  static ChatMessage fromRow(Map<String, dynamic> m) => ChatMessage(
    id: m['id'], bookingId: m['booking_id'], senderId: m['sender_id'], text: m['text'] ?? '',
    ts: DateTime.tryParse(m['ts'] ?? '')?.toLocal() ?? DateTime.now());
}

class WalletTxn {
  final String id, userId, description;
  final double amount;
  final DateTime ts;
  WalletTxn({required this.id, required this.userId, required this.amount, required this.description, DateTime? ts})
    : ts = ts ?? DateTime.now();
  Map<String, dynamic> toInsert() => {'id': id, 'user_id': userId, 'amount': amount, 'description': description};
  static WalletTxn fromRow(Map<String, dynamic> m) => WalletTxn(
    id: m['id'], userId: m['user_id'], amount: (m['amount'] ?? 0).toDouble(), description: m['description'] ?? '',
    ts: DateTime.tryParse(m['ts'] ?? '')?.toLocal() ?? DateTime.now());
}

class AppNotification {
  final String id, userId, title, body;
  final String? bookingId;
  final bool read;
  final DateTime ts;
  AppNotification({required this.id, required this.userId, required this.title, required this.body,
    this.bookingId, this.read = false, DateTime? ts}) : ts = ts ?? DateTime.now();
  Map<String, dynamic> toInsert() => {'id': id, 'user_id': userId, 'title': title, 'body': body, 'booking_id': bookingId, 'read': read};
  static AppNotification fromRow(Map<String, dynamic> m) => AppNotification(
    id: m['id'], userId: m['user_id'], title: m['title'] ?? '', body: m['body'] ?? '',
    bookingId: m['booking_id'], read: m['read'] ?? false,
    ts: DateTime.tryParse(m['ts'] ?? '')?.toLocal() ?? DateTime.now());
}

class InventoryItem {
  final String id, mechanicId, name;
  final int quantity;
  final double price;
  InventoryItem({required this.id, required this.mechanicId, required this.name, required this.quantity, required this.price});
  Map<String, dynamic> toInsert() => {'id': id, 'mechanic_id': mechanicId, 'name': name, 'quantity': quantity, 'price': price};
  static InventoryItem fromRow(Map<String, dynamic> m) => InventoryItem(
    id: m['id'], mechanicId: m['mechanic_id'], name: m['name'] ?? '', quantity: m['quantity'] ?? 0, price: (m['price'] ?? 0).toDouble());
}
