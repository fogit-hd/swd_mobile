class AvailabilitySlot {
  const AvailabilitySlot({required this.dayOfWeek, required this.slot});

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      dayOfWeek: json['dayOfWeek'] as int? ?? 0,
      slot: json['slot'] as int? ?? 0,
    );
  }

  final int dayOfWeek;
  final int slot;

  Map<String, dynamic> toJson() => {'dayOfWeek': dayOfWeek, 'slot': slot};

  @override
  bool operator ==(Object other) =>
      other is AvailabilitySlot &&
      other.dayOfWeek == dayOfWeek &&
      other.slot == slot;

  @override
  int get hashCode => Object.hash(dayOfWeek, slot);
}

class SlotRegistrationCount {
  const SlotRegistrationCount({
    required this.dayOfWeek,
    required this.slot,
    required this.registeredCount,
  });

  factory SlotRegistrationCount.fromJson(Map<String, dynamic> json) {
    return SlotRegistrationCount(
      dayOfWeek: json['dayOfWeek'] as int? ?? 0,
      slot: json['slot'] as int? ?? 0,
      registeredCount: json['registeredCount'] as int? ?? 0,
    );
  }

  final int dayOfWeek;
  final int slot;
  final int registeredCount;

  String get key => '$dayOfWeek-$slot';
}

class ReviewAvailabilityWeek {
  const ReviewAvailabilityWeek({
    required this.roundId,
    required this.semesterId,
    required this.lecturerId,
    required this.weekStart,
    this.isSubmitted = false,
    this.submittedAt,
    this.slots = const [],
    this.maxRegistrationsPerSlot = 4,
    this.slotRegistrationCounts = const [],
  });

  factory ReviewAvailabilityWeek.fromJson(Map<String, dynamic> json) {
    final slotsJson = json['slots'] as List<dynamic>? ?? [];
    final countsJson = json['slotRegistrationCounts'] as List<dynamic>? ?? [];
    final weekStartRaw = json['weekStart'];
    return ReviewAvailabilityWeek(
      roundId: json['roundId'] as int? ?? 0,
      semesterId: json['semesterId'] as int? ?? 0,
      lecturerId: json['lecturerId'] as int? ?? 0,
      weekStart: weekStartRaw?.toString() ?? '',
      isSubmitted: json['isSubmitted'] as bool? ?? false,
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString())
          : null,
      slots: slotsJson
          .map((e) => AvailabilitySlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      maxRegistrationsPerSlot: json['maxRegistrationsPerSlot'] as int? ?? 4,
      slotRegistrationCounts: countsJson
          .map((e) => SlotRegistrationCount.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int roundId;
  final int semesterId;
  final int lecturerId;
  final String weekStart;
  final bool isSubmitted;
  final DateTime? submittedAt;
  final List<AvailabilitySlot> slots;
  final int maxRegistrationsPerSlot;
  final List<SlotRegistrationCount> slotRegistrationCounts;

  Map<String, int> get registrationCountMap => {
    for (final item in slotRegistrationCounts) item.key: item.registeredCount,
  };
}
