import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'api.dart';
import 'controller.dart' as cv;
import 'platform_io.dart' as files;
import 'prototype_style.dart';
import 'financial_terms.dart';
import 'listing_filter.dart';
import 'deadline.dart';

part 'commercial_extension.dart';
part 'listing_ui.dart';
part 'dashboard_ui.dart';

void main() => runApp(const CasaVipApp());

class CasaVipApp extends StatelessWidget {
  final ApiClient? api;
  const CasaVipApp({super.key, this.api});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CASA VIP',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      fontFamily: 'Arial',
      scaffoldBackgroundColor: paper,
      colorScheme: ColorScheme.fromSeed(
        seedColor: gold,
        primary: primaryGold,
        surface: paper,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 14, color: ink),
        bodyLarge: TextStyle(fontSize: 14, color: ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xffd7d3c9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xffd7d3c9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryGold),
      ),
    ),
    home: CasaView(api: api),
  );
}

class CasaView extends StatefulWidget {
  final ApiClient? api;
  const CasaView({super.key, this.api});
  @override
  State<CasaView> createState() => _CasaViewState();
}

class _CasaViewState extends State<CasaView> {
  late final cv.CasaController c;
  final email = TextEditingController(), password = TextEditingController();
  final names = TextEditingController(),
      document = TextEditingController(),
      phone = TextEditingController(),
      address = TextEditingController(),
      mail = TextEditingController(),
      occupation = TextEditingController();
  final coNames = TextEditingController(),
      coDocument = TextEditingController(),
      coPhone = TextEditingController(),
      coAddress = TextEditingController(),
      coMail = TextEditingController(),
      coOccupation = TextEditingController();
  final deadlineDays = TextEditingController(text: '14');
  bool rememberSession = false, hadSession = false;
  final amount = TextEditingController(text: '500.00'),
      observation = TextEditingController(),
      search = TextEditingController();
  final loginKey = GlobalKey<FormState>(),
      clientKey = GlobalKey<FormState>(),
      separationKey = GlobalKey<FormState>(),
      sheetKey = GlobalKey(),
      receiptKey = GlobalKey();
  List<Data> catalogPreview = [];
  String catalogFilename = '';
  void repaint(VoidCallback change) => setState(change);
  final operationImageKey = GlobalKey();
  final negotiatedPrice = TextEditingController(),
      negotiatedInitial = TextEditingController(),
      negotiatedCount = TextEditingController();
  int? draftLot;
  bool busy = false, confirmed = false, withCo = false;
  String chip = 'Todos',
      filterState = '',
      filterLocation = '',
      projectLocation = '';
  int? filterStage;
  String get screen => c.screen;
  String get firstName => '${c.user?['name'] ?? ''}'.split(' ').first;
  String get userName => '${c.user?['name'] ?? 'Asesor'}';
  String get roleLabel => c.admin
      ? 'Administrador'
      : c.manager
      ? 'Responsable comercial'
      : 'Asesor comercial';
  String projectName(dynamic n) =>
      '$n' == 'SHENNAN HOUSE' ? 'Shennan House' : '${n ?? ''}';
  String get projectTitle => projectName(
    c.project?['nombre'] ?? c.lot?['proyecto'] ?? 'Shennan House',
  );
  List<Data> get plans =>
      c.lot?['planes'] == null ? [] : cv.CasaController.rows(c.lot!['planes']);
  Data get plan =>
      c.selectedPlan ?? (plans.isEmpty ? <String, dynamic>{} : plans.last);
  String get lotCode => '${c.lot?['codigo'] ?? ''}'.padLeft(2, '0');
  String get lotSubtitle =>
      'Manzana ${c.lot?['manzana'] ?? ''} · Lote $lotCode';
  DateTime when(dynamic value) =>
      DateTime.tryParse('$value')?.toLocal() ?? DateTime.now();
  String dateText(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String timeText(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  String get dateHeading {
    final d = DateTime.now();
    const days = [
      'LUNES',
      'MARTES',
      'MIÉRCOLES',
      'JUEVES',
      'VIERNES',
      'SÁBADO',
      'DOMINGO',
    ];
    const months = [
      'ENERO',
      'FEBRERO',
      'MARZO',
      'ABRIL',
      'MAYO',
      'JUNIO',
      'JULIO',
      'AGOSTO',
      'SEPTIEMBRE',
      'OCTUBRE',
      'NOVIEMBRE',
      'DICIEMBRE',
    ];
    return '${days[d.weekday - 1]}, ${d.day.toString().padLeft(2, '0')} DE ${months[d.month - 1]}';
  }

  @override
  void initState() {
    super.initState();
    const configured = String.fromEnvironment('API_URL');
    final base = configured.isNotEmpty
        ? configured
        : (kIsWeb ? Uri.base.origin : 'http://10.0.2.2:8080');
    c = cv.CasaController(widget.api ?? ApiClient(base));
    c.addListener(changed);
    amount.addListener(amountChanged);
    if (widget.api == null) unawaited(c.restoreSession());
  }

  void amountChanged() {
    final value = num.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
    final days = defaultDeadline(value);
    deadlineDays.text = days?.toString() ?? '';
    if (mounted) setState(() {});
  }

  void changed() {
    if (c.user != null) hadSession = true;
    if (c.screen == 'login' && hadSession) {
      email.clear();
      password.clear();
      rememberSession = false;
      hadSession = false;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final t in [
      email,
      password,
      names,
      document,
      phone,
      address,
      mail,
      occupation,
      coNames,
      coDocument,
      coPhone,
      coAddress,
      coMail,
      coOccupation,
      amount,
      deadlineDays,
      observation,
      search,
      negotiatedPrice,
      negotiatedInitial,
      negotiatedCount,
    ]) {
      t.dispose();
    }
    c.removeListener(changed);
    c.dispose();
    super.dispose();
  }

  void message(String s) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        if (e is ApiException && e.status == 401 && screen != 'login') {
          c.clear();
        }
        message(
          e is ApiException
              ? e.message
              : 'No se pudo completar la operación. Inténtalo nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void go(String s) {
    if (s == 'clients') c.lot = null;
    search.clear();
    chip = 'Todos';
    filterState = '';
    filterLocation = '';
    filterStage = null;
    c.go(s);
    if (s == 'clients') run(c.loadClients);
    if (s == 'reservations') run(c.loadOperations);
  }

  void back() {
    go(switch (screen) {
      'blocks' => 'projects',
      'lots' => 'blocks',
      'lot-detail' => 'lots',
      'commercial-sheet' => 'lot-detail',
      'client-form' => c.lot == null ? 'clients' : 'lot-detail',
      'documents' => 'client-form',
      'separation' => 'documents',
      'review' => 'separation',
      'operation-detail' => 'reservations',
      _ => 'home',
    });
  }

  void clearClient() {
    for (final f in [
      names,
      document,
      phone,
      address,
      mail,
      occupation,
      coNames,
      coDocument,
      coPhone,
      coAddress,
      coMail,
      coOccupation,
    ]) {
      f.clear();
    }
    withCo = false;
    confirmed = false;
    c.selectedClient = null;
    c.coClient = null;
    c.documents = [];
    c.coDocuments = [];
    amount.text = '500.00';
    observation.clear();
  }

  void newClient() {
    clearClient();
    go('client-form');
  }

  Widget tap(
    Widget child,
    VoidCallback? action, {
    String? label,
    double radius = 12,
  }) => Semantics(
    button: true,
    enabled: action != null,
    label: label,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action,
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    ),
  );
  Widget field(
    String label,
    TextEditingController controller, {
    bool required = false,
    bool obscure = false,
    bool compact = false,
    String? icon,
    String? hint,
    TextInputType? keyboard,
    int lines = 1,
    int? maxLength,
    void Function(String)? onChanged,
    String? Function(String?)? validate,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      tx(
        label,
        size: 12.64,
        weight: FontWeight.w700,
        color: const Color(0xff3a3935),
      ),
      space(8),
      Semantics(
        label: label,
        child: TextFormField(
          key: ValueKey(label),
          controller: controller,
          obscureText: obscure,
          maxLines: lines,
          maxLength: maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.none,
          onChanged: onChanged,
          keyboardType: keyboard,
          style: const TextStyle(fontSize: 14.4, height: 1.2, color: ink),
          autofillHints: label == 'Correo corporativo'
              ? [AutofillHints.username]
              : label == 'Contraseña'
              ? [AutofillHints.password]
              : null,
          decoration: InputDecoration(
            constraints: BoxConstraints(minHeight: compact ? 41 : 44),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: compact ? 10 : 12,
            ),
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xff8a867d), fontSize: 14),
            prefixIcon: icon == null
                ? null
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ico(icon, size: 18, color: const Color(0xff8a867d)),
                  ),
            prefixIconConstraints: icon == null
                ? null
                : const BoxConstraints(minWidth: 40, maxWidth: 40),
          ),
          validator: (value) {
            if (maxLength != null && (value?.runes.length ?? 0) > maxLength) {
              return 'Máximo $maxLength caracteres.';
            }
            if (validate != null) return validate(value);
            return required && (value == null || value.trim().isEmpty)
                ? 'Completa este campo.'
                : null;
          },
        ),
      ),
    ],
  );
  Widget header(String title, String subtitle, {bool canBack = false}) =>
      Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: const BoxDecoration(
          color: ink,
          border: PrototypeBorder(bottom: BorderSide(color: gold, width: 3)),
        ),
        child: Row(
          children: [
            if (canBack)
              Semantics(
                button: true,
                label: 'Volver',
                child: tap(
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xff2b2b27),
                      border: Border.all(color: const Color(0xff3e3e38)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: ico('arrow-left', color: Colors.white),
                  ),
                  back,
                ),
              )
            else
              brand(compact: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  tx(
                    title,
                    size: 16.32,
                    color: Colors.white,
                    weight: FontWeight.w700,
                    height: 1.5,
                  ),
                  space(2),
                  tx(
                    subtitle,
                    size: 12.48,
                    color: const Color(0xffb9b6ae),
                    height: 1.5,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Notificaciones',
              onPressed: () => go('notifications'),
              icon: Badge(
                isLabelVisible: c.unread > 0,
                label: Text('${c.unread > 99 ? '99+' : c.unread}'),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Mi cuenta',
              padding: EdgeInsets.zero,
              onSelected: accountAction,
              itemBuilder: (ctx) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName),
                      Text(
                        roleLabel,
                        style: const TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ),
                ),
                if (screen == 'lot-detail')
                  const PopupMenuItem(
                    value: 'history',
                    child: Text('Historial del lote'),
                  ),
                if (c.admin && screen == 'lot-detail')
                  const PopupMenuItem(
                    value: 'state',
                    child: Text('Administrar estado'),
                  ),
                if (c.manager && screen == 'reservations')
                  const PopupMenuItem(
                    value: 'dashboard',
                    child: Text('Dashboard y reportes'),
                  ),
                if (c.admin)
                  const PopupMenuItem(
                    value: 'catalog',
                    child: Text('Catálogo y precios'),
                  ),
                if (c.manager)
                  const PopupMenuItem(value: 'users', child: Text('Usuarios')),
                if (c.manager)
                  const PopupMenuItem(
                    value: 'dashboard',
                    child: Text('Dashboard y reportes'),
                  ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Text('Cerrar sesión'),
                ),
              ],
              child: avatar(userName),
            ),
          ],
        ),
      );
  void accountAction(String action) {
    if (['catalog', 'users', 'history-all', 'dashboard'].contains(action)) {
      openManagement(action);
      return;
    }
    if (action == 'logout') {
      run(c.logout);
    }
    if (action == 'history') {
      showHistory();
    }
    if (action == 'state') {
      adminState();
    }
    if (action == 'excel') {
      run(() async {
        final b = await c.api.bytes('/reports/reservations.xlsx');
        await files.shareFile(
          b,
          'separaciones.xlsx',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
      });
    }
  }

  Widget nav() => Container(
    height: 68,
    padding: const EdgeInsets.fromLTRB(4, 7, 4, 8),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: PrototypeBorder(top: BorderSide(color: Color(0xffdedad1))),
    ),
    child: Row(
      children: [
        for (final item in [
          ('home', 'Inicio', 'house'),
          ('projects', 'Proyectos', 'building-2'),
          ('clients', 'Clientes', 'users-round'),
          ('reservations', 'Operaciones', 'file-text'),
        ])
          Expanded(
            child: Builder(
              builder: (context) {
                final active =
                    screen == item.$1 ||
                    (item.$1 == 'projects' &&
                        ['blocks', 'lots', 'lot-detail'].contains(screen));
                return Semantics(
                  selected: active,
                  button: true,
                  label: item.$2,
                  child: tap(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ico(
                          item.$3,
                          size: 20,
                          color: active
                              ? const Color(0xff9a6f05)
                              : const Color(0xff858178),
                          stroke: active ? 2.4 : 1.9,
                        ),
                        space(4),
                        tx(
                          item.$2,
                          size: 8.96,
                          color: active
                              ? const Color(0xff9a6f05)
                              : const Color(0xff858178),
                          weight: active ? FontWeight.w800 : FontWeight.w400,
                        ),
                      ],
                    ),
                    () => go(item.$1),
                  ),
                );
              },
            ),
          ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, constraints) {
        final framed = constraints.maxWidth > 480;
        final view = Stack(
          children: [
            Column(
              children: [
                if (screen != 'login' && screen != 'success')
                  header(
                    switch (screen) {
                      'home' => 'Hola, $firstName',
                      'projects' => 'Proyectos',
                      'blocks' => projectTitle,
                      'lots' => 'Manzana ${c.block?['codigo'] ?? ''}',
                      'lot-detail' => 'Detalle del lote',
                      'commercial-sheet' => 'Ficha comercial',
                      'client-form' => 'Registrar cliente',
                      'documents' => 'Documentos de identidad',
                      'separation' => 'Datos de separación',
                      'review' => 'Confirmar separación',
                      'clients' => 'Clientes',
                      'reservations' => 'Operaciones',
                      'operation-detail' => 'Detalle de operación',
                      'notifications' => 'Notificaciones',
                      'users' => 'Usuarios',
                      'catalog' => 'Catálogo y precios',
                      'history-all' => 'Historial comercial',
                      'dashboard' => 'Dashboard comercial',
                      _ => 'CASA VIP',
                    },
                    switch (screen) {
                      'home' => roleLabel,
                      'projects' => 'Selecciona dónde buscar',
                      'blocks' => 'Elige una manzana',
                      'lots' => projectTitle,
                      'lot-detail' => projectTitle,
                      'commercial-sheet' => 'Lista para compartir',
                      'client-form' =>
                        c.lot == null ? 'Registro comercial' : lotSubtitle,
                      'documents' => '${c.selectedClient?['nombre'] ?? ''}',
                      'separation' => lotSubtitle,
                      'review' => 'Revisa antes de registrar',
                      'clients' => 'Mi cartera comercial',
                      'reservations' => 'Operaciones del asesor',
                      _ => roleLabel,
                    },
                    canBack: ![
                      'home',
                      'projects',
                      'clients',
                      'reservations',
                    ].contains(screen),
                  ),
                Expanded(
                  child: screen == 'login'
                      ? login()
                      : screen == 'success'
                      ? success()
                      : SingleChildScrollView(
                          key: ValueKey(screen),
                          padding: EdgeInsets.fromLTRB(
                            20,
                            [
                                  'client-form',
                                  'documents',
                                  'separation',
                                  'review',
                                ].contains(screen)
                                ? 17
                                : screen == 'lots'
                                ? 16
                                : 22,
                            20,
                            30,
                          ),
                          child: viewForScreen(),
                        ),
                ),
                if (![
                  'login',
                  'commercial-sheet',
                  'client-form',
                  'documents',
                  'separation',
                  'review',
                  'success',
                ].contains(screen))
                  nav(),
              ],
            ),
            if (busy)
              const Positioned.fill(
                child: AbsorbPointer(
                  child: ColoredBox(
                    color: Color(0x11000000),
                    child: Center(
                      child: CircularProgressIndicator(color: gold),
                    ),
                  ),
                ),
              ),
          ],
        );
        return ColoredBox(
          color: const Color(0xffe8e4dc),
          child: Center(
            child: Container(
              width: framed ? 430 : constraints.maxWidth,
              height: framed
                  ? math.min(900, constraints.maxHeight - 36)
                  : constraints.maxHeight,
              margin: framed ? const EdgeInsets.all(18) : EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: paper,
                borderRadius: BorderRadius.circular(framed ? 30 : 0),
                border: framed
                    ? Border.all(color: const Color(0xffd8d3c9))
                    : null,
                boxShadow: framed
                    ? [
                        const BoxShadow(
                          color: Color(0x301f1b13),
                          blurRadius: 70,
                          offset: Offset(0, 26),
                        ),
                      ]
                    : null,
              ),
              child: SafeArea(child: view),
            ),
          ),
        );
      },
    ),
  );
  Widget viewForScreen() => switch (screen) {
    'home' => home(),
    'projects' => projects(),
    'blocks' => blocks(),
    'lots' => lots(),
    'lot-detail' => detail(),
    'commercial-sheet' => commercial(),
    'client-form' => clientForm(),
    'documents' => documents(),
    'separation' => separation(),
    'review' => review(),
    'clients' => clients(),
    'reservations' => reservations(),
    'operation-detail' => operationPage(),
    'notifications' => notificationPage(),
    'users' => usersPage(),
    'catalog' => catalogPage(),
    'history-all' => historyPage(),
    'dashboard' => dashboardPage(),
    _ => const SizedBox.shrink(),
  };
  Widget login() => ColoredBox(
    color: Colors.white,
    child: SingleChildScrollView(
      key: const ValueKey('login-scroll'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 248,
            child: Stack(
              children: [
                const Positioned.fill(child: ColoredBox(color: ink)),
                Positioned.fill(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 16,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: gold.withValues(alpha: .38)),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [brand()],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 26, 26, 22),
            child: Form(
              key: loginKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  eyebrow('ACCESO'),
                  space(4),
                  tx('Bienvenido', size: 28, height: 1.5, spacing: -1.1),
                  space(7),
                  space(23),
                  field(
                    'Correo corporativo',
                    email,
                    maxLength: 254,
                    required: true,
                    icon: 'user-round',
                    hint: 'asesor@casavip.pe',
                    keyboard: TextInputType.emailAddress,
                  ),
                  space(17),
                  field(
                    'Contraseña',
                    password,
                    maxLength: 64,
                    validate: (v) => v == null || v.isEmpty
                        ? 'Completa este campo.'
                        : utf8.encode(v).length > 72
                        ? 'La contraseña excede el tamaño permitido.'
                        : null,
                    required: true,
                    obscure: true,
                    icon: 'lock-keyhole',
                    hint: '••••••••',
                  ),
                  space(17),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'Mantener sesión iniciada',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: rememberSession,
                    onChanged: (v) =>
                        setState(() => rememberSession = v ?? false),
                  ),
                  primary(
                    'Ingresar',
                    () => run(() async {
                      if (loginKey.currentState!.validate()) {
                        await c.login(
                          email.text.trim(),
                          password.text,
                          remember: rememberSession,
                        );
                        email.clear();
                        password.clear();
                      }
                    }),
                    after: 'arrow-right',
                  ),
                  if (!kIsWeb)
                    TextButton.icon(
                      onPressed: busy ? null : configureServer,
                      icon: const Icon(Icons.settings_ethernet, size: 16),
                      label: const Text('Conexión al servidor'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
  Widget home() {
    final active = c.reservations.where((r) => r['estado'] == 'ACTIVA').length;
    final available = c.projects.fold<int>(
      0,
      (sum, p) => sum + (p['disponibles'] as num? ?? 0).toInt(),
    );
    final recent = c.reservations.isEmpty ? null : c.reservations.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.manager) managementShortcuts(),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: charcoal,
            border: Border.all(color: const Color(0xff31312b)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -31,
                top: -34,
                child: Transform.rotate(
                  angle: .314,
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      border: Border.all(color: gold.withValues(alpha: .38)),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 19,
                  vertical: 21,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          eyebrow(dateHeading, golden: true),
                          space(7),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 260),
                            child: tx(
                              '¿Qué deseas gestionar hoy?',
                              size: 23.68,
                              height: 1.12,
                              color: Colors.white,
                              spacing: -.8,
                            ),
                          ),
                          space(7),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 250),
                            child: tx(
                              'Consulta información vigente antes de atender a tu cliente.',
                              size: 13.12,
                              color: const Color(0xffbdbab2),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 62,
                      height: 62,
                      child: Center(
                        child: ico(
                          'house',
                          size: 46,
                          color: const Color(0xffd8aa32),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        sectionTitle('Acciones rápidas'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 112,
              child: quickCard(
                'Buscar lote',
                'Precio y disponibilidad',
                'search',
                () => go('projects'),
                featured: true,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              flex: 88,
              child: quickCard(
                'Nuevo cliente',
                'Registro comercial',
                'user-round',
                () {
                  c.lot = null;
                  newClient();
                },
              ),
            ),
          ],
        ),
        sectionTitle(
          'Resumen de hoy',
          action: 'Ver actividad',
          onAction: () => go('reservations'),
        ),
        Row(
          children: [
            Expanded(
              child: metric(
                '$available',
                'Lotes disponibles',
                'layout-grid',
                const Color(0xffe4f2e7),
                const Color(0xff28713d),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: metric(
                '$active',
                'Separaciones',
                'file-text',
                const Color(0xffe5edf7),
                const Color(0xff2f5d91),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: metric(
                '${c.clients.length}',
                'Clientes activos',
                'users-round',
                const Color(0xfffff1c8),
                const Color(0xff9a6d00),
              ),
            ),
          ],
        ),
        space(18),
        tap(
          uiBox(
            Row(
              children: [
                Container(
                  width: 37,
                  height: 37,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xfffff2cf),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ico('clock-3', color: const Color(0xff9c7104)),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      tx(
                        'Última actividad',
                        size: 12.64,
                        weight: FontWeight.w700,
                      ),
                      space(3),
                      tx(
                        recent == null
                            ? 'Todavía no hay separaciones.'
                            : 'Separación de Manzana ${recent['manzana']} · Lote ${recent['lote']}',
                        size: 11.2,
                        color: muted,
                      ),
                    ],
                  ),
                ),
                if (recent != null)
                  tx(
                    timeText(when(recent['fecha_registro'])),
                    size: 11.04,
                    color: muted,
                  ),
              ],
            ),
            borders: const PrototypeBorder(
              left: BorderSide(color: gold, width: 3),
              top: BorderSide(color: border),
              right: BorderSide(color: border),
              bottom: BorderSide(color: border),
            ),
            radius: 12,
          ),
          () => go('reservations'),
        ),
      ],
    );
  }

  Widget quickCard(
    String label,
    String hint,
    String icon,
    VoidCallback action, {
    bool featured = false,
  }) => tap(
    Container(
      constraints: const BoxConstraints(minHeight: 122),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: featured ? const Color(0xfffff7dc) : Colors.white,
        border: Border.all(color: featured ? const Color(0xffe5cc7f) : border),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ico(icon, size: 23, color: const Color(0xffa57704)),
              space(12),
              tx(label, size: 14.4, weight: FontWeight.w700),
              space(3),
              tx(hint, size: 11.2, color: const Color(0xff7a766d)),
            ],
          ),
          Positioned(
            right: 0,
            top: -2,
            child: ico(
              'chevron-right',
              size: 18,
              color: const Color(0xffa57704),
            ),
          ),
        ],
      ),
    ),
    action,
    label: label,
    radius: 15,
  );
  Widget metric(String value, String label, String icon, Color bg, Color fg) =>
      uiBox(
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 31,
                height: 31,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: ico(icon, size: 19, color: fg),
              ),
              space(8),
              tx(value, size: 20.48, weight: FontWeight.w700, height: 1),
              space(3),
              tx(
                label,
                size: 10.88,
                color: const Color(0xff7a766d),
                height: 1.2,
              ),
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        radius: 14,
      );
  Widget searchRow(
    String hint, {
    String? filterLabel,
    VoidCallback? onFilter,
    VoidCallback? onAdd,
  }) => Row(
    children: [
      Expanded(
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xffdcd8cf)),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              ico('search', size: 18, color: const Color(0xff8a867d)),
              const SizedBox(width: 9),
              Expanded(
                child: TextField(
                  controller: search,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 13.12),
                  decoration: InputDecoration(
                    hintText: hint,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  textInputAction: TextInputAction.search,
                ),
              ),
            ],
          ),
        ),
      ),
      if (onAdd != null || onFilter != null) ...[
        const SizedBox(width: 9),
        Semantics(
          button: true,
          label: onAdd != null ? 'Nuevo cliente' : filterLabel ?? 'Filtrar',
          child: tap(
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: onAdd != null ? primaryGold : Colors.white,
                border: onAdd != null
                    ? null
                    : Border.all(color: const Color(0xffdcd8cf)),
                borderRadius: BorderRadius.circular(11),
              ),
              child: ico(
                onAdd != null ? 'plus' : 'list-filter',
                size: onAdd != null ? 24 : 19,
                color: onAdd != null ? Colors.white : const Color(0xff5f5c54),
              ),
            ),
            onAdd ?? onFilter,
          ),
        ),
      ],
    ],
  );
  Widget projects() {
    final q = search.text.trim().toLowerCase();
    final rows = c.projects
        .where(
          (p) =>
              ('${p['nombre']} ${p['ubicacion']}'.toLowerCase().contains(q)) &&
              (projectLocation.isEmpty || p['ubicacion'] == projectLocation),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        searchRow('Buscar proyecto', onFilter: filterProjects),
        sectionTitle(
          'Portafolio comercial',
          overline:
              '${rows.length} ${rows.length == 1 ? 'PROYECTO ACTIVO' : 'PROYECTOS ACTIVOS'}',
        ),
        for (final p in rows) ...[
          tap(
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xffdbd7ce)),
                borderRadius: BorderRadius.circular(17),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0f201c14),
                    blurRadius: 20,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: ColoredBox(
                      color: const Color(0xff23231f),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -74,
                            top: -85,
                            child: Transform.rotate(
                              angle: .524,
                              child: Container(
                                width: 190,
                                height: 190,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: gold.withValues(alpha: .45),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: -58,
                            bottom: -72,
                            child: Transform.rotate(
                              angle: .524,
                              child: Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: gold.withValues(alpha: .45),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 14,
                            left: 14,
                            child: Row(
                              children: [
                                ico(
                                  'sparkles',
                                  size: 15,
                                  color: const Color(0xfff3dda2),
                                ),
                                const SizedBox(width: 6),
                                tx(
                                  'Proyecto activo',
                                  size: 11.2,
                                  color: const Color(0xfff3dda2),
                                  weight: FontWeight.w700,
                                ),
                              ],
                            ),
                          ),
                          Center(
                            child: Transform.rotate(
                              angle: math.pi / 4,
                              child: Container(
                                width: 105,
                                height: 105,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0x6bd6a62d),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Transform.rotate(
                                  angle: -math.pi / 4,
                                  child: ico(
                                    'building-2',
                                    size: 54,
                                    color: const Color(0xffd6a62d),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 15,
                            bottom: 15,
                            child: Row(
                              children: [
                                ico(
                                  'map-pin',
                                  size: 15,
                                  color: const Color(0xffcbc7bd),
                                ),
                                const SizedBox(width: 5),
                                tx(
                                  '${p['ubicacion'] ?? ''}',
                                  size: 11.84,
                                  color: const Color(0xffcbc7bd),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              tx(
                                projectName(p['nombre']),
                                size: 17.6,
                                weight: FontWeight.w700,
                              ),
                              space(3),
                              tx('Lotes residenciales', size: 12, color: muted),
                            ],
                          ),
                        ),
                        ico(
                          'chevron-right',
                          size: 21,
                          color: const Color(0xff9c7104),
                        ),
                      ],
                    ),
                  ),
                  space(8),
                  Container(
                    decoration: const BoxDecoration(
                      border: PrototypeBorder(
                        top: BorderSide(color: Color(0xffebe8e1)),
                      ),
                    ),
                    child: Row(
                      children: [
                        for (final pair in [
                          (p['manzanas'] ?? 0, 'manzanas'),
                          (p['lotes'] ?? 0, 'lotes'),
                          (p['disponibles'] ?? 0, 'disponibles'),
                        ])
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              child: Column(
                                children: [
                                  tx(
                                    '${pair.$1}',
                                    size: 14.72,
                                    weight: FontWeight.w700,
                                  ),
                                  space(2),
                                  tx(pair.$2, size: 10.56, color: muted),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            () => run(() => c.selectProject(p)),
            label: projectName(p['nombre']),
            radius: 17,
          ),
          space(12),
        ],
        if (rows.isEmpty) empty('No se encontraron proyectos.'),
      ],
    );
  }

  Widget blocks() {
    final available = c.blocks.fold<num>(
      0,
      (a, b) => a + (b['disponibles'] as num? ?? 0),
    );
    final total = c.blocks.fold<num>(
      0,
      (a, b) => a + (b['total'] as num? ?? 0),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        uiBox(
          Row(
            children: [
              ico('map-pin', color: const Color(0xffa07508)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    tx(
                      '${c.project?['ubicacion'] ?? ''}',
                      size: 13.6,
                      weight: FontWeight.w700,
                    ),
                    space(2),
                    tx(
                      '$available de $total lotes disponibles',
                      size: 11.52,
                      color: const Color(0xff7c786f),
                    ),
                  ],
                ),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
        ),
        sectionTitle('Manzanas', overline: 'SELECCIÓN DE UBICACIÓN'),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 11,
            runSpacing: 11,
            children: [
              for (final b in c.blocks)
                SizedBox(
                  width: (constraints.maxWidth - 11) / 2,
                  child: tap(
                    uiBox(
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 94),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: charcoal,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: tx(
                                '${b['codigo']}',
                                size: 17.28,
                                color: const Color(0xffd6a62d),
                                weight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  tx(
                                    'Manzana ${b['codigo']}',
                                    size: 12.64,
                                    weight: FontWeight.w700,
                                  ),
                                  space(2),
                                  tx(
                                    '${b['total']} lotes',
                                    size: 10.88,
                                    color: const Color(0xff817d73),
                                  ),
                                  space(7),
                                  tx(
                                    '${b['disponibles']} disp.',
                                    size: 10.56,
                                    color: (b['disponibles'] as num? ?? 0) > 0
                                        ? const Color(0xff2d7041)
                                        : const Color(0xff8a867d),
                                    weight: FontWeight.w800,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(13),
                      line: b['codigo'] == 'B' ? gold : border,
                      color: b['codigo'] == 'B'
                          ? const Color(0xfffffaf0)
                          : Colors.white,
                      radius: 14,
                    ),
                    () => run(() => c.selectBlock(b)),
                    label: 'Manzana ${b['codigo']}',
                    radius: 14,
                  ),
                ),
            ],
          ),
        ),
        space(18),
        uiBox(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tx('Estados', size: 12.32, weight: FontWeight.w700),
              space(10),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  for (final row in [
                    ('Disponible', const Color(0xff2f8a4e)),
                    ('Reservado', const Color(0xff2c6da4)),
                    ('Vendido', const Color(0xffb36b1b)),
                    ('No disponible', const Color(0xff9a9a94)),
                  ])
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: row.$2,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        tx(row.$1, size: 10.72, color: const Color(0xff69665e)),
                      ],
                    ),
                ],
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
        ),
      ],
    );
  }

  Widget chipButton(String title, bool active, VoidCallback onTap) => Semantics(
    button: true,
    selected: active,
    label: title,
    child: tap(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? charcoal : Colors.white,
          border: Border.all(
            color: active ? charcoal : const Color(0xffdedad1),
          ),
          borderRadius: BorderRadius.circular(99),
        ),
        child: tx(
          title,
          size: 11.2,
          color: active ? Colors.white : const Color(0xff6d6961),
          weight: FontWeight.w700,
        ),
      ),
      onTap,
      radius: 99,
    ),
  );
  Widget lots() {
    final q = search.text.trim().toLowerCase();
    final rows = c.lots.where((l) {
      return '${l['codigo']}'.toLowerCase().contains(q) &&
          (chip != 'Disponibles' || l['estado'] == 'DISPONIBLE') &&
          (!['Parque', 'Avenida'].contains(chip) ||
              '${l['referencia'] ?? ''}'.toLowerCase().contains(
                chip.toLowerCase(),
              )) &&
          (filterState.isEmpty || l['estado'] == filterState) &&
          (filterLocation.isEmpty ||
              '${l['referencia'] ?? ''}'.toLowerCase().contains(
                filterLocation.toLowerCase(),
              )) &&
          (filterStage == null || l['etapa_id'] == filterStage);
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        searchRow(
          'Buscar número de lote',
          filterLabel: 'Filtrar lotes',
          onFilter: filterLots,
        ),
        space(12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final name in ['Todos', 'Disponibles', 'Parque', 'Avenida'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: chipButton(
                    name,
                    chip == name,
                    () => setState(() => chip = name),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(1, 12, 1, 9),
          child: Wrap(
            spacing: 12,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            children: [
              tx(
                '${rows.length} lotes mostrados',
                size: 11.84,
                weight: FontWeight.w700,
              ),
              tx(
                'Precio actualizado',
                size: 10.56,
                color: const Color(0xff7f7b72),
              ),
            ],
          ),
        ),
        for (final l in rows) ...[lotCard(l), space(9)],
        if (rows.isEmpty) empty('No se encontraron lotes para estos filtros.'),
      ],
    );
  }

  Widget lotCard(Data l) {
    final disabled = l['estado'] != 'DISPONIBLE';
    return Opacity(
      opacity: disabled ? .73 : 1,
      child: tap(
        uiBox(
          Row(
            children: [
              lotNumber(l),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: tx(
                            'Lote ${l['codigo']}',
                            size: 13.76,
                            weight: FontWeight.w700,
                          ),
                        ),
                        statusBadge(l['estado']),
                      ],
                    ),
                    space(5),
                    Row(
                      children: [
                        ico(
                          'map-pin',
                          size: 14,
                          color: const Color(0xff7d7970),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: tx(
                            '${l['referencia'] ?? l['etapa'] ?? ''} · ${num.tryParse('${l['area_m2']}')?.toStringAsFixed(2) ?? ''} m²',
                            size: 10.56,
                            color: const Color(0xff7d7970),
                          ),
                        ),
                      ],
                    ),
                    space(7),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        tx(
                          money(l['precio']),
                          size: 12.48,
                          weight: FontWeight.w700,
                        ),
                        tx(
                          'Inicial ${money(l['inicial'])}',
                          size: 9.76,
                          color: muted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!disabled) ...[
                const SizedBox(width: 8),
                ico('chevron-right'),
              ],
            ],
          ),
          padding: const EdgeInsets.all(11),
          color: disabled ? const Color(0xfff1f0ec) : Colors.white,
        ),
        disabled && !c.admin ? null : () => run(() => c.selectLot(l)),
        label: 'Lote ${l['codigo']}',
      ),
    );
  }

  Widget detail() {
    final l = c.lot!;
    final initial = num.tryParse('${plan['inicial'] ?? l['inicial']}') ?? 0;
    final price = num.tryParse('${l['precio']}') ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: charcoal,
            borderRadius: BorderRadius.circular(16),
            border: const PrototypeBorder(
              bottom: BorderSide(color: gold, width: 3),
            ),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        tx(
                          'MANZANA ${l['manzana']}',
                          size: 10.56,
                          color: const Color(0xffd4a731),
                          weight: FontWeight.w800,
                          spacing: 1.6,
                        ),
                        space(4),
                        tx(
                          'Lote $lotCode',
                          size: 28,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ],
                    ),
                  ),
                  statusBadge(l['estado']),
                ],
              ),
              space(17),
              Row(
                children: [
                  Expanded(
                    child: feature(
                      'map-pin',
                      'Ubicación',
                      '${l['referencia'] ?? l['etapa'] ?? ''}',
                    ),
                  ),
                  const SizedBox(width: 1),
                  Expanded(
                    child: feature('layout-grid', 'Área', '${l['area_m2']} m²'),
                  ),
                ],
              ),
            ],
          ),
        ),
        space(13),
        uiBox(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              eyebrow('PRECIO AL CONTADO'),
              space(5),
              Row(
                children: [
                  Expanded(
                    child: tx(
                      money(price),
                      size: 22.72,
                      weight: FontWeight.w700,
                      spacing: -.7,
                    ),
                  ),
                  ico('badge-check', size: 22, color: const Color(0xff2d7944)),
                ],
              ),
              space(13),
              const Divider(height: 1, color: Color(0xffebe8e1)),
              space(12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        tx(
                          'Inicial',
                          size: 10.56,
                          color: const Color(0xff7d7970),
                        ),
                        space(2),
                        tx(money(initial), size: 12.8, weight: FontWeight.w700),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(left: 14),
                      decoration: const BoxDecoration(
                        border: PrototypeBorder(
                          left: BorderSide(color: Color(0xffebe8e1)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          tx(
                            'Saldo',
                            size: 10.56,
                            color: const Color(0xff7d7970),
                          ),
                          space(2),
                          tx(
                            money(price - initial),
                            size: 12.8,
                            weight: FontWeight.w700,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          padding: const EdgeInsets.all(15),
          radius: 14,
        ),
        sectionTitle(
          'Planes de pago',
          action: 'Ver condiciones',
          onAction: conditions,
        ),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              for (final p in plans)
                SizedBox(
                  width: (constraints.maxWidth - 9) / 2,
                  child: tap(
                    uiBox(
                      Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              tx(
                                '${p['numero_cuotas']} meses',
                                size: 10.4,
                                color: const Color(0xff6e6a62),
                              ),
                              space(2),
                              tx(
                                money(p['monto_cuota']),
                                size: 13.28,
                                weight: FontWeight.w700,
                              ),
                              tx(
                                'cuota mensual',
                                size: 9.44,
                                color: const Color(0xff8a867d),
                              ),
                            ],
                          ),
                          if (p['id'] == plan['id'])
                            Positioned(
                              top: 0,
                              right: 0,
                              child: ico(
                                'check',
                                size: 15,
                                color: const Color(0xffa47502),
                              ),
                            ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 10,
                      ),
                      radius: 11,
                      color: p['id'] == plan['id']
                          ? const Color(0xfffff8e5)
                          : Colors.white,
                      line: p['id'] == plan['id']
                          ? const Color(0xffbf8c0d)
                          : border,
                    ),
                    () => setState(() => c.selectedPlan = p),
                    label: '${p['numero_cuotas']} meses',
                  ),
                ),
            ],
          ),
        ),
        space(18),
        Row(
          children: [
            Expanded(
              flex: 72,
              child: primary(
                'Ficha',
                () => go('commercial-sheet'),
                before: 'share-2',
                outline: true,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              flex: 128,
              child: primary(
                'Separar lote',
                l['estado'] == 'DISPONIBLE' && plans.isNotEmpty
                    ? newClient
                    : null,
                before: 'key-round',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget feature(String icon, String label, String value) => Container(
    padding: const EdgeInsets.all(11),
    color: const Color(0xff292924),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ico(icon, size: 18, color: const Color(0xffd4a731)),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tx(label, size: 9.76, color: const Color(0xffaaa79f)),
              space(1),
              tx(
                value,
                size: 12.16,
                color: Colors.white,
                weight: FontWeight.w700,
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget commercial() {
    final l = c.lot!,
        initial = num.tryParse('${plan['inicial']}') ?? 0,
        price = num.tryParse('${l['precio']}') ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(
          key: sheetKey,
          child: Container(
            color: const Color(0xffece9e1),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xffd7d2c8)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1a1f1b13),
                    blurRadius: 22,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: ink,
                      border: PrototypeBorder(
                        bottom: BorderSide(color: gold, width: 3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        brand(compact: true),
                        tx(
                          dateText(DateTime.now()),
                          size: 10.4,
                          color: const Color(0xffbdb9af),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        tx(
                          '${l['proyecto']} · ${l['ubicacion'] ?? ''}'
                              .toUpperCase(),
                          size: 10.4,
                          color: const Color(0xffa17300),
                          weight: FontWeight.w800,
                          spacing: 1.6,
                        ),
                        space(5),
                        tx(
                          'Manzana ${l['manzana']} · Lote $lotCode',
                          size: 20.8,
                          weight: FontWeight.w700,
                        ),
                        space(4),
                        tx(
                          '${l['etapa'] ?? ''} · ${l['referencia'] ?? ''} · ${l['area_m2']} m²',
                          size: 12.16,
                          color: muted,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xfffff6d9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        tx(
                          'Precio del lote',
                          size: 10.4,
                          color: const Color(0xff745c1d),
                        ),
                        space(3),
                        tx(
                          money(price),
                          size: 24.8,
                          weight: FontWeight.w700,
                          spacing: -.7,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: sheetValue('Inicial', money(initial))),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(left: 16),
                            decoration: const BoxDecoration(
                              border: PrototypeBorder(
                                left: BorderSide(color: Color(0xffe0ddd4)),
                              ),
                            ),
                            child: sheetValue('Saldo', money(price - initial)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    padding: const EdgeInsets.all(13),
                    decoration: const BoxDecoration(
                      color: charcoal,
                      border: PrototypeBorder(
                        left: BorderSide(color: gold, width: 3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              tx(
                                'PLAN SUGERIDO',
                                size: 9.6,
                                color: const Color(0xffd6aa39),
                                weight: FontWeight.w800,
                                spacing: 1.3,
                              ),
                              space(4),
                              tx(
                                '${plan['numero_cuotas']} cuotas de ${money(plan['monto_cuota'])}',
                                size: 13.12,
                                color: Colors.white,
                                weight: FontWeight.w700,
                              ),
                            ],
                          ),
                        ),
                        ico(
                          'calendar-days',
                          size: 27,
                          color: const Color(0xffd6aa39),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Row(
                      children: [
                        avatar(userName),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              tx('Tu asesor', size: 9.92, color: muted),
                              tx(
                                userName,
                                size: 12.48,
                                weight: FontWeight.w700,
                              ),
                              if ('${c.user?['phone'] ?? ''}'.isNotEmpty) ...[
                                space(3),
                                Row(
                                  children: [
                                    ico('phone', size: 13, color: muted),
                                    const SizedBox(width: 4),
                                    tx(
                                      '${c.user!['phone']}',
                                      size: 9.92,
                                      color: muted,
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    color: const Color(0xfff1f0ec),
                    child: tx(
                      'Información sujeta a actualización. La disponibilidad se confirma al registrar la separación.',
                      size: 9.6,
                      color: muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        space(15),
        primary(
          'Compartir por WhatsApp',
          () => shareBoundary(sheetKey, 'ficha_comercial.png', whatsapp: true),
          before: 'message-circle-more',
          color: const Color(0xff287a49),
        ),
      ],
    );
  }

  Widget sheetValue(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      tx(label, size: 10.4, color: muted),
      space(3),
      tx(value, size: 13.12, weight: FontWeight.w700),
    ],
  );
  Future<void> shareBoundary(
    GlobalKey key,
    String name, {
    bool whatsapp = false,
  }) => run(() async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) throw ApiException('No se pudo preparar la imagen.');
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) throw ApiException('No se pudo preparar la imagen.');
    await (whatsapp
        ? files.shareWhatsApp(data.buffer.asUint8List(), name, 'image/png')
        : files.shareFile(data.buffer.asUint8List(), name, 'image/png'));
    if (kIsWeb) {
      message(
        'Imagen preparada. Si tu navegador no permite compartir, adjunta la descarga en WhatsApp.',
      );
    }
  });
  Widget empty(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: tx(text, size: 13, color: muted, align: TextAlign.center),
  );
  //__PART2__
  Widget steps(int current) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 45),
      child: Stack(
        children: [
          const Positioned(
            left: 48,
            right: 48,
            top: 13,
            child: Divider(height: 1, color: Color(0xffd9d5cc)),
          ),
          Row(
            children: [
              for (int i = 1; i <= 4; i++)
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 27,
                        height: 27,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i <= current ? gold : const Color(0xffeceae4),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: i <= current
                                ? gold
                                : const Color(0xffd8d4cb),
                          ),
                        ),
                        child: i < current
                            ? ico('check', size: 13, color: Colors.white)
                            : tx(
                                '$i',
                                size: 10.4,
                                color: i <= current
                                    ? Colors.white
                                    : const Color(0xff949087),
                                weight: FontWeight.w800,
                              ),
                      ),
                      space(4),
                      tx(
                        ['Cliente', 'Documentos', 'Separación', 'Confirmar'][i -
                            1],
                        size: 8.8,
                        color: i <= current
                            ? const Color(0xff8f6806)
                            : const Color(0xff949087),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
  String? dniValidator(String? value) =>
      RegExp(r'^\d{8}$').hasMatch((value ?? '').trim())
      ? null
      : 'Ingresa un DNI de 8 dígitos.';
  String? phoneValidator(String? value) =>
      RegExp(r'^[0-9+ ()-]{6,25}$').hasMatch((value ?? '').trim())
      ? null
      : 'Ingresa un teléfono válido.';
  String? mailValidator(String? value) =>
      value == null ||
          value.trim().isEmpty ||
          RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())
      ? null
      : 'Revisa el correo.';
  Widget personFields({bool co = false}) {
    final n = co ? coNames : names,
        d = co ? coDocument : document,
        p = co ? coPhone : phone,
        a = co ? coAddress : address,
        m = co ? coMail : mail,
        o = co ? coOccupation : occupation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field('Nombres y apellidos', n, compact: true, required: true),
        space(12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: field(
                'DNI',
                d,
                compact: true,
                keyboard: TextInputType.number,
                validate: dniValidator,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: field(
                'Teléfono',
                p,
                compact: true,
                keyboard: TextInputType.phone,
                validate: phoneValidator,
              ),
            ),
          ],
        ),
        space(12),
        field('Dirección', a, compact: true),
        space(12),
        field(
          'Correo',
          m,
          compact: true,
          keyboard: TextInputType.emailAddress,
          validate: mailValidator,
        ),
        space(12),
        field('Ocupación', o, compact: true),
      ],
    );
  }

  Future<void> editCo() async {
    final key = GlobalKey<FormState>();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: paper,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(ctx).bottom + 20,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * .8,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sectionTitle('Datos del cotitular', top: 0),
                  infoNote(
                    'Usa los datos tal como aparecen en el DNI.',
                    compact: true,
                  ),
                  space(14),
                  TextButton(
                    onPressed: () => selectExistingCo(ctx),
                    child: const Text('Seleccionar cotitular registrado'),
                  ),
                  personFields(co: true),
                  space(18),
                  primary('Guardar cotitular', () {
                    if (key.currentState!.validate()) {
                      if (coDocument.text.trim() == document.text.trim()) {
                        message(
                          'El titular y cotitular deben tener un DNI diferente.',
                        );
                        return;
                      }
                      Navigator.pop(ctx, true);
                    }
                  }, after: 'check'),
                  space(6),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (mounted) {
      setState(() {
        if (saved != true && coNames.text.trim().isEmpty) withCo = false;
      });
    }
  }

  Data personInput({bool co = false}) => {
    'nombre': (co ? coNames : names).text.trim(),
    'tipo_documento': 'DNI',
    'numero_documento': (co ? coDocument : document).text.trim(),
    'telefono': (co ? coPhone : phone).text.trim(),
    'correo': (co ? coMail : mail).text.trim(),
    'direccion': (co ? coAddress : address).text.trim(),
    'ocupacion': (co ? coOccupation : occupation).text.trim(),
  };
  Widget clientForm() => Form(
    key: clientKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.lot != null) steps(1),
        sectionTitle(
          'Datos del titular',
          overline: c.lot == null ? 'REGISTRO COMERCIAL' : 'PASO 1 DE 4',
          top: 0,
        ),
        infoNote('Usa los datos tal como aparecen en el DNI.', compact: true),
        space(14),
        primary(
          'Seleccionar cliente existente',
          selectExistingClient,
          outline: true,
        ),
        space(14),
        personFields(),
        space(16),
        uiBox(
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    tx(
                      'Agregar cotitular',
                      size: 12.48,
                      weight: FontWeight.w700,
                    ),
                    space(2),
                    tx(
                      'Opcional para esta operación',
                      size: 10.4,
                      color: const Color(0xff817d74),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 36,
                height: 24,
                child: Transform.scale(
                  scale: .65,
                  child: Switch(
                    value: withCo,
                    activeThumbColor: Colors.white,
                    activeTrackColor: primaryGold,
                    inactiveTrackColor: const Color(0xffdad6cc),
                    onChanged: (v) {
                      setState(() => withCo = v);
                      if (v) editCo();
                    },
                  ),
                ),
              ),
            ],
          ),
          radius: 12,
        ),
        if (withCo) ...[
          space(9),
          tap(
            uiBox(
              Row(
                children: [
                  ico('users-round', size: 19, color: const Color(0xff735918)),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        tx(
                          coNames.text.trim().isEmpty
                              ? 'Datos del cotitular'
                              : coNames.text.trim(),
                          size: 11.52,
                          color: const Color(0xff735918),
                          weight: FontWeight.w700,
                        ),
                        space(2),
                        tx(
                          coDocument.text.trim().isEmpty
                              ? 'Se solicitarán sus datos y ambas caras del DNI.'
                              : 'DNI ${coDocument.text.trim()} · Editar datos',
                          size: 9.76,
                          color: const Color(0xff735918),
                        ),
                      ],
                    ),
                  ),
                  ico('check', size: 18, color: const Color(0xff735918)),
                ],
              ),
              color: const Color(0xfffff7de),
              line: const Color(0xffe8d28d),
              padding: const EdgeInsets.all(11),
              radius: 11,
            ),
            editCo,
          ),
        ],
        space(17),
        primary(
          c.lot == null ? 'Guardar cliente' : 'Continuar',
          () => run(() async {
            if (!clientKey.currentState!.validate()) return;
            if (withCo &&
                (coNames.text.trim().isEmpty ||
                    dniValidator(coDocument.text) != null ||
                    phoneValidator(coPhone.text) != null)) {
              await editCo();
              return;
            }
            if (c.projects.isEmpty) {
              throw ApiException('No hay proyectos registrados.');
            }
            await c.saveClient({
              ...personInput(),
              'proyecto_id':
                  c.selectedClient?['proyecto_id'] ??
                  c.project?['id'] ??
                  c.projects.first['id'],
              'quitar_cotitular':
                  !withCo && c.selectedClient?['cotitular'] != null,
              if (withCo) 'cotitular': personInput(co: true),
            });
          }),
          after: 'arrow-right',
        ),
      ],
    ),
  );
  Widget documents() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      steps(2),
      sectionTitle('Fotografías del DNI', overline: 'PASO 2 DE 4', top: 0),
      tx(
        'Verifica que los datos y la fotografía sean legibles antes de continuar.',
        size: 14.24,
        color: const Color(0xff716e66),
        height: 1.45,
      ),
      space(15),
      for (final group in [false, if (c.coClient != null) true])
        for (final side in ['ANVERSO', 'REVERSO']) ...[
          documentCard(group, side),
          space(9),
        ],
      if (c.coClient != null) ...[
        space(3),
        infoNote(
          'Al incluir cotitular se solicitan los documentos de ambas personas.',
          compact: true,
          icon: 'users-round',
        ),
      ],
      space(13),
      Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: charcoal,
          borderRadius: BorderRadius.circular(12),
          border: const PrototypeBorder(
            left: BorderSide(color: gold, width: 3),
          ),
        ),
        child: Row(
          children: [
            ico('camera', size: 26, color: const Color(0xffd1a12a)),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  tx(
                    'Buena captura',
                    size: 12,
                    color: Colors.white,
                    weight: FontWeight.w700,
                  ),
                  space(3),
                  tx(
                    'Documento completo, sin reflejos y con suficiente iluminación.',
                    size: 9.92,
                    color: const Color(0xffbbb8b0),
                    height: 1.35,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      space(17),
      primary('Continuar', () {
        final needed = [c.documents, if (c.coClient != null) c.coDocuments];
        if (needed.any(
          (group) =>
              !group.any((d) => d['lado'] == 'ANVERSO') ||
              !group.any((d) => d['lado'] == 'REVERSO'),
        )) {
          message('Completa ambas caras del DNI antes de continuar.');
          return;
        }
        go('separation');
      }, after: 'arrow-right'),
    ],
  );
  Widget documentCard(bool co, String side) {
    final uploaded = (co ? c.coDocuments : c.documents).any(
      (d) => d['lado'] == side,
    );
    final person = c.coClient == null
        ? ''
        : co
        ? ' cotitular'
        : ' titular';
    final label = 'DNI$person · ${side == 'ANVERSO' ? 'Anverso' : 'Reverso'}';
    return tap(
      uiBox(
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: uploaded
                    ? const Color(0xffdcefe1)
                    : const Color(0xfff1eee7),
                borderRadius: BorderRadius.circular(9),
              ),
              child: ico(
                uploaded ? 'check' : 'camera',
                size: 22,
                color: uploaded
                    ? const Color(0xff28713d)
                    : const Color(0xff9a7006),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  tx(label, size: 12, weight: FontWeight.w700),
                  space(3),
                  tx(
                    uploaded
                        ? 'Imagen cargada correctamente'
                        : 'Toca para tomar o elegir una foto',
                    size: 9.92,
                    color: const Color(0xff7d7970),
                  ),
                ],
              ),
            ),
            ico('chevron-right', size: 19, color: muted),
          ],
        ),
        padding: const EdgeInsets.all(12),
        color: uploaded ? const Color(0xfff3f8f4) : Colors.white,
        line: uploaded ? const Color(0xffbdd8c4) : const Color(0xffcfcac0),
        radius: 12,
      ),
      () => run(() async {
        final f = await files.pickImage();
        if (f == null) return;
        if (f.bytes.length > 5 * 1024 * 1024) {
          throw ApiException('Selecciona una imagen de hasta 5 MB.');
        }
        await c.upload(side, f.bytes, f.name, cotitular: co);
      }),
      label: label,
    );
  }

  Widget separation() {
    ensureDraftTerms();
    final l = c.lot!,
        price = c.agreedPrice ?? 0,
        initial = c.agreedInitial ?? 0;
    return Form(
      key: separationKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          steps(3),
          sectionTitle(
            'Condiciones acordadas',
            overline: 'PASO 3 DE 4',
            top: 0,
          ),
          uiBox(
            Row(
              children: [
                lotNumber(l, small: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      tx(projectTitle, size: 12.16, weight: FontWeight.w700),
                      space(3),
                      tx(
                        '${l['referencia'] ?? ''} · ${l['area_m2']} m²',
                        size: 10.08,
                        color: const Color(0xff7d7970),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                tx(money(price), size: 11.84, weight: FontWeight.w700),
              ],
            ),
            padding: const EdgeInsets.all(12),
            radius: 12,
          ),
          space(15),
          field(
            'Monto de separación',
            amount,
            required: true,
            keyboard: const TextInputType.numberWithOptions(decimal: true),
          ),
          space(15),
          field(
            'Plazo de separación (días)',
            deadlineDays,
            required: true,
            keyboard: TextInputType.number,
            validate: (v) => validateDeadline(
              v,
              num.tryParse(amount.text.replaceAll(',', '.')) ?? 0,
            ),
          ),
          space(6),
          tx(deadlinePreview(), size: 12, color: muted),
          space(15),
          tx(
            'Plan de financiamiento',
            size: 12.64,
            weight: FontWeight.w700,
            color: const Color(0xff3a3935),
          ),
          space(8),
          Row(
            children: [
              for (int i = 0; i < plans.length; i++) ...[
                if (i > 0) const SizedBox(width: 7),
                Expanded(
                  child: tap(
                    uiBox(
                      Column(
                        children: [
                          tx(
                            '${plans[i]['numero_cuotas']}',
                            size: 13.12,
                            weight: FontWeight.w700,
                            color: plans[i]['id'] == plan['id']
                                ? const Color(0xff7b5904)
                                : const Color(0xff55524b),
                          ),
                          tx(
                            'meses',
                            size: 9.12,
                            color: plans[i]['id'] == plan['id']
                                ? const Color(0xff7b5904)
                                : const Color(0xff55524b),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 9,
                      ),
                      radius: 9,
                      color: plans[i]['id'] == plan['id']
                          ? const Color(0xfffff6da)
                          : Colors.white,
                      line: plans[i]['id'] == plan['id']
                          ? primaryGold
                          : const Color(0xffd8d4cb),
                    ),
                    () => setState(() {
                      c.selectedPlan = plans[i];
                      resetDraftPlan();
                    }),
                    label: '${plans[i]['numero_cuotas']} meses',
                  ),
                ),
              ],
            ],
          ),
          space(14),
          negotiatedFields(),
          space(14),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xffdedad1)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  paymentRow('Precio del lote', money(price)),
                  paymentRow('Inicial', money(initial)),
                  paymentRow('Saldo financiado', money(price - initial)),
                  paymentRow(
                    'Cuota mensual',
                    money(draftMonthly),
                    highlight: true,
                  ),
                ],
              ),
            ),
          ),
          space(14),
          field('Observación (opcional)', observation, lines: 3),
          space(17),
          primary('Revisar separación', () {
            if (!separationKey.currentState!.validate()) return;
            final value = num.tryParse(amount.text.replaceAll(',', '.'));
            if (value == null || value <= 0 || value > price) {
              message('Ingresa un monto mayor que cero y dentro del precio.');
              return;
            }
            if (!validDraftTerms()) {
              message('Revisa precio, inicial y número de cuotas (1 a 600).');
              return;
            }
            if (c.selectedPlan == null) {
              message('Selecciona un plan vigente.');
              return;
            }
            setState(() => confirmed = false);
            go('review');
          }, after: 'arrow-right'),
        ],
      ),
    );
  }

  Widget paymentRow(String label, String value, {bool highlight = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xfffff5d5) : Colors.white,
          border: highlight
              ? null
              : const PrototypeBorder(
                  bottom: BorderSide(color: Color(0xffeeeae3)),
                ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            tx(label, size: 10.56, color: muted),
            tx(
              value,
              size: highlight ? 13.76 : 11.52,
              weight: FontWeight.w700,
              color: highlight ? const Color(0xff805d05) : ink,
            ),
          ],
        ),
      );
  Widget summaryRow(String icon, String label, String value, String hint) =>
      Container(
        padding: const EdgeInsets.all(13),
        decoration: const BoxDecoration(
          border: PrototypeBorder(bottom: BorderSide(color: Color(0xffebe8e1))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xfffff1c9),
                borderRadius: BorderRadius.circular(9),
              ),
              child: ico(icon, size: 19, color: const Color(0xff9a6e02)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  tx(label, size: 9.76, color: const Color(0xff837f76)),
                  space(2),
                  tx(value, size: 12, weight: FontWeight.w700),
                  space(2),
                  tx(hint, size: 10.24, color: muted),
                ],
              ),
            ),
          ],
        ),
      );
  Widget review() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      steps(4),
      sectionTitle('Resumen de la operación', overline: 'PASO 4 DE 4', top: 0),
      uiBox(
        Column(
          children: [
            summaryRow(
              'house',
              'Lote',
              '$projectTitle · MZ ${c.lot?['manzana']} · Lote $lotCode',
              '${c.lot?['referencia'] ?? ''} · ${c.lot?['area_m2']} m²',
            ),
            summaryRow(
              'user-round',
              'Titular',
              '${c.selectedClient?['nombre']}',
              'DNI ${c.selectedClient?['numero_documento']} · ${c.selectedClient?['telefono'] ?? ''}',
            ),
            if (c.coClient != null)
              summaryRow(
                'users-round',
                'Cotitular',
                '${c.coClient!['nombre']}',
                'DNI ${c.coClient!['numero_documento']} · documentos completos',
              ),
            summaryRow(
              'wallet-cards',
              'Condiciones',
              '${money(amount.text.replaceAll(',', '.'))} de separación',
              'Inicial ${money(c.agreedInitial ?? plan['inicial'])} · ${c.agreedCount ?? plan['numero_cuotas']} cuotas de ${money(draftMonthly)}',
            ),
          ],
        ),
        padding: EdgeInsets.zero,
        radius: 14,
      ),
      space(13),
      uiBox(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ico('shield-check', color: const Color(0xff735a18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  tx(
                    'Validación final',
                    size: 11.68,
                    color: const Color(0xff735a18),
                    weight: FontWeight.w700,
                  ),
                  space(3),
                  tx(
                    'Al confirmar, el lote cambiará de Disponible a Reservado.',
                    size: 10.24,
                    color: const Color(0xff735a18),
                    height: 1.4,
                  ),
                ],
              ),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        radius: 11,
        color: const Color(0xfffff7df),
        line: const Color(0xffe6cc79),
      ),
      space(13),
      Semantics(
        label: 'Confirmo que los datos fueron revisados con el cliente.',
        checked: confirmed,
        child: InkWell(
          onTap: () => setState(() => confirmed = !confirmed),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 20,
                height: 22,
                child: Checkbox(
                  value: confirmed,
                  activeColor: primaryGold,
                  visualDensity: VisualDensity.compact,
                  onChanged: (v) => setState(() => confirmed = v ?? false),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: tx(
                  'Confirmo que los datos fueron revisados con el cliente.',
                  size: 10.88,
                  color: const Color(0xff5c5952),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
      space(17),
      primary(
        'Confirmar separación',
        confirmed
            ? () => run(
                () => c.reserve(
                  num.parse(amount.text.replaceAll(',', '.')),
                  observation.text.trim(),
                  days: int.tryParse(deadlineDays.text),
                ),
              )
            : null,
        before: 'key-round',
      ),
      space(5),
      TextButton(
        onPressed: () => go('separation'),
        child: tx('Editar información', size: 11.52, color: muted),
      ),
    ],
  );
  String reservationCode(Data r) {
    final d = when(r['fecha_registro']);
    return 'SEP-${d.year}-${'${r['id']}'.padLeft(4, '0')}';
  }

  Widget receiptRow(String label, Widget value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: const BoxDecoration(
      border: PrototypeBorder(bottom: BorderSide(color: Color(0xffeeeae3))),
    ),
    child: Row(
      children: [
        Expanded(child: tx(label, size: 10.4, color: muted)),
        const SizedBox(width: 10),
        Flexible(flex: 2, child: value),
      ],
    ),
  );
  Widget success() {
    final r = c.result ?? <String, dynamic>{};
    return SingleChildScrollView(
      key: const ValueKey('success-scroll'),
      padding: const EdgeInsets.fromLTRB(25, 22, 25, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RepaintBoundary(
            key: receiptKey,
            child: ColoredBox(
              color: paper,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      brand(compact: true),
                      tx(
                        'Separación registrada',
                        size: 10.56,
                        color: const Color(0xff79756d),
                      ),
                    ],
                  ),
                  space(34),
                  Container(
                    width: 88,
                    height: 88,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xffdaf0df),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xffedf8ef),
                        width: 8,
                      ),
                    ),
                    child: ico(
                      'check',
                      size: 42,
                      color: const Color(0xff287541),
                    ),
                  ),
                  space(17),
                  eyebrow('OPERACIÓN EXITOSA'),
                  space(5),
                  tx(
                    '¡Lote reservado!',
                    size: 28.8,
                    height: 1.2,
                    spacing: -1.1,
                    align: TextAlign.center,
                  ),
                  space(5),
                  tx(
                    'La disponibilidad del lote se actualizó correctamente.',
                    size: 12.48,
                    color: const Color(0xff747169),
                    align: TextAlign.center,
                  ),
                  space(23),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: PrototypeBorder(
                        top: BorderSide(color: gold, width: 3),
                        left: BorderSide(color: Color(0xffdad6cd)),
                        right: BorderSide(color: Color(0xffdad6cd)),
                        bottom: BorderSide(color: Color(0xffdad6cd)),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x0f1f1b13),
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        for (final pair in [
                          ('Código', reservationCode(r)),
                          ('Proyecto', projectTitle),
                          ('Lote', lotSubtitle),
                          ('Cliente', '${c.selectedClient?['nombre'] ?? ''}'),
                          ('Monto', money(r['monto'])),
                        ])
                          receiptRow(
                            pair.$1,
                            tx(
                              pair.$2,
                              size: 11.36,
                              weight: FontWeight.w700,
                              align: TextAlign.right,
                            ),
                          ),
                        receiptRow(
                          'Estado',
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xffe5f2e8),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: tx(
                              'Reservado',
                              size: 11.36,
                              color: const Color(0xff2b6b3d),
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  space(13),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ico('clock-3', size: 15, color: const Color(0xff827e75)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: tx(
                          'Registrado el ${dateText(when(r['fecha_registro']))} a las ${timeText(when(r['fecha_registro']))}',
                          size: 9.92,
                          color: const Color(0xff827e75),
                          align: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  space(16),
                ],
              ),
            ),
          ),
          primary(
            'Compartir constancia',
            () => shareBoundary(receiptKey, 'constancia_${r['id']}.png'),
            before: 'share-2',
          ),
          space(9),
          primary('Volver al inicio', () {
            c.lot = null;
            go('home');
          }, outline: true),
        ],
      ),
    );
  }

  bool hasReservation(Data client) =>
      clientOperations(client).any((r) => r['estado'] == 'ACTIVA');
  List<Data> clientOperations(Data client) => client['operaciones'] is List
      ? cv.CasaController.rows(client['operaciones'])
      : c.reservations
            .where(
              (r) =>
                  r['cliente_id'] == client['id'] ||
                  r['cotitular_id'] == client['id'],
            )
            .toList();
  Widget clients() {
    final q = search.text.trim().toLowerCase();
    final assigned = c.listedClients
        .where(
          (p) => '${p['nombre']} ${p['numero_documento']} ${p['telefono']}'
              .toLowerCase()
              .contains(q),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        searchRow(
          'Nombre, DNI o teléfono',
          onAdd: () {
            c.lot = null;
            newClient();
          },
        ),
        space(12),
        clientFilterControls(),
        sectionTitle(
          '${assigned.length} clientes',
          overline: monthLabel(c.clientMonth).toUpperCase(),
        ),
        for (int i = 0; i < assigned.length; i++) ...[
          tap(
            uiBox(
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == 0
                          ? const Color(0xfff6e9ba)
                          : const Color(0xffe8e6df),
                      shape: BoxShape.circle,
                    ),
                    child: tx(
                      '${assigned[i]['nombre']}'
                          .split(' ')
                          .where((x) => x.isNotEmpty)
                          .take(2)
                          .map((x) => x[0])
                          .join()
                          .toUpperCase(),
                      size: 11.36,
                      color: i == 0
                          ? const Color(0xff7b5a05)
                          : const Color(0xff5d5a53),
                      weight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        tx(
                          '${assigned[i]['nombre']}',
                          size: 12.16,
                          weight: FontWeight.w700,
                        ),
                        space(2),
                        tx(
                          '${assigned[i]['tipo_documento']} ${i == 0 ? assigned[i]['numero_documento'] : '••••${'${assigned[i]['numero_documento']}'.substring(math.max(0, '${assigned[i]['numero_documento']}'.length - 4))}'} · ${assigned[i]['telefono'] ?? ''}',
                          size: 9.76,
                          color: const Color(0xff7b776e),
                        ),
                        space(2),
                        tx(
                          hasReservation(assigned[i])
                              ? 'Separación activa'
                              : hasSale(assigned[i])
                              ? 'Venta registrada'
                              : 'Cliente potencial',
                          size: 9.6,
                          color: const Color(0xff2f7042),
                          weight: FontWeight.w700,
                        ),
                      ],
                    ),
                  ),
                  ico(
                    'chevron-right',
                    size: 19,
                    color: const Color(0xff9a968d),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(11),
              radius: 12,
            ),
            () => clientProfile(assigned[i]),
            label: 'Cliente ${assigned[i]['nombre']}',
          ),
          space(9),
        ],
        if (assigned.isEmpty) empty('No se encontraron clientes.'),
      ],
    );
  }

  Widget reservations() {
    final all = c.listedOperations;
    final active = all.where((r) => r['estado'] == 'ACTIVA').toList();
    final q = search.text.trim().toLowerCase();
    final rows = all
        .where(
          (r) => '${r['proyecto']} ${r['manzana']} ${r['lote']} ${r['cliente']}'
              .toLowerCase()
              .contains(q),
        )
        .toList();
    final saleOnly = c.operationState == 'CONFIRMADA';
    final total = (saleOnly ? all : active).fold<num>(
      0,
      (a, b) =>
          a +
          (num.tryParse('${saleOnly ? b['precio_final'] : b['monto']}') ?? 0),
    );
    final summary =
        '${all.length} ${switch (c.operationState) {
          'ACTIVA' => 'separaciones',
          'CONFIRMADA' => 'ventas',
          'LIBERADA' => 'liberadas',
          _ => 'operaciones',
        }}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: charcoal,
            borderRadius: BorderRadius.circular(15),
            border: const PrototypeBorder(
              left: BorderSide(color: gold, width: 3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    eyebrow(
                      monthLabel(c.operationMonth).toUpperCase(),
                      golden: true,
                    ),
                    space(5),
                    tx(summary, size: 16, color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              tx(
                money(total),
                size: 16,
                color: const Color(0xffe0ba51),
                weight: FontWeight.w800,
              ),
            ],
          ),
        ),
        space(12),
        searchRow('Proyecto, lote o cliente'),
        space(10),
        filterSummary(
          operationStateLabel(c.operationState),
          c.operationMonth,
          operationFilters,
        ),
        space(16),
        for (int i = 0; i < rows.length; i++) ...[
          tap(
            uiBox(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      statusBadge(
                        rows[i]['estado'] == 'CONFIRMADA'
                            ? 'VENDIDO'
                            : rows[i]['estado'],
                      ),
                      tx(
                        reservationCode(rows[i]),
                        size: 9.6,
                        color: const Color(0xff8a867d),
                      ),
                    ],
                  ),
                  space(10),
                  tx(
                    '${projectName(rows[i]['proyecto'])} · MZ ${rows[i]['manzana']} · Lote ${'${rows[i]['lote']}'.padLeft(2, '0')}',
                    size: 12.64,
                    weight: FontWeight.w700,
                  ),
                  space(5),
                  Row(
                    children: [
                      ico('user-round', size: 15, color: muted),
                      const SizedBox(width: 5),
                      Expanded(
                        child: tx(
                          '${rows[i]['cliente']}',
                          size: 10.4,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                  space(11),
                  const Divider(height: 1, color: Color(0xffebe8e1)),
                  space(10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            tx(
                              rows[i]['estado'] == 'CONFIRMADA'
                                  ? 'Precio de venta'
                                  : 'Separación',
                              size: 9.28,
                              color: const Color(0xff858178),
                            ),
                            space(2),
                            tx(
                              money(
                                rows[i]['estado'] == 'CONFIRMADA'
                                    ? rows[i]['precio_final']
                                    : rows[i]['monto'],
                              ),
                              size: 10.88,
                              weight: FontWeight.w700,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            tx(
                              'Registrado',
                              size: 9.28,
                              color: const Color(0xff858178),
                            ),
                            space(2),
                            tx(
                              displayDate(
                                rows[i]['estado'] == 'CONFIRMADA'
                                    ? rows[i]['fecha_venta']
                                    : [
                                        'ANULADA',
                                        'VENCIDA',
                                      ].contains(rows[i]['estado'])
                                    ? rows[i]['fecha_liberacion'] ??
                                          rows[i]['fecha_registro']
                                    : rows[i]['fecha_registro'],
                              ),
                              size: 10.88,
                              weight: FontWeight.w700,
                            ),
                          ],
                        ),
                      ),
                      ico('chevron-right', color: const Color(0xff9a7006)),
                    ],
                  ),
                ],
              ),
              line: i == 0 ? const Color(0xffd6b65c) : border,
            ),
            () => reservationDetail(rows[i]),
          ),
          space(10),
        ],
        if (rows.isEmpty) empty('No hay operaciones con este filtro.'),
      ],
    );
  }

  Future<void> conditions() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: paper,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sectionTitle('Condiciones del plan', top: 0),
            tx(
              '${plan['numero_cuotas']} cuotas mensuales de ${money(plan['monto_cuota'])}.',
              weight: FontWeight.w700,
            ),
            space(12),
            tx(
              'Inicial: ${money(plan['inicial'])}. El monto de separación se registra por separado. La disponibilidad se confirma al registrar la operación.',
              size: 13,
              color: muted,
            ),
            space(18),
            primary('Entendido', () => Navigator.pop(ctx)),
          ],
        ),
      ),
    );
  }

  Future<void> filterProjects() async {
    String value = projectLocation;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: paper,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              sectionTitle('Filtrar proyectos', top: 0),
              DropdownButtonFormField<String>(
                initialValue: value,
                decoration: const InputDecoration(labelText: 'Ubicación'),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Todas las ubicaciones'),
                  ),
                  for (final loc
                      in c.projects
                          .map((p) => '${p['ubicacion'] ?? ''}')
                          .where((v) => v.isNotEmpty)
                          .toSet())
                    DropdownMenuItem(value: loc, child: Text(loc)),
                ],
                onChanged: (v) => update(() => value = v ?? ''),
              ),
              space(18),
              primary('Aplicar filtros', () {
                setState(() => projectLocation = value);
                Navigator.pop(ctx);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> filterLots() async {
    String state = filterState, location = filterLocation;
    int? stage = filterStage;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: paper,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              sectionTitle('Filtrar lotes', top: 0),
              DropdownButtonFormField<String>(
                initialValue: state,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Todos los estados'),
                  ),
                  for (final s in [
                    'DISPONIBLE',
                    'RESERVADO',
                    'VENDIDO',
                    'NO_DISPONIBLE',
                  ])
                    DropdownMenuItem(value: s, child: Text(stateLabel(s))),
                ],
                onChanged: (v) => update(() => state = v ?? ''),
              ),
              space(14),
              DropdownButtonFormField<String>(
                initialValue: location,
                decoration: const InputDecoration(labelText: 'Ubicación'),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Todas las ubicaciones'),
                  ),
                  for (final l
                      in c.lots
                          .map((l) => '${l['referencia'] ?? ''}')
                          .where((v) => v.isNotEmpty)
                          .toSet())
                    DropdownMenuItem(value: l, child: Text(l)),
                ],
                onChanged: (v) => update(() => location = v ?? ''),
              ),
              space(14),
              DropdownButtonFormField<int>(
                initialValue: stage ?? 0,
                decoration: const InputDecoration(labelText: 'Etapa'),
                items: [
                  const DropdownMenuItem(
                    value: 0,
                    child: Text('Todas las etapas'),
                  ),
                  for (final s in c.stages)
                    DropdownMenuItem(
                      value: (s['id'] as num).toInt(),
                      child: Text('${s['nombre']}'),
                    ),
                ],
                onChanged: (v) => update(() => stage = v == 0 ? null : v),
              ),
              space(18),
              primary('Aplicar filtros', () {
                setState(() {
                  filterState = state;
                  filterLocation = location;
                  filterStage = stage;
                });
                Navigator.pop(ctx);
              }),
              TextButton(
                onPressed: () {
                  setState(() {
                    filterState = '';
                    filterLocation = '';
                    filterStage = null;
                    chip = 'Todos';
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Limpiar filtros'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> clientProfile(Data input) => extendedClientProfile(input);
  Future<void> reservationDetail(Data r) => openOperation(r);

  Future<String?> reason(String title) async {
    final input = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: input,
          maxLength: 180,
          decoration: const InputDecoration(labelText: 'Motivo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (input.text.trim().isNotEmpty) {
                Navigator.pop(ctx, input.text.trim());
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    input.dispose();
    return result;
  }

  Future<void> release(Data r) => run(() async {
    final why = await reason('Liberar ${reservationCode(r)}');
    if (why == null) return;
    await c.api.call('POST', '/reservations/${r['id']}/release', {
      'estado': 'DISPONIBLE',
      'motivo': why,
    });
    await c.refresh();
    if (c.operation?['id'] == r['id']) {
      c.operation = Data.from(
        await c.api.call('GET', '/operations/${r['id']}'),
      );
    }
  });
  Future<void> reassign(Data r) => run(() async {
    final options = cv.CasaController.rows(
      await c.api.call('GET', '/lots?state=DISPONIBLE'),
    ).where((l) => l['proyecto'] == r['proyecto']).toList();
    if (!mounted) return;
    final selected = await showDialog<Data>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Nuevo lote disponible'),
        children: [
          for (final l in options)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, l),
              child: Text('${l['proyecto']} · ${l['manzana']}-${l['codigo']}'),
            ),
          if (options.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No hay lotes disponibles.'),
            ),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    final why = await reason('Motivo de reasignación');
    if (why == null) return;
    await c.api.call('POST', '/reservations/${r['id']}/reassign', {
      'lote_id': selected['id'],
      'motivo': why,
    });
    await c.refresh();
    if (c.operation?['id'] == r['id']) {
      c.operation = Data.from(
        await c.api.call('GET', '/operations/${r['id']}'),
      );
    }
  });
  Future<void> sell(Data r) => sellOperation(r);

  Future<void> adminState() => run(() async {
    final l = c.lot!;
    final next = l['estado'] == 'DISPONIBLE' ? 'NO_DISPONIBLE' : 'DISPONIBLE';
    final why = await reason(
      next == 'NO_DISPONIBLE' ? 'Deshabilitar lote' : 'Reactivar lote',
    );
    if (why == null) return;
    await c.api.call('PATCH', '/lots/${l['id']}/state', {
      'estado': next,
      'motivo': why,
    });
    await c.selectLot(l);
  });
  Future<void> showHistory() => run(() async {
    final rows = cv.CasaController.rows(
      await c.api.call('GET', '/lots/${c.lot!['id']}/history'),
    );
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: paper,
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sectionTitle('Historial del lote', top: 0),
            if (rows.isEmpty)
              tx('Todavía no hay cambios registrados.', size: 13, color: muted),
            for (final row in rows) ...[
              tx(
                '${stateLabel(row['estado_anterior'])} → ${stateLabel(row['estado_nuevo'])}',
                weight: FontWeight.w700,
              ),
              space(5),
              tx('${row['motivo']}', size: 12, color: muted),
              tx(
                '${dateText(when(row['fecha_cambio']))} · ${row['usuario']}',
                size: 11,
                color: muted,
              ),
              space(16),
            ],
          ],
        ),
      ),
    );
  });
}
