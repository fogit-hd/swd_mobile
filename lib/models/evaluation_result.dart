enum EvaluationResult {
  pass('PASS'),
  fail('FAIL');

  const EvaluationResult(this.label);

  final String label;
}
