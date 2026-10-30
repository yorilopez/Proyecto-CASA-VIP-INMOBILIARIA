part of 'main.dart';

extension _ListingUi on _CasaViewState {
  Widget filterSummary(String category, String month, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.tune_rounded, size: 17, color: primaryGold),
              const SizedBox(width: 8),
              Expanded(
                child: tx(
                  '$category · ${monthLabel(month)}',
                  size: 12,
                  color: muted,
                ),
              ),
              const Icon(Icons.expand_more_rounded, size: 18, color: muted),
            ],
          ),
        ),
      );
  Widget clientFilterControls() => filterSummary(
    clientCategoryLabel(c.clientCategory),
    c.clientMonth,
    clientFilters,
  );

  Future<Map<String, dynamic>?> listingFilters({
    required String title,
    required String month,
    required String category,
    required Map<String, String> categories,
    bool history = false,
  }) {
    final parsed = DateTime.tryParse('$month-01') ?? DateTime.now();
    int selectedMonth = parsed.month, year = parsed.year;
    bool all = month.isEmpty;
    String kind = category;
    int? user = c.historyUser;
    String action = c.historyAction;
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: paper,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                20 + MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sectionTitle(title, top: 0),
                  space(8),
                  DropdownButtonFormField<String>(
                    initialValue: kind,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Mostrar'),
                    items: categories.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => update(() => kind = v ?? ''),
                  ),
                  space(12),
                  if (history) ...[
                    DropdownButtonFormField<String>(
                      initialValue: action,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Acción'),
                      items:
                          const {
                                '': 'Todas las acciones',
                                'SEPARACION': 'Separaciones',
                                'VENTA': 'Ventas',
                                'LIBERACION': 'Liberaciones',
                                'PLAZO': 'Cambios de plazo',
                                'MODIFICAR': 'Correcciones',
                                'REASIGNAR': 'Reasignaciones',
                              }.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => update(() => action = v ?? ''),
                    ),
                    space(12),
                    DropdownButtonFormField<int>(
                      initialValue: user ?? 0,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Usuario'),
                      items: [
                        const DropdownMenuItem(
                          value: 0,
                          child: Text('Todos los usuarios'),
                        ),
                        for (final u in c.historyUsers)
                          DropdownMenuItem(
                            value: (u['id'] as num).toInt(),
                            child: Text(
                              '${u['nombre']}${u['eliminado'] == true ? ' (retirado)' : ''}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) => update(() => user = v == 0 ? null : v),
                    ),
                    space(12),
                  ],
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Todos los períodos'),
                    value: all,
                    activeColor: primaryGold,
                    onChanged: (v) => update(() => all = v ?? false),
                  ),
                  if (!all)
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<int>(
                            key: ValueKey('month-$selectedMonth'),
                            initialValue: selectedMonth,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Mes'),
                            items: [
                              for (int i = 1; i <= 12; i++)
                                DropdownMenuItem(
                                  value: i,
                                  child: Text(monthNames[i - 1]),
                                ),
                            ],
                            onChanged: (v) => update(
                              () => selectedMonth = v ?? selectedMonth,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<int>(
                            key: ValueKey('year-$year'),
                            initialValue: year,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Año'),
                            items: [
                              for (
                                int i = math.max(DateTime.now().year + 1, year);
                                i >= 1900;
                                i--
                              )
                                DropdownMenuItem(value: i, child: Text('$i')),
                            ],
                            onChanged: (v) => update(() => year = v ?? year),
                          ),
                        ),
                      ],
                    ),
                  space(20),
                  primary(
                    'Aplicar filtros',
                    () => Navigator.pop(ctx, {
                      'month': all
                          ? ''
                          : '$year-${selectedMonth.toString().padLeft(2, '0')}',
                      'category': kind,
                      'user': user,
                      'action': action,
                    }),
                  ),
                  space(6),
                  TextButton(
                    onPressed: () => update(() {
                      all = false;
                      final now = DateTime.now().toUtc().subtract(
                        const Duration(hours: 5),
                      );
                      selectedMonth = now.month;
                      year = now.year;
                      kind = '';
                      user = null;
                      action = '';
                    }),
                    child: const Text('Restablecer al mes actual'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> clientFilters() async {
    final result = await listingFilters(
      title: 'Filtrar clientes',
      month: c.clientMonth,
      category: c.clientCategory,
      categories: {
        for (final v in ['', 'POTENCIAL', 'SEPARACION', 'VENTA'])
          v: clientCategoryLabel(v),
      },
    );
    if (result == null) return;
    await run(() async {
      c.clientMonth = result['month'];
      c.clientCategory = result['category'];
      await c.loadClients();
    });
  }

  Future<void> operationFilters() async {
    final result = await listingFilters(
      title: 'Filtrar operaciones',
      month: c.operationMonth,
      category: c.operationState,
      categories: {
        for (final v in ['', 'ACTIVA', 'CONFIRMADA', 'LIBERADA'])
          v: operationStateLabel(v),
      },
    );
    if (result == null) return;
    await run(() async {
      c.operationMonth = result['month'];
      c.operationState = result['category'];
      await c.loadOperations();
    });
  }

  Future<void> historyFilters() async {
    final result = await listingFilters(
      title: 'Filtrar historial',
      month: c.historyMonth,
      category: c.historyEntity,
      categories: const {
        '': 'Todos los registros',
        'CLIENTE': 'Clientes',
        'OPERACION': 'Operaciones',
        'CATALOGO': 'Precios',
        'USUARIO': 'Usuarios',
      },
      history: true,
    );
    if (result == null) return;
    await run(() async {
      c.historyMonth = result['month'];
      c.historyEntity = result['category'];
      c.historyUser = result['user'];
      c.historyAction = result['action'];
      await c.loadHistory();
    });
  }

  String displayDate(dynamic value) {
    final parsed = DateTime.tryParse('${value ?? ''}');
    if (parsed == null) return 'Sin fecha registrada';
    final local = parsed.isUtc
        ? parsed.subtract(const Duration(hours: 5))
        : parsed;
    return dateText(local);
  }

  Widget detailLine(String label, dynamic value) {
    if (value == null || '$value'.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tx(label, size: 10.5, color: muted, weight: FontWeight.w600),
          space(3),
          SelectableText(
            '$value',
            style: const TextStyle(fontSize: 13, color: ink, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget personVisual(String title, Map<dynamic, dynamic> person) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      sectionTitle(title, top: 16),
      detailLine('Nombre completo', person['nombre']),
      detailLine(
        '${person['tipo_documento'] ?? 'Documento'}',
        person['numero_documento'],
      ),
      detailLine('Teléfono', person['telefono']),
      detailLine('Dirección', person['direccion']),
      detailLine('Correo', person['correo']),
      detailLine('Ocupación', person['ocupacion']),
    ],
  );
  Widget operationVisual(Data op) {
    final snapshot = operationSnapshot(op);
    final lot = Data.from(snapshot['lote'] ?? op['lote_actual'] ?? {}),
        terms = Data.from(snapshot['condiciones'] ?? {}),
        person = Data.from(snapshot['titular'] ?? {});
    final co = snapshot['cotitular'];
    final values = [
      ('Precio acordado', money(terms['precio'] ?? op['precio_acordado'])),
      ('Inicial', money(terms['inicial'] ?? op['inicial_acordada'])),
      (
        'Número de cuotas',
        '${terms['numero_cuotas'] ?? op['numero_cuotas_acordado'] ?? '—'}',
      ),
      ('Mensualidad', money(terms['mensualidad'] ?? op['cuota_acordada'])),
      ('Última cuota', money(terms['ultima_cuota'])),
      ('Monto de separación', money(op['monto'])),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        eyebrow(reservationCode(op)),
        space(6),
        tx(projectName(lot['proyecto']), size: 21, weight: FontWeight.w800),
        space(5),
        tx(
          'Manzana ${lot['manzana'] ?? ''} · Lote ${lot['codigo'] ?? ''}',
          size: 16,
          weight: FontWeight.w600,
        ),
        space(4),
        tx(
          '${lot['etapa'] ?? ''}${lot['area_m2'] == null ? '' : ' · ${lot['area_m2']} m²'}',
          size: 12,
          color: muted,
        ),
        sectionTitle('Condiciones de la operación'),
        LayoutBuilder(
          builder: (ctx, size) => Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              for (final item in values)
                SizedBox(
                  width: (size.maxWidth - 14) / 2,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: paper,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        tx(item.$1, size: 10.5, color: muted),
                        space(5),
                        tx(
                          item.$2,
                          size: 15,
                          weight: FontWeight.w800,
                          color: item.$1 == 'Precio acordado'
                              ? primaryGold
                              : ink,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        personVisual('Titular', person),
        if (co is Map) personVisual('Cotitular', co),
        sectionTitle('Registro de la operación', top: 16),
        detailLine('Asesor', op['asesor_nombre']),
        detailLine('Fecha de separación', displayDate(op['fecha_registro'])),
        detailLine(
          'Plazo',
          op['plazo_dias'] == null
              ? 'Pendiente de definir'
              : '${op['plazo_dias']} días',
        ),
        if (op['fecha_vencimiento'] != null)
          detailLine('Vencimiento', displayDate(op['fecha_vencimiento'])),
        if (op['venta'] != null)
          detailLine('Fecha de venta', displayDate(op['venta']['fecha_venta'])),
        detailLine('Observaciones', op['observacion']),
      ],
    );
  }

  String readable(String raw) {
    const labels = {
      'CLIENTE': 'Cliente',
      'OPERACION': 'Operación',
      'CATALOGO': 'Catálogo',
      'USUARIO': 'Usuario',
      'CREAR': 'Registro',
      'CORREGIR': 'Corrección',
      'ACTUALIZAR': 'Actualización',
      'ELIMINAR': 'Retiro',
      'DESVINCULAR': 'Desvinculación',
      'VENTA': 'Venta',
      'VENDER': 'Venta',
      'SEPARAR': 'Separación',
      'LIBERAR': 'Liberación',
      'REASIGNAR': 'Reasignación',
      'IMPORTAR': 'Importación',
      'HABILITAR': 'Habilitación',
      'DESHABILITAR': 'Deshabilitación',
      'ACTIVA': 'Separación activa',
      'CONFIRMADA': 'Venta registrada',
      'ANULADA': 'Liberada',
      'VENCIDA': 'Vencida',
      'ADMINISTRADOR': 'Administrador',
      'RESPONSABLE_COMERCIAL': 'Responsable comercial',
      'ASESOR': 'Asesor',
      'nombre': 'Nombre',
      'numero_documento': 'Documento',
      'tipo_documento': 'Tipo de documento',
      'precio_acordado': 'Precio acordado',
      'precio_final': 'Precio de venta',
      'inicial_acordada': 'Inicial acordada',
      'numero_cuotas_acordado': 'Número de cuotas',
      'cuota_acordada': 'Mensualidad',
      'monto': 'Separación',
      'fecha_registro': 'Fecha de registro',
      'fecha_venta': 'Fecha de venta',
      'cliente_id': 'Titular',
      'cotitular_id': 'Cotitular',
      'asesor_id': 'Asesor',
      'lote_id': 'Lote',
      'precio': 'Precio',
      'inicial': 'Inicial',
      'numero_cuotas': 'Cuotas',
      'monto_cuota': 'Mensualidad',
      'area_m2': 'Área (m²)',
      'correo': 'Correo',
      'telefono': 'Teléfono',
      'direccion': 'Dirección',
      'ocupacion': 'Ocupación',
      'activo': 'Activo',
      'observacion': 'Observación',
      'estado': 'Estado',
      'motivo': 'Motivo',
      'rol': 'Rol',
      'planes': 'Planes de pago',
      'rows': 'Lotes',
      'ultima_cuota': 'Última cuota',
      'mensualidad': 'Mensualidad',
      'ubicacion': 'Ubicación',
      'eliminado': 'Retirado',
      'proyecto_id': 'Proyecto',
      'plan_pago_id': 'Plan de pago',
    };
    if (labels.containsKey(raw)) return labels[raw]!;
    final value = raw.toLowerCase().replaceAll('_', ' ');
    return value.isEmpty
        ? 'Dato'
        : '${value[0].toUpperCase()}${value.substring(1)}';
  }

  Map<String, String> historyValues(dynamic data, [String prefix = '']) {
    final result = <String, String>{};
    const hidden = {
      'password_hash',
      'token_hash',
      'ruta_privada',
      'ruta',
      'archivo',
      'datos_acordados',
      'datos_finales',
      'version',
      'version_catalogo',
      'version_condiciones',
      'condiciones_activas',
    };
    if (data is Map) {
      for (final e in data.entries) {
        final key = '${e.key}';
        if (hidden.contains(key) ||
            key.contains('password') ||
            key.contains('token')) {
          continue;
        }
        final label = prefix.isEmpty
            ? readable(key)
            : '$prefix · ${readable(key)}';
        result.addAll(historyValues(e.value, label));
      }
    } else if (data is List) {
      for (int i = 0; i < data.length; i++) {
        result.addAll(historyValues(data[i], '$prefix ${i + 1}'));
      }
    } else {
      String value = data == null
          ? 'Sin dato'
          : data is bool
          ? (data ? 'Sí' : 'No')
          : '$data';
      if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(value)) {
        value = displayDate(value);
      }
      if (RegExp(r'^[A-Z_]+$').hasMatch(value)) value = readable(value);
      result[prefix] = value;
    }
    return result;
  }

  Future<void> historyDetail(Data entry) async {
    final before = historyValues(entry['anterior']),
        after = historyValues(entry['actual']);
    final keys = {
      ...before.keys,
      ...after.keys,
    }.where((k) => k.isNotEmpty && before[k] != after[k]).toList()..sort();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: paper,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * .84,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sectionTitle(
                  '${readable('${entry['entidad']}')} #${entry['registro_id']}',
                  top: 0,
                ),
                tx(
                  readable('${entry['accion']}'),
                  size: 19,
                  weight: FontWeight.w800,
                ),
                space(10),
                detailLine(
                  'Responsable',
                  '${entry['usuario']} · ${readable('${entry['rol'] ?? ''}')}',
                ),
                detailLine('Fecha', displayDate(entry['fecha'])),
                detailLine('Motivo', entry['motivo']),
                space(8),
                for (final key in keys) ...[
                  uiBox(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        tx(key, size: 12, weight: FontWeight.w700),
                        space(10),
                        detailLine('Anterior', before[key] ?? 'Sin dato'),
                        detailLine('Nuevo', after[key] ?? 'Sin dato'),
                      ],
                    ),
                    padding: const EdgeInsets.all(14),
                  ),
                  space(10),
                ],
                if (keys.isEmpty)
                  empty(
                    'El registro no contiene cambios de campos para mostrar.',
                  ),
                primary('Cerrar', () => Navigator.pop(ctx), outline: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget historyPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () => openManagement('dashboard'),
              icon: const Icon(Icons.dashboard_outlined),
              label: const Text('Dashboard'),
            ),
          ),
          TextButton.icon(
            onPressed: () => downloadReport(history: true),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Descargar'),
          ),
        ],
      ),
      filterSummary(
        c.historyUser == null
            ? 'Todas las acciones${c.historyAction.isEmpty ? '' : ' · ${readable(c.historyAction)}'}'
            : c.historyUsers
                      .where((u) => u['id'] == c.historyUser)
                      .map((u) => '${u['nombre']}')
                      .firstOrNull ??
                  'Usuario seleccionado',
        c.historyMonth,
        historyFilters,
      ),
      sectionTitle(
        '${c.history.length} registros',
        overline: c.historyEntity.isEmpty
            ? 'TODOS LOS TIPOS'
            : readable(c.historyEntity).toUpperCase(),
      ),
      for (final h in c.history) ...[
        tap(
          uiBox(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xfff6edcf),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: primaryGold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      tx(
                        '${readable('${h['entidad']}')} #${h['registro_id']}',
                        size: 12,
                        color: muted,
                      ),
                      space(3),
                      tx(
                        readable('${h['accion']}'),
                        size: 14,
                        weight: FontWeight.w800,
                      ),
                      space(6),
                      tx('${h['usuario']}', size: 12),
                      space(2),
                      tx(displayDate(h['fecha']), size: 11, color: muted),
                      if ('${h['motivo'] ?? ''}'.isNotEmpty) ...[
                        space(7),
                        tx('${h['motivo']}', size: 12, color: muted),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: muted),
              ],
            ),
            padding: const EdgeInsets.all(14),
          ),
          () => historyDetail(h),
          label: 'Ver cambio ${h['id']}',
        ),
        space(10),
      ],
      if (c.history.isEmpty)
        empty('No hay registros para los filtros seleccionados.'),
    ],
  );
}
