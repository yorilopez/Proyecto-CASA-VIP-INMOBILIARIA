const monthNames = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];
String businessMonth([DateTime? time]) {
  final d = (time ?? DateTime.now()).toUtc().subtract(const Duration(hours: 5));
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
}

String monthLabel(String value) {
  if (value.isEmpty) return 'Todos los períodos';
  final d = DateTime.tryParse('$value-01');
  return d == null ? 'Sin fecha' : '${monthNames[d.month - 1]} ${d.year}';
}

String listingUrl(String path, Map<String, String> values) {
  final params = Map<String, String>.fromEntries(
    values.entries.where((e) => e.value.isNotEmpty),
  );
  return params.isEmpty ? path : '$path?${Uri(queryParameters: params).query}';
}

String clientCategoryLabel(String value) => switch (value) {
  'POTENCIAL' => 'Clientes potenciales',
  'SEPARACION' => 'Con separación',
  'VENTA' => 'Con venta',
  _ => 'Todos los clientes',
};
String operationStateLabel(String value) => switch (value) {
  'ACTIVA' => 'Separaciones',
  'CONFIRMADA' => 'Ventas',
  'LIBERADA' => 'Liberadas',
  _ => 'Todas las operaciones',
};
