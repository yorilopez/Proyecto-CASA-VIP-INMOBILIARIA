part of 'main.dart';

extension CommercialExtension on _CasaViewState {
  num monthlyForInputs(String price, String initial, String count) {
    final n = int.tryParse(count) ?? 0;
    if (n < 1) return 0;
    return (((num.tryParse(price.replaceAll(',', '.')) ?? 0) -
                    (num.tryParse(initial.replaceAll(',', '.')) ?? 0)) *
                100 /
                n)
            .floor() /
        100;
  }

  num get draftMonthly {
    final price = c.agreedPrice ?? num.tryParse('${c.lot?['precio']}') ?? 0;
    final initial = c.agreedInitial ?? num.tryParse('${plan['inicial']}') ?? 0;
    final count =
        c.agreedCount ?? (plan['numero_cuotas'] as num?)?.toInt() ?? 1;
    return count > 0 ? ((price - initial) * 100 / count).floor() / 100 : 0;
  }

  bool validDraftTerms() =>
      c.agreedPrice != null &&
      c.agreedInitial != null &&
      c.agreedCount != null &&
      c.agreedPrice! > 0 &&
      c.agreedInitial! > 0 &&
      c.agreedInitial! <= c.agreedPrice! &&
      c.agreedCount! > 0 &&
      c.agreedCount! <= 600;
  void ensureDraftTerms() {
    if (draftLot != c.lot?['id'] || c.agreedPrice == null) {
      draftLot = (c.lot?['id'] as num?)?.toInt();
      negotiatedPrice.text = '${c.lot?['precio'] ?? 0}';
      resetDraftPlan();
    }
  }

  void resetDraftPlan() {
    negotiatedInitial.text = '${plan['inicial'] ?? 0}';
    negotiatedCount.text = '${plan['numero_cuotas'] ?? 1}';
    readDraft();
  }

  void readDraft() {
    c.agreedPrice = num.tryParse(negotiatedPrice.text.replaceAll(',', '.'));
    c.agreedInitial = num.tryParse(negotiatedInitial.text.replaceAll(',', '.'));
    c.agreedCount = int.tryParse(negotiatedCount.text);
  }

