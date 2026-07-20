enum ReviewType {
  review1('Review1', 'Review đợt 1'),
  review2('Review2', 'Review đợt 2'),
  review3('Review3', 'Review đợt 3');

  const ReviewType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ReviewType get defaultType => ReviewType.review1;

  static ReviewType? tryParse(String? raw) {
    if (raw == null) return null;
    for (final value in ReviewType.values) {
      if (value.apiValue.toLowerCase() == raw.toLowerCase()) return value;
    }
    return null;
  }
}

enum ReviewChecklistAnswer {
  yes('Yes', 'Có'),
  no('No', 'Không'),
  notApplicable('NotApplicable', 'Không áp dụng');

  const ReviewChecklistAnswer(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ReviewChecklistAnswer? tryParse(String? raw) {
    if (raw == null) return null;
    for (final value in ReviewChecklistAnswer.values) {
      if (value.apiValue == raw) return value;
    }
    return null;
  }
}
