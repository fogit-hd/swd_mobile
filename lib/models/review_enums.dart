enum ReviewType {
  review1('Review1', 'Review 1'),
  review2('Review2', 'Review 2'),
  review3('Review3', 'Review 3');

  const ReviewType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ReviewType get defaultType => ReviewType.review1;
}

enum ReviewChecklistAnswer {
  yes('Yes', 'Có'),
  no('No', 'Không'),
  notApplicable('NotApplicable', 'N/A');

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
