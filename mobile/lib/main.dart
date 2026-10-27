import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'platform_io.dart';
import 'api.dart';
import 'controller.dart' as cv;

const ink = Color(0xff171714),
    gold = Color(0xffc79517),
    paper = Color(0xfff7f6f2),
    muted = Color(0xff6f6c63);
typedef Data = Map<String, dynamic>;
String money(dynamic value) =>
    'S/ ${(num.tryParse('$value') ?? 0).toStringAsFixed(2)}';
String stateLabel(dynamic s) =>
    const {
      'DISPONIBLE': 'Disponible',
      'RESERVADO': 'Reservado',
      'VENDIDO': 'Vendido',
      'NO_DISPONIBLE': 'No disponible',
      'ACTIVA': 'Activa',
      'ANULADA': 'Anulada',
      'CONFIRMADA': 'Confirmada',
    }[s] ??
    '$s';
void main() {
  runApp(const CasaVipApp());
}

class CasaVipApp extends StatelessWidget {
  final ApiClient? api;
  const CasaVipApp({super.key, this.api});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CASA VIP',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: gold,
        primary: gold,
        surface: paper,
      ),
      scaffoldBackgroundColor: const Color(0xffe8e4dc),
      fontFamily: 'Arial',
      appBarTheme: const AppBarTheme(
        backgroundColor: ink,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffdedbd2)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
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
  final email = TextEditingController(),
      password = TextEditingController(),
      server = TextEditingController();
  final names = TextEditingController(),
      surnames = TextEditingController(),
      document = TextEditingController(),
      phone = TextEditingController(),
      mail = TextEditingController();
  final amount = TextEditingController(text: '500'),
      observation = TextEditingController(),
      search = TextEditingController();
  final loginKey = GlobalKey<FormState>(),
      clientKey = GlobalKey<FormState>(),
      separationKey = GlobalKey<FormState>();
  bool busy = false, confirmed = false;
  String type = 'DNI', filter = '';
  Uint8List? card;
  @override
  void initState() {
    super.initState();
    const configured = String.fromEnvironment('API_URL');
    String base = configured.isNotEmpty
        ? configured
        : (kIsWeb ? Uri.base.origin : 'http://10.0.2.2:8080');
    c = cv.CasaController(widget.api ?? ApiClient(base));
    server.text = c.api.baseUrl;
  }

  @override
  void dispose() {
    for (final f in [
      email,
      password,
      server,
      names,
      surnames,
      document,
      phone,
      mail,
      amount,
      observation,
      search,
    ]) {
      f.dispose();
    }
    c.dispose();
    super.dispose();
  }

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        if (e is ApiException && e.status == 401 && c.screen != 'login') {
          c.clear();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void go(String s) {
    search.clear();
    filter = '';
    c.go(s);
  }

  void back() {
    go(switch (c.screen) {
      'blocks' => 'projects',
      'lots' => 'blocks',
      'lot-detail' => 'lots',
      'commercial-sheet' => 'lot-detail',
      'client-form' => 'lot-detail',
      'documents' => 'client-form',
      'separation' => 'documents',
      'review' => 'separation',
      _ => 'home',
    });
  }

  Widget title(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 14, top: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
    ),
  );
  Widget note(String text, {IconData icon = Icons.shield_outlined}) =>
      Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xffeef4ef),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 19, color: const Color(0xff396046)),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Color(0xff396046),
                ),
              ),
            ),
          ],
        ),
      );
  Widget box(Widget child, {Color? color}) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color ?? Colors.white,
      border: Border.all(color: const Color(0xffdedbd2)),
      borderRadius: BorderRadius.circular(13),
    ),
    child: child,
  );
  Widget field(
    String label,
    TextEditingController controller, {
    bool mandatory = true,
    bool obscure = false,
    TextInputType? keyboard,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      obscureText: obscure,
      maxLines: lines,
      keyboardType: keyboard,
      validator: mandatory
          ? (v) => v == null || v.trim().isEmpty ? 'Completa este campo.' : null
          : null,
      decoration: InputDecoration(labelText: label),
    ),
  );
  Widget button(String text, VoidCallback? action, {IconData? icon}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: FilledButton(
      onPressed: busy ? null : action,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 19)],
        ],
      ),
    ),
  );
  Widget pair(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: muted, fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ],
    ),
  );
  Widget badge(dynamic state) {
    final label = stateLabel(state);
    final color = state == 'DISPONIBLE' || state == 'ACTIVA'
        ? const Color(0xff287541)
        : state == 'RESERVADO'
        ? const Color(0xff9a7006)
        : state == 'VENDIDO' || state == 'CONFIRMADA'
        ? const Color(0xffa03932)
        : muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget brand({double height = 70}) => Image.asset(
    'assets/casa-vip-logo.png',
    height: height,
    fit: BoxFit.contain,
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, size) {
          final desktop = size.maxWidth > 600;
          return Center(
            child: Padding(
              padding: EdgeInsets.all(desktop ? 18 : 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(desktop ? 24 : 0),
                child: SizedBox(
                  width: 430,
                  height: desktop
                      ? math.min(900, size.maxHeight - 36)
                      : size.maxHeight,
                  child: AnimatedBuilder(
                    animation: c,
                    builder: (context, _) => ColoredBox(
                      color: paper,
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              if (c.screen != 'login') header(),
                              Expanded(
                                child: ListView(
                                  key: ValueKey(c.screen),
                                  padding: c.screen == 'login'
                                      ? EdgeInsets.zero
                                      : const EdgeInsets.fromLTRB(
                                          20,
                                          18,
                                          20,
                                          25,
                                        ),
                                  children: [body()],
                                ),
                              ),
                              if (c.screen != 'login' && c.screen != 'success')
                                nav(),
                            ],
                          ),
                          if (busy)
                            const Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: LinearProgressIndicator(color: gold),
                            ),
                          if (busy)
                            const Positioned.fill(
                              child: AbsorbPointer(
                                child: ColoredBox(color: Color(0x08ffffff)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
  Widget header() {
    final labels = {
      'home': 'Hola, ${c.user?['name'] ?? ''}',
      'projects': 'Proyectos',
      'blocks': 'Manzanas',
      'lots': 'Lotes',
      'lot-detail': 'Detalle del lote',
      'commercial-sheet': 'Ficha comercial',
      'client-form': 'Registro de cliente',
      'documents': 'Documentos del cliente',
      'separation': 'Datos de separación',
      'review': 'Confirmar separación',
      'success': 'Operación registrada',
      'clients': 'Clientes',
      'reservations': 'Separaciones',
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 14, 15),
      decoration: const BoxDecoration(
        color: ink,
        border: Border(bottom: BorderSide(color: gold, width: 3)),
      ),
      child: Row(
        children: [
          if (![
            'home',
            'projects',
            'clients',
            'reservations',
          ].contains(c.screen))
            IconButton(
              tooltip: 'Volver',
              onPressed: back,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: brand(height: 32),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  labels[c.screen] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  c.user?['role'] == 'ASESOR'
                      ? 'Asesor comercial'
                      : c.user?['role'] == 'ADMINISTRADOR'
                      ? 'Administrador'
                      : 'Responsable comercial',
                  style: const TextStyle(
                    color: Color(0xffb9b6ae),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => run(c.logout),
            icon: const Icon(Icons.logout, color: gold, size: 21),
          ),
        ],
      ),
    );
  }

  Widget nav() {
    const pages = ['home', 'projects', 'clients', 'reservations'];
    int index = pages.indexOf(c.screen);
    if (index < 0) index = 1;
    return NavigationBar(
      height: 70,
      selectedIndex: index,
      indicatorColor: const Color(0xfff5e8bb),
      backgroundColor: Colors.white,
      onDestinationSelected: (i) => run(() async {
        if (i == 2 || i == 3) {
          await c.refresh();
        }
        if (i == 2) c.lot = null;
        go(pages[i]);
      }),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
        NavigationDestination(icon: Icon(Icons.apartment), label: 'Proyectos'),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          label: 'Clientes',
        ),
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          label: 'Separaciones',
        ),
      ],
    );
  }

  Widget body() => switch (c.screen) {
    'login' => login(),
    'home' => home(),
    'projects' => projects(),
    'blocks' => blocks(),
    'lots' => lots(),
    'lot-detail' => detail(),
    'commercial-sheet' => commercialCard(),
    'client-form' => clientForm(),
    'documents' => documents(),
    'separation' => separation(),
    'review' => review(),
    'success' => success(),
    'clients' => clients(),
    'reservations' => reservations(),
    _ => const SizedBox.shrink(),
  };
  Widget login() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.fromLTRB(30, 38, 30, 28),
        color: ink,
        child: Column(
          children: [
            brand(height: 100),
            const SizedBox(height: 20),
            const Text(
              'Información de lotes y separaciones, lista para atender al cliente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xffd5d1c7),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(25),
        child: Form(
          key: loginKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ACCESO DEL EQUIPO COMERCIAL',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xff9a7006),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              title('Bienvenido'),
              const Padding(
                padding: EdgeInsets.only(bottom: 22),
                child: Text(
                  'Ingresa para consultar precios, clientes y disponibilidad.',
                  style: TextStyle(color: muted, fontSize: 13, height: 1.5),
                ),
              ),
              field(
                'Correo corporativo',
                email,
                keyboard: TextInputType.emailAddress,
              ),
              field('Contraseña', password, obscure: true),
              button(
                'Ingresar',
                () => run(() async {
                  if (loginKey.currentState!.validate()) {
                    c.api.baseUrl = server.text.trim();
                    await c.login(email.text.trim(), password.text);
                  }
                }),
                icon: Icons.arrow_forward,
              ),
              note('Acceso seguro para el equipo comercial'),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text(
                  'Conexión',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
                children: [
                  field(
                    'Dirección del servidor',
                    server,
                    keyboard: TextInputType.url,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ],
  );
  Widget home() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      box(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: const TextStyle(
                color: gold,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '¿Qué deseas gestionar hoy?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Consulta información vigente antes de atender a tu cliente.',
              style: TextStyle(
                color: Color(0xffc0bdb5),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
        color: ink,
      ),
      title('Acciones rápidas'),
      Row(
        children: [
          Expanded(
            child: action(
              'Buscar lote',
              'Precio y disponibilidad',
              Icons.search,
              () => go('projects'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: action(
              'Nuevo cliente',
              'Registro comercial',
              Icons.person_add_alt,
              () => run(() async {
                c.lot = null;
                clearClient();
                go('client-form');
              }),
            ),
          ),
        ],
      ),
      title('Proyecto destacado'),
      for (final p in c.projects) projectCard(p),
      title('Mi actividad'),
      box(
        Column(
          children: [
            pair('Clientes registrados', '${c.clients.length}'),
            pair(
              'Separaciones activas',
              '${c.reservations.where((r) => r['estado'] == 'ACTIVA').length}',
            ),
          ],
        ),
      ),
      TextButton.icon(
        onPressed: () => run(c.refresh),
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Actualizar información'),
      ),
    ],
  );
  Widget action(String name, String sub, IconData icon, VoidCallback tap) =>
      InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(13),
        child: box(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: gold, size: 27),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),
              Text(sub, style: const TextStyle(color: muted, fontSize: 11)),
            ],
          ),
        ),
      );
  Widget projectCard(Data p) => InkWell(
    onTap: () => run(() => c.selectProject(p)),
    child: box(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.holiday_village_outlined, size: 45, color: gold),
          const SizedBox(height: 14),
          Text(
            '${p['nombre']}',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '${p['ubicacion']}',
            style: const TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ver manzanas y lotes',
                style: TextStyle(
                  color: Color(0xff9a7006),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.arrow_forward, color: gold, size: 19),
            ],
          ),
        ],
      ),
    ),
  );
  Widget projects() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      title('Encuentra el proyecto'),
      const Padding(
        padding: EdgeInsets.only(bottom: 18),
        child: Text(
          'Selecciona un proyecto para consultar información comercial.',
          style: TextStyle(color: muted, fontSize: 13),
        ),
      ),
      for (final p in c.projects) projectCard(p),
      if (c.projects.isEmpty) note('No hay proyectos disponibles.'),
    ],
  );
  Widget blocks() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '${c.project?['nombre']}',
        style: const TextStyle(
          color: Color(0xff9a7006),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      title('Selecciona una manzana'),
      for (final b in c.blocks)
        InkWell(
          onTap: () => run(() => c.selectBlock(b)),
          child: box(
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xfff5e8bb),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${b['codigo']}',
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manzana ${b['codigo']}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${b['etapa']}  ·  ${b['total']} lotes',
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${b['disponibles']} disponibles',
                        style: const TextStyle(
                          color: Color(0xff287541),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: gold),
              ],
            ),
          ),
        ),
      note('Los estados se consultan antes de confirmar cada operación.'),
    ],
  );
  Widget lots() {
    final list = c.lots
        .where(
          (l) =>
              (filter.isEmpty || l['estado'] == filter) &&
              ('${l['codigo']}'.toLowerCase().contains(
                search.text.toLowerCase(),
              )),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        title('Manzana ${c.block?['codigo']}'),
        TextField(
          controller: search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Buscar número de lote',
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final s in [
                '',
                'DISPONIBLE',
                'RESERVADO',
                'VENDIDO',
                'NO_DISPONIBLE',
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: ChoiceChip(
                    label: Text(
                      s.isEmpty ? 'Todos' : stateLabel(s),
                      style: const TextStyle(fontSize: 11),
                    ),
                    selected: filter == s,
                    onSelected: (_) => setState(() => filter = s),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final l in list)
          InkWell(
            onTap: () => run(() => c.selectLot(l)),
            child: box(
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 62,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xfff5e8bb),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '${l['codigo']}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lote ${l['codigo']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${l['area_m2']} m²',
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          money(l['precio']),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  badge(l['estado']),
                ],
              ),
            ),
          ),
        if (list.isEmpty) note('No se encontraron lotes con estos filtros.'),
      ],
    );
  }

  Widget detail() {
    final l = c.lot!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${l['proyecto']}',
              style: const TextStyle(
                color: Color(0xff9a7006),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            badge(l['estado']),
          ],
        ),
        title('Manzana ${l['manzana']} · Lote ${l['codigo']}'),
        box(
          Column(
            children: [
              pair('Área', '${l['area_m2']} m²'),
              pair('Etapa', '${l['etapa']}'),
              pair('Precio al contado', money(l['precio'])),
            ],
          ),
        ),
        title('Planes de pago'),
        for (final p in (l['planes'] as List))
          box(
            Column(
              children: [
                pair('${p['nombre']}', '${p['numero_cuotas']} cuotas'),
                pair('Inicial', money(p['inicial'])),
                pair('Cuota', money(p['monto_cuota'])),
              ],
            ),
          ),
        button(
          'Separar este lote',
          l['estado'] == 'DISPONIBLE'
              ? () => run(() async {
                  clearClient();
                  go('client-form');
                })
              : null,
          icon: Icons.key_outlined,
        ),
        OutlinedButton.icon(
          onPressed: () => run(() async {
            card = await c.api.bytes('/lots/${l['id']}/card.png');
            go('commercial-sheet');
          }),
          icon: const Icon(Icons.description_outlined),
          label: const Text('Generar ficha comercial'),
        ),
        TextButton.icon(
          onPressed: () => showHistory(l['id']),
          icon: const Icon(Icons.history),
          label: const Text('Ver historial'),
        ),
        if (c.admin && ['DISPONIBLE', 'NO_DISPONIBLE'].contains(l['estado']))
          TextButton(
            onPressed: () => run(() async {
              final reason = await prompt('Motivo del cambio');
              if (reason == null) return;
              await c.api.call('PATCH', '/lots/${l['id']}/state', {
                'estado': l['estado'] == 'DISPONIBLE'
                    ? 'NO_DISPONIBLE'
                    : 'DISPONIBLE',
                'motivo': reason,
              });
              await c.selectLot(l);
            }),
            child: Text(
              l['estado'] == 'DISPONIBLE'
                  ? 'Deshabilitar lote'
                  : 'Reactivar lote',
            ),
          ),
        note(
          'La disponibilidad se valida nuevamente al confirmar la separación.',
        ),
      ],
    );
  }

  Widget commercialCard() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      title('Ficha para tu cliente'),
      if (card != null)
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(card!),
        ),
      const SizedBox(height: 12),
      button(
        kIsWeb ? 'Guardar ficha' : 'Compartir ficha',
        () => run(() async {
          await share(card!, 'ficha_comercial.png', 'image/png');
        }),
        icon: Icons.share_outlined,
      ),
      note(
        'La ficha incluye únicamente información comercial. Confirma la disponibilidad antes de reservar.',
      ),
    ],
  );
  void clearClient() {
    for (final f in [names, surnames, document, phone, mail]) {
      f.clear();
    }
    c.selectedClient = null;
    c.documents = [];
    confirmed = false;
  }

  Widget steps(int current) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (int i = 0; i < 4; i++)
          Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: i <= current ? gold : const Color(0xffe8e4dc),
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    color: i <= current ? Colors.white : muted,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                ['Cliente', 'DNI', 'Separación', 'Confirmar'][i],
                style: const TextStyle(fontSize: 10, color: muted),
              ),
            ],
          ),
      ],
    ),
  );
  Widget clientForm() => Form(
    key: clientKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.lot != null) steps(0),
        title('Datos del cliente'),
        if (c.lot != null)
          TextButton.icon(
            onPressed: () => go('clients'),
            icon: const Icon(Icons.person_search),
            label: const Text('Seleccionar cliente existente'),
          ),
        note('Los datos personales se utilizan para la atención comercial.'),
        field('Nombres', names),
        field('Apellidos', surnames),
        DropdownButtonFormField<String>(
          initialValue: type,
          decoration: const InputDecoration(labelText: 'Tipo de documento'),
          items: const [
            DropdownMenuItem(value: 'DNI', child: Text('DNI')),
            DropdownMenuItem(value: 'CE', child: Text('Carné de extranjería')),
          ],
          onChanged: (v) => setState(() => type = v!),
        ),
        const SizedBox(height: 14),
        field('Número de documento', document, keyboard: TextInputType.text),
        field('Teléfono', phone, keyboard: TextInputType.phone),
        field(
          'Correo electrónico',
          mail,
          mandatory: false,
          keyboard: TextInputType.emailAddress,
        ),
        button(
          c.lot == null ? 'Guardar cliente' : 'Guardar y continuar',
          () => run(() async {
            if (!clientKey.currentState!.validate()) return;
            if (c.projects.isEmpty) {
              throw ApiException('No hay proyectos registrados.');
            }
            await c.saveClient({
              'nombre': '${names.text.trim()} ${surnames.text.trim()}',
              'tipo_documento': type,
              'numero_documento': document.text.trim(),
              'telefono': phone.text.trim(),
              'correo': mail.text.trim(),
              'proyecto_id': c.project?['id'] ?? c.projects.first['id'],
            });
          }),
          icon: Icons.arrow_forward,
        ),
      ],
    ),
  );
  Widget documents() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      steps(1),
      title('Fotografías del documento'),
      Text(
        '${c.selectedClient?['nombre']}',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      note(
        'Carga opcional para esta separación. Solo PNG o JPEG de hasta 5 MB. Las imágenes permanecen privadas.',
      ),
      for (final side in ['ANVERSO', 'REVERSO'])
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OutlinedButton(
            onPressed: () => run(() async {
              final f = await pickImage();
              if (f == null) return;
              if (f.bytes.length > 5 * 1024 * 1024) {
                throw ApiException('Selecciona una imagen de hasta 5 MB.');
              }
              await c.upload(side, f.bytes, f.name);
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  Icon(
                    c.documents.any((d) => d['lado'] == side)
                        ? Icons.check_circle_outline
                        : Icons.add_a_photo_outlined,
                    color: gold,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${side == 'ANVERSO' ? 'Anverso' : 'Reverso'} del documento',
                    ),
                  ),
                  Text(
                    c.documents.any((d) => d['lado'] == side)
                        ? 'Cargado'
                        : 'Adjuntar',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      note(
        'Asegúrate de que el documento se vea completo y sea legible.',
        icon: Icons.camera_alt_outlined,
      ),
      button('Continuar', () => go('separation'), icon: Icons.arrow_forward),
    ],
  );
  Widget separation() => Form(
    key: separationKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        steps(2),
        title('Datos de separación'),
        box(
          Column(
            children: [
              pair('Proyecto', '${c.lot?['proyecto']}'),
              pair('Lote', '${c.lot?['manzana']}-${c.lot?['codigo']}'),
              pair('Cliente', '${c.selectedClient?['nombre']}'),
              pair('Precio', money(c.lot?['precio'])),
            ],
          ),
        ),
        field(
          'Monto de separación (S/)',
          amount,
          keyboard: const TextInputType.numberWithOptions(decimal: true),
        ),
        pair(
          'Fecha de registro',
          '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
        ),
        field('Observación', observation, mandatory: false, lines: 3),
        note(
          'El monto de separación se registra en esta operación. El precio y los planes se consultan en el detalle del lote.',
        ),
        button(
          'Revisar separación',
          () => run(() async {
            if (!separationKey.currentState!.validate()) return;
            final value = num.tryParse(amount.text.replaceAll(',', '.'));
            if (value == null ||
                value <= 0 ||
                value > (c.lot!['precio'] as num)) {
              throw ApiException(
                'Ingresa un monto mayor que cero y dentro del precio.',
              );
            }
            setState(() => confirmed = false);
            go('review');
          }),
          icon: Icons.arrow_forward,
        ),
      ],
    ),
  );
  Widget review() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      steps(3),
      title('Revisa antes de confirmar'),
      box(
        Column(
          children: [
            pair('Cliente', '${c.selectedClient?['nombre']}'),
            pair('Documento', '${c.selectedClient?['numero_documento']}'),
            pair('Proyecto', '${c.lot?['proyecto']}'),
            pair('Lote', '${c.lot?['manzana']}-${c.lot?['codigo']}'),
            pair('Monto', money(amount.text.replaceAll(',', '.'))),
            pair('Asesor', '${c.user?['name']}'),
          ],
        ),
      ),
      note(
        'Al confirmar, el sistema volverá a validar la disponibilidad y cambiará el lote a Reservado.',
        icon: Icons.info_outline,
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: confirmed,
        onChanged: (v) => setState(() => confirmed = v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        title: const Text(
          'Confirmo que los datos de la operación son correctos.',
          style: TextStyle(fontSize: 13),
        ),
      ),
      button(
        'Confirmar separación',
        confirmed
            ? () => run(
                () => c.reserve(
                  num.parse(amount.text.replaceAll(',', '.')),
                  observation.text.trim(),
                ),
              )
            : null,
        icon: Icons.check,
      ),
      TextButton(
        onPressed: () => go('separation'),
        child: const Text('Volver a revisar'),
      ),
    ],
  );
  Widget success() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 25),
        child: Icon(
          Icons.check_circle_outline,
          size: 90,
          color: Color(0xff287541),
        ),
      ),
      const Text(
        '¡Separación exitosa!',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      const Text(
        'La operación quedó registrada.',
        textAlign: TextAlign.center,
        style: TextStyle(color: muted),
      ),
      const SizedBox(height: 25),
      box(
        Column(
          children: [
            pair('N.º de separación', '#${c.result?['id']}'),
            pair('Cliente', '${c.selectedClient?['nombre']}'),
            pair('Lote', '${c.lot?['manzana']}-${c.lot?['codigo']}'),
            pair('Monto', money(c.result?['monto'])),
            pair('Estado del lote', 'Reservado'),
          ],
        ),
      ),
      note('El historial registra al usuario y la fecha de la operación.'),
      button(
        'Ver separaciones',
        () => go('reservations'),
        icon: Icons.description_outlined,
      ),
      OutlinedButton(
        onPressed: () => go('home'),
        child: const Text('Volver al inicio'),
      ),
    ],
  );
  Widget clients() {
    final list = c.clients
        .where(
          (x) => '${x['nombre']} ${x['numero_documento']}'
              .toLowerCase()
              .contains(search.text.toLowerCase()),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        title(c.lot == null ? 'Mis clientes' : 'Selecciona un cliente'),
        TextField(
          controller: search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Nombre o documento',
          ),
        ),
        const SizedBox(height: 14),
        for (final item in list)
          InkWell(
            onTap: c.lot == null ? null : () => run(() => c.chooseClient(item)),
            child: box(
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xfff5e8bb),
                    child: Icon(Icons.person_outline, color: Color(0xff9a7006)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item['nombre']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item['tipo_documento']} ${item['numero_documento']}',
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                        Text(
                          '${item['telefono'] ?? ''}',
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (c.lot != null)
                    const Icon(Icons.chevron_right, color: gold),
                ],
              ),
            ),
          ),
        if (list.isEmpty) note('No se encontraron clientes.'),
        button('Nuevo cliente', () {
          clearClient();
          go('client-form');
        }, icon: Icons.person_add_alt),
      ],
    );
  }

  Widget reservations() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      title('Seguimiento comercial'),
      box(
        Column(
          children: [
            pair(
              'Separaciones activas',
              '${c.reservations.where((x) => x['estado'] == 'ACTIVA').length}',
            ),
            pair(
              'Monto registrado',
              money(
                c.reservations
                    .where((x) => x['estado'] == 'ACTIVA')
                    .fold<num>(0, (sum, x) => sum + (x['monto'] as num)),
              ),
            ),
          ],
        ),
      ),
      for (final r in c.reservations)
        box(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${r['id']}',
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                  badge(r['estado']),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${r['cliente']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${r['proyecto']} · ${r['manzana']}-${r['lote']}',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
              pair('Separación', money(r['monto'])),
              if (c.manager && r['estado'] == 'ACTIVA')
                Wrap(
                  spacing: 5,
                  children: [
                    TextButton(
                      onPressed: () => release(r),
                      child: const Text('Liberar'),
                    ),
                    TextButton(
                      onPressed: () => reassign(r),
                      child: const Text('Reasignar'),
                    ),
                    TextButton(
                      onPressed: () => sell(r),
                      child: const Text('Registrar venta'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      if (c.reservations.isEmpty)
        note('Todavía no hay separaciones registradas.'),
      if (c.manager)
        OutlinedButton.icon(
          onPressed: () => run(() async {
            final bytes = await c.api.bytes('/reports/reservations.xlsx');
            await share(
              bytes,
              'separaciones.xlsx',
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            );
          }),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Exportar reporte Excel'),
        ),
    ],
  );
  Future<String?> prompt(String text) async {
    final input = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(text),
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
    final reason = await prompt('Liberar reserva #${r['id']}');
    if (reason == null) return;
    await c.api.call('POST', '/reservations/${r['id']}/release', {
      'estado': 'DISPONIBLE',
      'motivo': reason,
    });
    await c.refresh();
  });
  Future<void> reassign(Data r) => run(() async {
    final options = cv.CasaController.rows(
      await c.api.call('GET', '/lots?state=DISPONIBLE'),
    );
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
    final reason = await prompt('Motivo de reasignación');
    if (reason == null) return;
    await c.api.call('POST', '/reservations/${r['id']}/reassign', {
      'lote_id': selected['id'],
      'motivo': reason,
    });
    await c.refresh();
  });
  Future<void> sell(Data r) => run(() async {
    final l = await c.api.call('GET', '/lots/${r['lote_id']}');
    if (!mounted) return;
    final price = TextEditingController(text: '${l['precio']}'),
        initial = TextEditingController(text: '${l['inicial']}');
    bool signed = false;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: const Text('Registrar venta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                field(
                  'Precio final (S/)',
                  price,
                  keyboard: TextInputType.number,
                ),
                field('Inicial (S/)', initial, keyboard: TextInputType.number),
                CheckboxListTile(
                  value: signed,
                  onChanged: (v) => update(() => signed = v ?? false),
                  title: const Text(
                    'Confirmo contrato firmado',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: signed ? () => Navigator.pop(ctx, true) : null,
              child: const Text('Confirmar venta'),
            ),
          ],
        ),
      ),
    );
    if (accepted == true) {
      await c.api.call('POST', '/reservations/${r['id']}/sale', {
        'plan_id': (l['planes'] as List).first['id'],
        'precio': num.tryParse(price.text),
        'inicial': num.tryParse(initial.text),
        'contrato_firmado': signed,
        'fecha': DateTime.now().toIso8601String().substring(0, 10),
      });
      await c.refresh();
    }
    price.dispose();
    initial.dispose();
  });
  Future<void> showHistory(int id) => run(() async {
    final list = cv.CasaController.rows(
      await c.api.call('GET', '/lots/$id/history'),
    );
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          title('Historial del lote'),
          if (list.isEmpty) const Text('Sin cambios registrados.'),
          for (final h in list)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${stateLabel(h['estado_anterior'])} a ${stateLabel(h['estado_nuevo'])}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                '${h['motivo']}\n${h['usuario']}\n${h['fecha_cambio']}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  });
  Future<void> share(Uint8List bytes, String name, String mime) async {
    await shareFile(bytes, name, mime);
  }
}
