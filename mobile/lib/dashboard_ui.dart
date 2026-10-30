part of 'main.dart';

const reportSections = <String, String>{
  'general': 'Reporte general',
  'separaciones': 'Separaciones',
  'ventas': 'Ventas',
  'clientes': 'Clientes nuevos',
  'asesores': 'Actividad por asesor',
  'ranking': 'Ranking de ventas',
  'liberaciones': 'Liberaciones',
};

extension _DashboardUi on _CasaViewState {
  String deadlinePreview() {
    final days = int.tryParse(deadlineDays.text);
    if (days == null) return 'Define el plazo de espera hasta la venta.';
    final now = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    return 'Vence el ${dateText(now.add(Duration(days: days)))} · días calendario';
  }

  Future<void> configureServer() async {
    final input = TextEditingController(text: c.api.baseUrl);
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conexión al servidor'),
        content: TextField(
          controller: input,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Dirección del servidor',
            hintText: 'http://192.168.1.12:8080',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, input.text.trim()),
            child: const Text('Comprobar y guardar'),
          ),
        ],
      ),
    );
    input.dispose();
    if (selected == null) return;
    await run(() async {
      final uri = Uri.tryParse(selected);
      if (uri == null ||
          !['http', 'https'].contains(uri.scheme) ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty ||
          (uri.path.isNotEmpty && uri.path != '/') ||
          uri.hasQuery ||
          uri.hasFragment) {
        message('Usa una dirección HTTP o HTTPS con el puerto del servidor.');
        return;
      }
      final candidate = ApiClient(uri.origin);
      try {
        final health = await candidate.call('GET', '/health');
        if (health['status'] != 'UP') {
          throw ApiException('El servidor no está disponible.');
        }
        await c.sessionStore.clear();
        c.api.baseUrl = uri.origin;
        await files.writeSetting('server', uri.origin);
        email.clear();
        password.clear();
        message('Conexión verificada.');
      } finally {
        candidate.client.close();
      }
    });
  }

  Future<void> changeDeadline(Data op) async {
    final input = TextEditingController(text: '${op['plazo_dias'] ?? 14}');
    final key = GlobalKey<FormState>();
    final days = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modificar plazo'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Desde el registro: ${displayDate(op['fecha_registro'])}'),
              space(12),
              TextFormField(
                controller: input,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Días calendario'),
                validator: (s) {
                  final n = int.tryParse(s ?? '');
                  return n == null || n < 1 || n > 3650
                      ? 'Indica de 1 a 3650 días.'
                      : null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) {
                Navigator.pop(ctx, int.parse(input.text));
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    input.dispose();
    if (days == null) return;
    await run(() async {
      await c.api.call('PATCH', '/operations/${op['id']}/deadline', {
        'dias': days,
        'version': op['version'],
      });
      c.operation = Data.from(
        await c.api.call('GET', '/operations/${op['id']}'),
      );
      await c.loadOperations();
      await c.pollNotifications();
      message('Plazo actualizado.');
    });
  }

  Future<void> dashboardFilters() async {
    final parsed = DateTime.parse('${c.dashboardMonth}-01');
    int month = parsed.month, year = parsed.year;
    int? advisor = c.dashboardUser, project = c.dashboardProject;
    final result = await showModalBottomSheet<Data>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: paper,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sectionTitle('Filtrar dashboard', top: 0),
                space(12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: month,
                        decoration: const InputDecoration(labelText: 'Mes'),
                        items: [
                          for (int i = 1; i <= 12; i++)
                            DropdownMenuItem(
                              value: i,
                              child: Text(monthNames[i - 1]),
                            ),
                        ],
                        onChanged: (v) => update(() => month = v ?? month),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: year,
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
                space(12),
                DropdownButtonFormField<int>(
                  initialValue: advisor ?? 0,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Asesor'),
                  items: [
                    const DropdownMenuItem(
                      value: 0,
                      child: Text('Todos los asesores'),
                    ),
                    for (final u in cv.CasaController.rows(
                      c.dashboard['usuarios'] ?? [],
                    ))
                      DropdownMenuItem(
                        value: (u['id'] as num).toInt(),
                        child: Text(
                          '${u['nombre']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => update(() => advisor = v == 0 ? null : v),
                ),
                space(12),
                DropdownButtonFormField<int>(
                  initialValue: project ?? 0,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Proyecto'),
                  items: [
                    const DropdownMenuItem(
                      value: 0,
                      child: Text('Todos los proyectos'),
                    ),
                    for (final p in cv.CasaController.rows(
                      c.dashboard['proyectos'] ?? [],
                    ))
                      DropdownMenuItem(
                        value: (p['id'] as num).toInt(),
                        child: Text(
                          '${p['nombre']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => update(() => project = v == 0 ? null : v),
                ),
                space(20),
                primary(
                  'Aplicar filtros',
                  () => Navigator.pop(ctx, {
                    'month': '$year-${month.toString().padLeft(2, '0')}',
                    'user': advisor,
                    'project': project,
                  }),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, {
                    'month': businessMonth(),
                    'user': null,
                    'project': null,
                  }),
                  child: const Text('Restablecer al mes actual'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == null) return;
    await run(() async {
      c.dashboardMonth = result['month'];
      c.dashboardUser = result['user'];
      c.dashboardProject = result['project'];
      await c.loadDashboard();
    });
  }

  Future<void> shiftDashboard(int delta) => run(() async {
    final date = DateTime.parse('${c.dashboardMonth}-01');
    final next = DateTime(date.year, date.month + delta);
    c.dashboardMonth = '${next.year}-${next.month.toString().padLeft(2, '0')}';
    await c.loadDashboard();
  });

  Future<void> downloadReport({bool history = false}) async {
    String section = history ? 'historial' : c.dashboardSection;
    String format = 'pdf';
    final result = await showModalBottomSheet<Data>(
      context: context,
      showDragHandle: true,
      backgroundColor: paper,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sectionTitle('Descargar reporte', top: 0),
                space(12),
                if (!history) ...[
                  DropdownButtonFormField<String>(
                    initialValue: section,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Contenido'),
                    items: reportSections.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => update(() => section = v ?? 'general'),
                  ),
                  space(16),
                ],
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'pdf',
                      label: Text('PDF'),
                      icon: Icon(Icons.picture_as_pdf_outlined),
                    ),
                    ButtonSegment(
                      value: 'xlsx',
                      label: Text('Excel'),
                      icon: Icon(Icons.table_chart_outlined),
                    ),
                    ButtonSegment(
                      value: 'txt',
                      label: Text('TXT'),
                      icon: Icon(Icons.notes_outlined),
                    ),
                  ],
                  selected: {format},
                  onSelectionChanged: (v) => update(() => format = v.first),
                ),
                space(20),
                primary(
                  'Guardar reporte',
                  () => Navigator.pop(ctx, {
                    'section': section,
                    'format': format,
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == null) return;
    await run(() async {
      final ext = result['format'] as String;
      final path = history
          ? listingUrl('/reports/history.$ext', {
              'month': c.historyMonth,
              'entity': c.historyEntity,
              'action': c.historyAction,
              'user': c.historyUser?.toString() ?? '',
            })
          : listingUrl('/reports/monthly.$ext', {
              'month': c.dashboardMonth,
              'section': result['section'],
              'user': c.dashboardUser?.toString() ?? '',
              'project': c.dashboardProject?.toString() ?? '',
            });
      final bytes = await c.api.bytes(path);
      final name = history
          ? 'CASA_VIP_historial_${c.historyMonth.isEmpty ? 'todos' : c.historyMonth}.$ext'
          : 'CASA_VIP_${c.dashboardMonth}_${result['section']}.$ext';
      await files.saveReport(bytes, name, switch (ext) {
        'pdf' => 'application/pdf',
        'xlsx' =>
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        _ => 'text/plain',
      });
    });
  }

  Widget dashboardPage() {
    if (c.dashboard.isEmpty) return empty('No se pudo cargar el dashboard.');
    final d = c.dashboard, totals = Data.from(d['totales']);
    final ranking = cv.CasaController.rows(d['ranking']);
    final alerts = cv.CasaController.rows(d['alertas']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Mes anterior',
              onPressed: busy ? null : () => shiftDashboard(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: busy ? null : dashboardFilters,
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: Text(
                  monthLabel(c.dashboardMonth),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Mes siguiente',
              onPressed: busy ? null : () => shiftDashboard(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        if (c.dashboardUser != null || c.dashboardProject != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: tx(
              '${d['filtros']['asesor']} · ${d['filtros']['proyecto']}',
              size: 12,
              color: muted,
            ),
          ),
        space(8),
        LayoutBuilder(
          builder: (ctx, box) => Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final item in [
                ('separaciones', 'Separaciones', Icons.bookmark_outline),
                ('ventas', 'Ventas', Icons.verified_outlined),
                ('clientes', 'Clientes nuevos', Icons.people_outline),
                ('liberaciones', 'Liberaciones', Icons.lock_open_outlined),
              ])
                SizedBox(
                  width: (box.maxWidth - 12) / 2,
                  child: tap(
                    uiBox(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(item.$3, size: 20, color: primaryGold),
                              const Spacer(),
                              const Icon(
                                Icons.north_east,
                                size: 14,
                                color: muted,
                              ),
                            ],
                          ),
                          space(12),
                          tx(
                            '${totals[item.$1] ?? 0}',
                            size: 30,
                            weight: FontWeight.w800,
                          ),
                          space(3),
                          tx(item.$2, size: 12, color: muted),
                          if (item.$1 == 'clientes') ...[
                            space(3),
                            tx(
                              '${totals['cotitulares'] ?? 0} cotitulares',
                              size: 11,
                              color: muted,
                            ),
                          ],
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                    ),
                    () => repaint(() => c.dashboardSection = item.$1),
                    label: 'Ver ${item.$2}',
                  ),
                ),
            ],
          ),
        ),
        space(18),
        primary(
          'Descargar reporte mensual',
          downloadReport,
          before: 'download',
        ),
        space(10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey(c.dashboardSection),
                initialValue: c.dashboardSection,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Ver información'),
                items: reportSections.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (v) =>
                    repaint(() => c.dashboardSection = v ?? 'general'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Ver historial de cambios',
              onPressed: () => openManagement('history-all'),
              icon: const Icon(Icons.history_rounded, color: primaryGold),
            ),
          ],
        ),
        if (c.dashboardSection == 'general' ||
            c.dashboardSection == 'ranking') ...[
          sectionTitle('Ranking de ventas'),
          if (ranking.isEmpty) empty('Sin ventas en este período.'),
          for (final r in ranking)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      tx(
                        '${r['posicion']}.',
                        size: 16,
                        color: primaryGold,
                        weight: FontWeight.w800,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: tx(
                          '${r['asesor']}',
                          size: 13,
                          weight: FontWeight.w600,
                        ),
                      ),
                      tx('${r['ventas']} ventas', size: 12),
                    ],
                  ),
                  space(6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value:
                          (r['ventas'] as num) /
                          (ranking.first['ventas'] as num),
                      minHeight: 6,
                      color: primaryGold,
                      backgroundColor: const Color(0xffe8e3d7),
                    ),
                  ),
                ],
              ),
            ),
        ],
        if (c.dashboardSection == 'general') ...[
          sectionTitle('Seguimiento actual de separaciones'),
          if (alerts.isEmpty) empty('Sin separaciones próximas a vencer.'),
          for (final a in alerts)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                a['alerta'] == 'Vencida'
                    ? Icons.warning_amber_rounded
                    : Icons.schedule,
                color: a['alerta'] == 'Vencida'
                    ? Colors.deepOrange
                    : primaryGold,
              ),
              title: Text(
                '${a['proyecto']} · Mz ${a['manzana']} · Lote ${a['lote']}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '${a['alerta']} · ${a['asesor']}\n${a['fecha_vencimiento'] == null ? 'Plazo pendiente' : displayDate(a['fecha_vencimiento'])}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openOperation(a),
            ),
        ],
        if (c.dashboardSection != 'ranking')
          for (final e in reportSections.entries.where(
            (e) => !['general', 'ranking'].contains(e.key),
          ))
            if (c.dashboardSection == 'general' || c.dashboardSection == e.key)
              dashboardSection(
                e.key,
                e.value,
                cv.CasaController.rows(d[e.key]),
              ),
      ],
    );
  }

  Widget dashboardSection(
    String key,
    String title,
    List<Data> rows,
  ) => ExpansionTile(
    key: ValueKey('${c.dashboardMonth}-$key-${c.dashboardSection}'),
    initiallyExpanded: c.dashboardSection == key,
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: 12),
    title: Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      '${rows.length} registros',
      style: const TextStyle(fontSize: 12),
    ),
    children: [
      if (rows.isEmpty) empty('Sin movimientos en este período.'),
      for (final row in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: uiBox(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (key == 'clientes') ...[
                  tx('${row['nombre']}', size: 14, weight: FontWeight.w700),
                  space(5),
                  tx(
                    '${row['participacion']} · ${row['tipo_documento']} ${row['numero_documento']}',
                    size: 12,
                    color: muted,
                  ),
                  detailLine('Teléfono', row['telefono']),
                  detailLine('Correo', row['correo']),
                  detailLine('Registro', displayDate(row['fecha_registro'])),
                  detailLine('Proyecto', row['proyecto']),
                  detailLine(
                    'Lotes',
                    (row['lotes'] as List).isEmpty
                        ? 'Sin lotes separados o vendidos'
                        : (row['lotes'] as List).join('\n'),
                  ),
                ] else if (key == 'asesores') ...[
                  tx('${row['asesor']}', size: 14, weight: FontWeight.w700),
                  space(6),
                  tx(
                    '${row['separaciones']} separaciones · ${row['ventas']} ventas',
                    size: 13,
                    color: primaryGold,
                  ),
                  space(8),
                  detailLine(
                    'Lotes separados',
                    (row['lotes_separados'] as List).join('\n'),
                  ),
                  detailLine(
                    'Lotes vendidos',
                    (row['lotes_vendidos'] as List).join('\n'),
                  ),
                ] else ...[
                  tx('${row['proyecto']}', size: 14, weight: FontWeight.w700),
                  space(5),
                  tx('Mz ${row['manzana']} · Lote ${row['lote']}', size: 13),
                  space(6),
                  detailLine('Titular', row['cliente']),
                  detailLine('Cotitular', row['cotitular']),
                  detailLine('Asesor', row['asesor']),
                  detailLine(
                    key == 'ventas'
                        ? 'Venta'
                        : key == 'liberaciones'
                        ? 'Liberación'
                        : 'Separación',
                    displayDate(
                      row[key == 'ventas'
                          ? 'fecha_venta'
                          : key == 'liberaciones'
                          ? 'fecha_liberacion'
                          : 'fecha_registro'],
                    ),
                  ),
                  if (key == 'liberaciones') ...[
                    detailLine('Responsable', row['responsable']),
                    detailLine('Motivo', row['motivo']),
                  ],
                  if (key == 'separaciones' && row['fecha_vencimiento'] != null)
                    detailLine(
                      'Vencimiento',
                      displayDate(row['fecha_vencimiento']),
                    ),
                  TextButton(
                    onPressed: () => openOperation(row),
                    child: const Text('Ver operación'),
                  ),
                ],
              ],
            ),
            padding: const EdgeInsets.all(14),
          ),
        ),
    ],
  );
}
