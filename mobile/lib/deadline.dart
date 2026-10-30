int? defaultDeadline(num amount) => switch (amount) {
  100 => 3,
  200 => 5,
  500 => 14,
  _ => null,
};

String? validateDeadline(String? text, num amount) {
  final days = int.tryParse(text ?? '');
  if (days == null || days < 1 || days > 3650) {
    return 'Indica de 1 a 3650 días.';
  }
  final limit = defaultDeadline(amount);
  if (limit != null && days > limit) return 'Máximo inicial: $limit días.';
  return null;
}
