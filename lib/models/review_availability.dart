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

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek,
        'slot': slot,
      };

  @override
  bool operator ==(Object other) =>
      other is AvailabilitySlot &&
      other.dayOfWeek == dayOfWeek &&
      other.slot == slot;

  @override
  int get hashCode => Object.hash(dayOfWeek, slot);
}

class ReviewAvailabilityWeek {
  const ReviewAvailabilityWeek({
    required this.semesterId,
    required this.lecturerId,
    required this.weekStart,
    this.slots = const [],
  });

  factory ReviewAvailabilityWeek.fromJson(Map<String, dynamic> json) {
    final slotsJson = json['slots'] as List<dynamic>? ?? [];
    return ReviewAvailabilityWeek(
      semesterId: json['semesterId'] as int? ?? 0,
      lecturerId: json['lecturerId'] as int? ?? 0,
      weekStart: json['weekStart'] as String? ?? '',
      slots: slotsJson
          .map((e) => AvailabilitySlot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int semesterId;
  final int lecturerId;
  final String weekStart;
  final List<AvailabilitySlot> slots;

  Map<String, dynamic> toSaveJson() => {
        'slots': slots.map((s) => s.toJson()).toList(),
      };
}