  Widget negotiatedFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (c.manager) ...[
        field(
          'Precio acordado (S/)',
          negotiatedPrice,
          keyboard: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => repaint(readDraft),
        ),
        space(12),
      ],
      field(
        'Inicial acordada (S/)',
        negotiatedInitial,
        required: true,
        keyboard: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => repaint(readDraft),
      ),
      space(12),
      field(
        'Número de cuotas acordado',
        negotiatedCount,
        required: true,
        keyboard: TextInputType.number,
        onChanged: (_) => repaint(readDraft),
      ),
      space(10),
      infoNote(
        'Las condiciones se guardan en esta operación. La mensualidad se calcula sin intereses; la última cuota absorbe el redondeo.',
        compact: true,
      ),
    ],
  );
  bool hasSale(Data client) => c.reservations.any(
    (r) =>
        r['estado'] == 'CONFIRMADA' &&
        (r['cliente_id'] == client['id'] || r['cotitular_id'] == client['id']),
  );
  void loadPersonForm(Data profile) {
    names.text = '${profile['nombre'] ?? ''}';
    document.text = '${profile['numero_documento'] ?? ''}';
    phone.text = '${profile['telefono'] ?? ''}';
    address.text = '${profile['direccion'] ?? ''}';
    mail.text = '${profile['correo'] ?? ''}';
    occupation.text = '${profile['ocupacion'] ?? ''}';
    final co = profile['cotitular'];
    withCo = co != null;
    coNames.text = '${co?['nombre'] ?? ''}';
    coDocument.text = '${co?['numero_documento'] ?? ''}';
    coPhone.text = '${co?['telefono'] ?? ''}';
    coAddress.text = '${co?['direccion'] ?? ''}';
    coMail.text = '${co?['correo'] ?? ''}';
    coOccupation.text = '${co?['ocupacion'] ?? ''}';
  }

  Future<Data?> choosePerson({bool co = false}) async {
    final query = TextEditingController();
    return showModalBottomSheet<Data>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: paper,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => SizedBox(
          height: MediaQuery.sizeOf(ctx).height * .75,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                sectionTitle(
                  co ? 'Seleccionar cotitular' : 'Seleccionar cliente',
                  top: 0,
                ),
                TextField(
                  controller: query,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre o documento',
                  ),
                  onChanged: (_) => update(() {}),
                ),
                space(12),
                Expanded(
                  child: ListView(
                    children: [
                      for (final p in c.clients.where(
                        (p) =>
                            '${p['nombre']} ${p['numero_documento']}'
                                .toLowerCase()
                                .contains(query.text.toLowerCase()) &&
                            (!co || p['id'] != c.selectedClient?['id']) &&
                            (c.lot == null ||
                                p['proyecto_id'] == c.lot?['proyecto_id']),
                      ))
                        ListTile(
                          title: Text('${p['nombre']}'),
                          subtitle: Text(
                            '${p['tipo_documento']} ${p['numero_documento']}',
                          ),
                          onTap: () => Navigator.pop(ctx, p),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> selectExistingClient() async {
    final person = await choosePerson();
    if (person == null) return;
    await run(() async {
      await c.chooseClient(person);
      loadPersonForm(c.selectedClient!);
    });
  }

  Future<void> selectExistingCo(BuildContext editor) async {
    final person = await choosePerson(co: true);
    if (person == null || !editor.mounted) return;
    coNames.text = '${person['nombre']}';
    coDocument.text = '${person['numero_documento']}';
    coPhone.text = '${person['telefono'] ?? ''}';
    coAddress.text = '${person['direccion'] ?? ''}';
    coMail.text = '${person['correo'] ?? ''}';
    coOccupation.text = '${person['ocupacion'] ?? ''}';
    withCo = true;
    Navigator.pop(editor, true);
  }

  Future<bool> confirmAction(String title, String text) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> extendedClientProfile(Data input) async {
    Data? profile;
    List<Data> docs = [];
    await run(() async {
      profile = Data.from(await c.api.call('GET', '/clients/${input['id']}'));
      docs = cv.CasaController.rows(
        await c.api.call('GET', '/clients/${input['id']}/documents'),
      );
    });
    if (profile == null || !mounted) return;
    final p = profile!;
    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: paper,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * .85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              sectionTitle('${p['nombre']}', top: 0),
              tx(
                '${p['tipo_documento']} ${p['numero_documento']}',
                weight: FontWeight.w700,
              ),
              space(12),
              for (final k in ['telefono', 'correo', 'direccion', 'ocupacion'])
                if ('${p[k] ?? ''}'.isNotEmpty) ...[
                  tx('$k: ${p[k]}', size: 13),
                  space(6),
                ],
              if (p['cotitular'] != null) ...[
                space(10),
                tx(
                  'Cotitular: ${p['cotitular']['nombre']}',
                  weight: FontWeight.w700,
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 'unlink'),
                  child: const Text('Eliminar vínculo del cotitular'),
                ),
              ],
              sectionTitle('Lotes y operaciones'),
              for (final op in cv.CasaController.rows(p['operaciones'] ?? []))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${op['proyecto']} · MZ ${op['manzana']} · Lote ${op['lote']}',
                  ),
                  subtitle: Text(
                    op['estado'] == 'CONFIRMADA'
                        ? 'Venta'
                        : op['estado'] == 'ACTIVA'
                        ? 'Separación activa'
                        : 'Liberada / historial',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    openOperation(op);
                  },
                ),
              if ((p['operaciones'] as List? ?? []).isEmpty)
                tx('Sin operaciones registradas.', color: muted),
              for (final doc in docs)
                TextButton(
                  onPressed: () => run(() async {
                    final bytes = await c.api.bytes('/documents/${doc['id']}');
                    if (!ctx.mounted) return;
                    await showDialog<void>(
                      context: ctx,
                      builder: (dialog) => AlertDialog(
                        title: Text('Documento ${doc['lado']}'),
                        content: Image.memory(bytes),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialog),
                            child: const Text('Cerrar'),
                          ),
                        ],
                      ),
                    );
                  }),
                  child: Text('Ver ${doc['lado']}'),
                ),
              space(16),
              primary(
                c.lot != null
                    ? 'Usar para esta separación'
                    : 'Editar cliente / cotitular',
                () => Navigator.pop(ctx, 'edit'),
              ),
              space(8),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'delete'),
                child: const Text(
                  'Eliminar registro del cliente',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == 'edit') {
      await run(() async {
        await c.chooseClient(p);
        loadPersonForm(c.selectedClient!);
      });
    }
    if (action == 'unlink' &&
        await confirmAction(
          'Eliminar cotitular',
          'Se retirará el vínculo para nuevas operaciones. Los registros anteriores se conservarán.',
        ))
      await run(() async {
        await c.api.call('DELETE', '/clients/${p['id']}/cotitular');
        await c.refresh();
        message('Cotitular desvinculado.');
      });
    if (action == 'delete' &&
        await confirmAction(
          'Eliminar cliente',
          'Se retirará de la cartera activa. Sus operaciones y datos históricos se conservarán.',
        ))
      await run(() async {
        await c.api.call('DELETE', '/clients/${p['id']}');
        await c.refresh();
        message('Cliente retirado de la cartera.');
      });
  }

  Future<void> openOperation(Data row) => run(() async {
    c.operation = Data.from(
      await c.api.call('GET', '/operations/${row['id']}'),
    );
    go('operation-detail');
  });
  Data operationSnapshot(Data op) {
    final sale = op['venta'];
    return Data.from(sale?['datos_finales'] ?? op['datos_acordados'] ?? {});
  }

  String operationText(Data op) {
    final data = operationSnapshot(op);
    final l = data['lote'] ?? op['lote_actual'] ?? {},
        p = data['titular'] ?? {},
        co = data['cotitular'],
        f = data['condiciones'] ?? {};
    return 'CASA VIP · ${op['estado'] == 'CONFIRMADA' ? 'VENTA' : 'SEPARACIÓN'} ${reservationCode(op)}\n${l['proyecto'] ?? ''} · ${l['etapa'] ?? ''}\nManzana ${l['manzana'] ?? ''} · Lote ${l['codigo'] ?? ''}\nTitular: ${p['nombre'] ?? ''}\n${p['tipo_documento'] ?? 'DNI'}: ${p['numero_documento'] ?? ''}\nTeléfono: ${p['telefono'] ?? ''}\nDirección: ${p['direccion'] ?? ''}\nCorreo: ${p['correo'] ?? ''}\nOcupación: ${p['ocupacion'] ?? ''}\n${co == null ? '' : 'Cotitular: ${co['nombre']} · ${co['tipo_documento']} ${co['numero_documento']}\nTeléfono: ${co['telefono'] ?? ''}\nDirección: ${co['direccion'] ?? ''}\nCorreo: ${co['correo'] ?? ''}\nOcupación: ${co['ocupacion'] ?? ''}\n'}Precio: ${money(f['precio'] ?? op['precio_acordado'])}\nInicial: ${money(f['inicial'] ?? op['inicial_acordada'])}\nCuotas: ${f['numero_cuotas'] ?? op['numero_cuotas_acordado']}\nMensualidad: ${money(f['mensualidad'] ?? op['cuota_acordada'])}\nÚltima cuota: ${money(f['ultima_cuota'])}\nSeparación: ${money(op['monto'])}\nRegistrada: ${dateText(when(op['fecha_registro']))}\n${op['venta'] == null ? '' : 'Venta: ${op['venta']['fecha_venta']}\n'}Observación: ${op['observacion'] ?? ''}';
  }

  Widget operationPage() {
    final op = c.operation;
    if (op == null) return empty('Selecciona una operación.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(
          key: operationImageKey,
          child: uiBox(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                brand(compact: true),
                space(16),
                statusBadge(
                  op['estado'] == 'CONFIRMADA' ? 'VENDIDO' : op['estado'],
                ),
                space(16),
                Text(
                  operationText(op),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.65,
                    color: ink,
                  ),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
          ),
        ),
        space(16),
        primary(
          'Compartir como imagen',
          () => shareBoundary(operationImageKey, 'operacion_${op['id']}.png'),
        ),
        if (c.manager) ...[
          space(10),
          primary(
            'Compartir texto y fotos de DNI',
            () => shareOperationBundle(op),
            outline: true,
          ),
          space(10),
          primary(
            'Corregir información',
            () => correctOperation(op),
            outline: true,
          ),
        ],
        if (c.manager && op['estado'] == 'ACTIVA') ...[
          space(10),
          primary('Registrar venta', () => sellOperation(op)),
          space(8),
          primary('Liberar reserva', () => release(op), outline: true),
          space(8),
          primary('Reasignar lote', () => reassign(op), outline: true),
        ],
        sectionTitle('Historial de la operación'),
        for (final h in cv.CasaController.rows(op['historial'] ?? []))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${h['accion']} · ${h['usuario']}'),
            subtitle: Text(
              '${h['motivo']}\n${dateText(when(h['fecha']))} ${timeText(when(h['fecha']))}',
            ),
          ),
      ],
    );
  }

  Future<void> shareOperationBundle(Data op) => run(() async {
    final record = Data.from(
      await c.api.call('GET', '/operations/${op['id']}/share'),
    );
    final attachments = <Data>[];
    for (final doc in cv.CasaController.rows(record['documentos'] ?? [])) {
      final bytes = await c.api.bytes(
        '/operations/${op['id']}/documents/${doc['id']}',
      );
      attachments.add({
        'bytes': bytes,
        'name':
            'DNI_${doc['id']}_${doc['lado']}.${bytes.isNotEmpty && bytes[0] == 137 ? 'png' : 'jpg'}',
        'mime': bytes.isNotEmpty && bytes[0] == 137
            ? 'image/png'
            : 'image/jpeg',
      });
    }
    await files.shareBundle(operationText(record), attachments);
  });
  Future<void> correctOperation(Data op) async {
    final values = await commercialDialog(op, sale: false);
    if (values == null) return;
    await run(() async {
      c.operation = Data.from(
        await c.api.call('PUT', '/operations/${op['id']}', {
          ...values,
          'version': op['version'],
        }),
      );
      await c.refresh();
      message('Corrección guardada con historial.');
    });
  }

  Future<void> sellOperation(Data row) async {
    Data? op;
    await run(() async {
      op = Data.from(await c.api.call('GET', '/operations/${row['id']}'));
    });
    if (op == null || !mounted) return;
    final values = await commercialDialog(op!, sale: true);
    if (values == null) return;
    await run(() async {
      await c.api.call('POST', '/reservations/${op!['id']}/sale', {
        'plan_id': op!['plan_pago_id'],
        'precio': values['precio'],
        'inicial': values['inicial'],
        'numero_cuotas': values['numero_cuotas'],
        'fecha': values['fecha'],
        'contrato_firmado': true,
      });
      await c.refresh();
      c.operation = Data.from(
        await c.api.call('GET', '/operations/${op!['id']}'),
      );
      go('operation-detail');
      message('Venta registrada.');
    });
  }

  Future<Data?> commercialDialog(Data op, {required bool sale}) async {
    final price = TextEditingController(text: '${op['precio_acordado']}'),
        initial = TextEditingController(text: '${op['inicial_acordada']}'),
        count = TextEditingController(text: '${op['numero_cuotas_acordado']}'),
        deposit = TextEditingController(text: '${op['monto']}'),
        obs = TextEditingController(text: '${op['observacion'] ?? ''}'),
        reasonInput = TextEditingController(),
        date = TextEditingController(
          text:
              '${op['venta']?['fecha_venta'] ?? DateTime.now().toIso8601String().substring(0, 10)}',
        );
    bool signed = false;
    int? selectedClient = (op['cliente_id'] as num?)?.toInt(),
        selectedCo = (op['cotitular_id'] as num?)?.toInt(),
        selectedAdvisor = (op['asesor_id'] as num?)?.toInt();
    if (!sale)
      c.users = cv.CasaController.rows(await c.api.call('GET', '/admin/users'));
    if (!mounted) return null;
    final key = GlobalKey<FormState>();
    return showDialog<Data>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text(sale ? 'Registrar venta' : 'Corregir operación'),
          content: SizedBox(
            width: 390,
            child: SingleChildScrollView(
              child: Form(
                key: key,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    infoNote(
                      'Se conservan las condiciones de esta operación, independientemente del catálogo.',
                      compact: true,
                    ),
                    space(14),
                    field(
                      'Precio acordado (S/)',
                      price,
                      required: true,
                      keyboard: TextInputType.number,
                      onChanged: (_) => update(() {}),
                    ),
                    space(12),
                    field(
                      'Inicial acordada (S/)',
                      initial,
                      required: true,
                      keyboard: TextInputType.number,
                      onChanged: (_) => update(() {}),
                    ),
                    space(12),
                    field(
                      'Número de cuotas',
                      count,
                      required: true,
                      keyboard: TextInputType.number,
                      onChanged: (_) => update(() {}),
                    ),
                    space(10),
                    tx(
                      'Mensualidad: ${money(monthlyForInputs(price.text, initial.text, count.text))}',
                      weight: FontWeight.w700,
                    ),
                    space(12),
                    if (!sale) ...[
                      field(
                        'Monto de separación',
                        deposit,
                        required: true,
                        keyboard: TextInputType.number,
                      ),
                      space(12),
                      field('Observación', obs, lines: 2),
                      space(12),
                      DropdownButtonFormField<int>(
                        initialValue:
                            c.clients.any((p) => p['id'] == selectedClient)
                            ? selectedClient
                            : null,
                        decoration: const InputDecoration(labelText: 'Titular'),
                        items: [
                          for (final p in c.clients.where(
                            (p) =>
                                p['proyecto_id'] ==
                                op['lote_actual']['proyecto_id'],
                          ))
                            DropdownMenuItem(
                              value: (p['id'] as num).toInt(),
                              child: Text(
                                '${p['nombre']}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        isExpanded: true,
                        onChanged: (v) => update(() => selectedClient = v),
                      ),
                      space(12),
                      DropdownButtonFormField<int>(
                        initialValue:
                            c.clients.any((p) => p['id'] == selectedCo)
                            ? selectedCo
                            : 0,
                        decoration: const InputDecoration(
                          labelText: 'Cotitular',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 0,
                            child: Text('Sin cotitular'),
                          ),
                          for (final p in c.clients.where(
                            (p) =>
                                p['proyecto_id'] ==
                                op['lote_actual']['proyecto_id'],
                          ))
                            DropdownMenuItem(
                              value: (p['id'] as num).toInt(),
                              child: Text(
                                '${p['nombre']}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        isExpanded: true,
                        onChanged: (v) => update(() => selectedCo = v),
                      ),
                      space(12),
                      DropdownButtonFormField<int>(
                        initialValue:
                            c.users.any((u) => u['id'] == selectedAdvisor)
                            ? selectedAdvisor
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Asesor asignado',
                        ),
                        items: [
                          for (final u in c.users.where(
                            (u) => u['activo'] == true,
                          ))
                            DropdownMenuItem(
                              value: (u['id'] as num).toInt(),
                              child: Text(
                                '${u['nombre']}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        isExpanded: true,
                        onChanged: (v) => update(() => selectedAdvisor = v),
                      ),
                      space(12),
                      field(
                        'Motivo de la corrección',
                        reasonInput,
                        required: true,
                        maxLength: 500,
                      ),
                      space(12),
                    ],
                    if (sale || op['estado'] == 'CONFIRMADA')
                      field(
                        'Fecha de venta (AAAA-MM-DD)',
                        date,
                        required: true,
                      ),
                    if (sale)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Contrato firmado'),
                        value: signed,
                        onChanged: (v) => update(() => signed = v ?? false),
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!key.currentState!.validate()) return;
                final p = num.tryParse(price.text.replaceAll(',', '.')),
                    i = num.tryParse(initial.text.replaceAll(',', '.')),
                    n = int.tryParse(count.text),
                    m = num.tryParse(deposit.text.replaceAll(',', '.'));
                if (p == null ||
                    i == null ||
                    n == null ||
                    m == null ||
                    p <= 0 ||
                    i <= 0 ||
                    i > p ||
                    n < 1 ||
                    n > 600 ||
                    m <= 0 ||
                    m > p) {
                  message('Revisa los montos y el número de cuotas.');
                  return;
                }
                if (sale && !signed) {
                  message('Confirma el contrato firmado.');
                  return;
                }
                Navigator.pop(ctx, {
                  'precio': p,
                  'inicial': i,
                  'numero_cuotas': n,
                  'monto': m,
                  'observacion': obs.text,
                  'motivo': reasonInput.text,
                  'cliente_id': selectedClient,
                  'cotitular_id': selectedCo == 0 ? null : selectedCo,
                  'quitar_cotitular': selectedCo == 0,
                  'asesor_id': selectedAdvisor,
                  if (sale || op['estado'] == 'CONFIRMADA') 'fecha': date.text,
                });
              },
              child: Text(sale ? 'Confirmar venta' : 'Guardar corrección'),
            ),
          ],
        ),
      ),
    );
  }

  Widget managementShortcuts() => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (c.admin)
          OutlinedButton.icon(
            onPressed: () => openManagement('catalog'),
            icon: const Icon(Icons.price_change_outlined, size: 17),
            label: const Text('Precios'),
          ),
        OutlinedButton.icon(
          onPressed: () => openManagement('users'),
          icon: const Icon(Icons.manage_accounts_outlined, size: 17),
          label: const Text('Usuarios'),
        ),
        OutlinedButton.icon(
          onPressed: () => openManagement('history-all'),
          icon: const Icon(Icons.history, size: 17),
          label: const Text('Historiales'),
        ),
      ],
    ),
  );
  Future<void> openManagement(String screen) => run(() async {
    if (screen == 'users')
      c.users = cv.CasaController.rows(await c.api.call('GET', '/admin/users'));
    if (screen == 'catalog')
      c.catalog = cv.CasaController.rows(
        await c.api.call('GET', '/admin/catalog'),
      );
    if (screen == 'history-all')
      c.history = cv.CasaController.rows(
        await c.api.call('GET', '/admin/history'),
      );
    go(screen);
  });
  Widget usersPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (c.admin) primary('Agregar usuario', () => userEditor()),
      space(12),
      if (!c.admin)
        infoNote(
          'Puedes consultar la lista y deshabilitar usuarios. La creación, edición y habilitación corresponden al administrador.',
          compact: true,
        ),
      for (final u in c.users) ...[
        space(10),
        uiBox(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tx('${u['nombre']}', weight: FontWeight.w700),
              space(4),
              tx(
                '${u['correo']}\n${u['rol']} · ${u['activo'] == true ? 'Activo' : 'Deshabilitado'}',
                size: 12,
                color: muted,
              ),
              space(6),
              Wrap(
                spacing: 8,
                children: [
                  if (c.admin)
                    TextButton(
                      onPressed: () => userEditor(u),
                      child: const Text('Editar'),
                    ),
                  if (u['activo'] == true || c.admin)
                    TextButton(
                      onPressed: () => changeUserActive(u),
                      child: Text(
                        u['activo'] == true ? 'Deshabilitar' : 'Habilitar',
                      ),
                    ),
                  if (c.admin)
                    TextButton(
                      onPressed: () => deleteUser(u),
                      child: const Text(
                        'Eliminar',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    ],
  );
  Future<void> changeUserActive(Data u) async {
    final active = u['activo'] != true;
    if (!await confirmAction(
      active ? 'Habilitar usuario' : 'Deshabilitar usuario',
      '${u['nombre']}. ${active ? 'Recuperará el acceso.' : 'Se cerrarán sus sesiones activas.'}',
    ))
      return;
    await run(() async {
      await c.api.call('PATCH', '/admin/users/${u['id']}/active', {
        'activo': active,
      });
      c.users = cv.CasaController.rows(await c.api.call('GET', '/admin/users'));
    });
  }

  Future<void> deleteUser(Data u) async {
    if (!await confirmAction(
      'Eliminar usuario',
      'La cuenta dejará de estar disponible. Sus operaciones históricas se conservarán.',
    ))
      return;
    await run(() async {
      await c.api.call('DELETE', '/admin/users/${u['id']}');
      c.users = cv.CasaController.rows(await c.api.call('GET', '/admin/users'));
    });
  }

  Future<void> userEditor([Data? user]) async {
    final name = TextEditingController(text: '${user?['nombre'] ?? ''}'),
        emailInput = TextEditingController(text: '${user?['correo'] ?? ''}'),
        phoneInput = TextEditingController(text: '${user?['telefono'] ?? ''}'),
        pass = TextEditingController();
    String role = '${user?['rol'] ?? 'ASESOR'}';
    bool active = user?['activo'] ?? true;
    final key = GlobalKey<FormState>();
    final data = await showDialog<Data>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text(user == null ? 'Agregar usuario' : 'Editar usuario'),
          content: SingleChildScrollView(
            child: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  field('Nombre', name, required: true, maxLength: 160),
                  space(12),
                  field(
                    'Correo',
                    emailInput,
                    required: true,
                    maxLength: 254,
                    keyboard: TextInputType.emailAddress,
                  ),
                  space(12),
                  field('Teléfono', phoneInput, maxLength: 30),
                  space(12),
                  field(
                    user == null ? 'Contraseña' : 'Nueva contraseña (opcional)',
                    pass,
                    obscure: true,
                    required: user == null,
                    maxLength: 64,
                  ),
                  space(12),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    items: [
                      for (final r in [
                        'ASESOR',
                        'RESPONSABLE_COMERCIAL',
                        'ADMINISTRADOR',
                      ])
                        DropdownMenuItem(
                          value: r,
                          child: Text(
                            r == 'ASESOR'
                                ? 'Asesor'
                                : r == 'ADMINISTRADOR'
                                ? 'Administrador'
                                : 'Responsable comercial',
                          ),
                        ),
                    ],
                    isExpanded: true,
                    onChanged: (v) => update(() => role = v!),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Activo'),
                    value: active,
                    onChanged: (v) => update(() => active = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (key.currentState!.validate())
                  Navigator.pop(ctx, {
                    'nombre': name.text,
                    'correo': emailInput.text,
                    'telefono': phoneInput.text,
                    'rol': role,
                    'password': pass.text,
                    'activo': active,
                  });
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (data == null) return;
    await run(() async {
      await c.api.call(
        user == null ? 'POST' : 'PUT',
        user == null ? '/admin/users' : '/admin/users/${user['id']}',
        data,
      );
      c.users = cv.CasaController.rows(await c.api.call('GET', '/admin/users'));
      message('Usuario guardado.');
    });
  }

  Widget catalogPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      infoNote(
        'Los lotes vendidos se omiten. Las separaciones conservan las condiciones pactadas. Usa lote_id para identificar cada lote.',
        compact: true,
      ),
      space(14),
      primary('Importar CSV, Excel o JSON', previewCatalog),
      space(8),
      TextButton(
        onPressed: () => files.shareFile(
          Uint8List.fromList(
            utf8.encode(
              'lote_id,precio,inicial,numero_cuotas,area_m2,ubicacion\n3,21000,3000,48,124.42,Interior\n',
            ),
          ),
          'plantilla_precios.csv',
          'text/csv',
        ),
        child: const Text('Descargar plantilla CSV'),
      ),
      if (catalogPreview.isNotEmpty) ...[
        sectionTitle('Vista previa · $catalogFilename'),
        for (final r in catalogPreview)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${r['proyecto']} · ${r['manzana']}-${r['lote']}'),
            subtitle: Text(
              r['omitido'] == true
                  ? 'Vendido: se omitirá'
                  : '${money(r['precio_anterior'])} → ${money(r['precio'])}',
            ),
          ),
        primary('Aplicar actualización', applyCatalog),
        space(18),
      ],
      sectionTitle('Catálogo vigente'),
      for (final l in c.catalog) ...[
        uiBox(
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${l['proyecto']} · ${l['manzana']}-${l['lote']}'),
            subtitle: Text('${money(l['precio'])} · ${l['estado']}'),
            trailing: l['estado'] == 'VENDIDO'
                ? const Icon(Icons.lock_outline, size: 18)
                : const Icon(Icons.edit_outlined, size: 18),
            onTap: l['estado'] == 'VENDIDO' ? null : () => editCatalogLot(l),
          ),
        ),
        space(8),
      ],
    ],
  );
  Future<void> previewCatalog() async {
    final file = await files.pickCatalog();
    if (file == null) return;
    await run(() async {
      final data = await c.api.previewCatalog(file.bytes, file.name);
      catalogPreview = cv.CasaController.rows(data['rows']);
      catalogFilename = file.name;
    });
  }

  Future<void> applyCatalog() async {
    final note = await reason('Motivo de actualización del catálogo');
    if (note == null) return;
    await run(() async {
      final result = await c.api.call('POST', '/admin/catalog/apply', {
        'rows': catalogPreview,
        'motivo': note,
      });
      catalogPreview = [];
      c.catalog = cv.CasaController.rows(
        await c.api.call('GET', '/admin/catalog'),
      );
      await c.refresh();
      message(
        '${result['actualizados']} lotes actualizados; ${result['vendidos_omitidos']} vendidos omitidos.',
      );
    });
  }

  Future<void> editCatalogLot(Data row) async {
    Data? lot;
    await run(() async {
      lot = Data.from(await c.api.call('GET', '/lots/${row['lote_id']}'));
    });
    if (lot == null || !mounted) return;
    final plans = cv.CasaController.rows(lot!['planes']);
    final p = plans.isEmpty ? <String, dynamic>{} : plans.last;
    final price = TextEditingController(text: '${row['precio']}'),
        initial = TextEditingController(text: '${p['inicial'] ?? 0}'),
        count = TextEditingController(text: '${p['numero_cuotas'] ?? 48}'),
        area = TextEditingController(text: '${row['area_m2']}'),
        location = TextEditingController(text: '${row['ubicacion'] ?? ''}');
    final key = GlobalKey<FormState>();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Catálogo · ${row['manzana']}-${row['lote']}'),
        content: SingleChildScrollView(
          child: Form(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                field('Precio de catálogo', price, required: true),
                space(12),
                field('Inicial del plan', initial, required: true),
                space(12),
                field('Número de cuotas del plan', count, required: true),
                space(12),
                field('Área (m²)', area, required: true),
                space(12),
                field('Ubicación', location, maxLength: 160),
                space(10),
                infoNote(
                  'Esta edición publica un plan para este lote. Para publicar varios planes usa JSON con la propiedad planes.',
                  compact: true,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Vista previa'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    repaint(() {
      catalogFilename = 'Edición manual';
      catalogPreview = [
        {
          ...row,
          'precio_anterior': row['precio'],
          'precio': price.text,
          'inicial': initial.text,
          'numero_cuotas': count.text,
          'area_m2': area.text,
          'ubicacion': location.text,
          'omitido': false,
        },
      ];
    });
  }

  Widget historyPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: 6,
        children: [
          for (final e in [
            ('', 'Todos'),
            ('CLIENTE', 'Clientes'),
            ('OPERACION', 'Operaciones'),
            ('CATALOGO', 'Precios'),
            ('USUARIO', 'Usuarios'),
          ])
            ChoiceChip(
              label: Text(e.$2),
              selected: historyFilter == e.$1,
              onSelected: (_) => run(() async {
                historyFilter = e.$1;
                c.history = cv.CasaController.rows(
                  await c.api.call(
                    'GET',
                    '/admin/history${historyFilter.isEmpty ? '' : '?entity=$historyFilter'}',
                  ),
                );
              }),
            ),
        ],
      ),
      space(14),
      for (final h in c.history) ...[
        uiBox(
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${h['entidad']} #${h['registro_id']} · ${h['accion']}',
            ),
            subtitle: Text(
              '${h['usuario']} · ${dateText(when(h['fecha']))}\n${h['motivo']}',
            ),
            onTap: () => showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Detalle guardado'),
                content: SingleChildScrollView(
                  child: SelectableText(
                    const JsonEncoder.withIndent('  ').convert({
                      'anterior': h['anterior'],
                      'actual': h['actual'],
                    }),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ),
          ),
        ),
        space(8),
      ],
      if (c.history.isEmpty)
        empty('No hay cambios registrados con este filtro.'),
    ],
  );
  Widget notificationPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      infoNote(
        'Avisos globales de separaciones, ventas y liberaciones. Se actualizan cada 15 segundos mientras mantienes la sesión abierta.',
        compact: true,
      ),
      space(10),
      Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => run(c.pollNotifications),
              child: const Text('Actualizar'),
            ),
          ),
          Expanded(
            child: TextButton(
              onPressed: c.notifications.isEmpty
                  ? null
                  : () => run(() async {
                      await c.api.call('POST', '/notifications/read', {
                        'hasta': c.notifications.first['id'],
                      });
                      await c.pollNotifications();
                    }),
              child: const Text('Marcar como leídas'),
            ),
          ),
        ],
      ),
      for (final n in c.notifications) ...[
        uiBox(
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              n['leida'] == true
                  ? Icons.notifications_none
                  : Icons.notifications_active_outlined,
              color: primaryGold,
            ),
            title: Text('${n['titulo']}'),
            subtitle: Text(
              '${n['mensaje']}\n${dateText(when(n['fecha']))} ${timeText(when(n['fecha']))}',
            ),
            onTap: () => run(() async {
              await c.api.call('POST', '/notifications/${n['id']}/read');
              await c.pollNotifications();
              if (n['operacion_id'] != null) {
                c.operation = Data.from(
                  await c.api.call('GET', '/operations/${n['operacion_id']}'),
                );
                go('operation-detail');
              }
            }),
          ),
        ),
        space(9),
      ],
      if (c.notifications.isEmpty) empty('No hay notificaciones todavía.'),
    ],
  );
}
