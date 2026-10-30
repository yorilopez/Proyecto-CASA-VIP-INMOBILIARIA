import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:casa_vip/main.dart';
import 'package:casa_vip/api.dart';
import 'package:casa_vip/controller.dart' as cv;

class Fixture {
  int reservations = 0, loginCalls = 0;
  bool reject = false;
  List<Map<String, dynamic>> clientRows = [], operationRows = [];
  Map<String, dynamic>? reservationInput, clientInput;
  final documents = <String, List<Map<String, dynamic>>>{};
  final selectedPlans = [
    {
      'id': 12,
      'nombre': '12 meses',
      'inicial': 3000,
      'numero_cuotas': 12,
      'monto_cuota': 1500,
    },
    {
      'id': 24,
      'nombre': '24 meses',
      'inicial': 3000,
      'numero_cuotas': 24,
      'monto_cuota': 750,
    },
    {
      'id': 36,
      'nombre': '36 meses',
      'inicial': 3000,
      'numero_cuotas': 36,
      'monto_cuota': 500,
    },
    {
      'id': 48,
      'nombre': '48 meses',
      'inicial': 3000,
      'numero_cuotas': 48,
      'monto_cuota': 375,
    },
  ];
  late final Map<String, dynamic> lot = {
    'id': 3,
    'codigo': '6',
    'manzana': 'B',
    'manzana_id': 1,
    'area_m2': 124.42,
    'precio': 21000,
    'estado': 'DISPONIBLE',
    'referencia': 'Parque',
    'proyecto': 'SHENNAN HOUSE',
    'ubicacion': 'Huacho, Lima',
    'etapa': 'Etapa 1',
    'etapa_id': 1,
    'proyecto_id': 1,
    'version': 0,
    'inicial': 3000,
    'numero_cuotas': 48,
    'planes': selectedPlans,
  };
  late final api = ApiClient(
    'http://192.0.2.1:8080',
    client: MockClient((request) async {
      final path = request.url.path;
      dynamic data;
      if (path.endsWith('/notifications')) {
        data = {'items': [], 'pendientes': 0};
      } else if (path.endsWith('/auth/login')) {
        loginCalls++;
        if (reject) {
          return http.Response(
            jsonEncode({'message': 'Credenciales no válidas.'}),
            401,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        data = {
          'token': 'token-de-prueba',
          'user': {
            'id': 1,
            'name': 'Andrea Demo',
            'role': 'ASESOR',
            'phone': '900000000',
          },
        };
      } else if (path.endsWith('/projects')) {
        data = [
          {
            'id': 1,
            'nombre': 'SHENNAN HOUSE',
            'ubicacion': 'Huacho, Lima',
            'manzanas': 1,
            'lotes': 2,
            'disponibles': 1,
          },
        ];
      } else if (path.endsWith('/stages')) {
        data = [
          {'id': 1, 'nombre': 'Etapa 1'},
        ];
      } else if (path.endsWith('/blocks')) {
        data = [
          {
            'id': 1,
            'codigo': 'B',
            'etapa': 'Etapa 1',
            'etapa_id': 1,
            'proyecto_id': 1,
            'version': 0,
            'total': 2,
            'disponibles': 1,
          },
        ];
      } else if (path.endsWith('/lots')) {
        data = [
          lot,
          {...lot, 'id': 4, 'codigo': '7', 'estado': 'RESERVADO'},
        ];
      } else if (path.endsWith('/lots/3')) {
        data = lot;
      } else if (RegExp(r'/clients/\d+/documents').hasMatch(path)) {
        final match = RegExp(
          r'/clients/(\d+)/documents(?:/(ANVERSO|REVERSO))?$',
        ).firstMatch(path)!;
        final id = match.group(1)!, side = match.group(2);
        if (request.method == 'POST') {
          documents.putIfAbsent(id, () => []);
          documents[id]!.removeWhere((d) => d['lado'] == side);
          documents[id]!.add({'id': documents[id]!.length + 1, 'lado': side});
          data = {'ok': true};
        } else {
          data = documents[id] ?? [];
        }
      } else if (path.endsWith('/clients') && request.method == 'POST' ||
          RegExp(r'/clients/\d+$').hasMatch(path) && request.method == 'PUT') {
        clientInput = jsonDecode(request.body);
        data = {...clientInput!, 'id': 10};
        if (clientInput!['cotitular'] != null) {
          data['cotitular'] = {...clientInput!['cotitular'], 'id': 11};
        }
      } else if (RegExp(r'/clients/\d+$').hasMatch(path) &&
          request.method == 'GET') {
        data = clientRows.firstWhere((c) => path.endsWith('/${c['id']}'));
      } else if (path.endsWith('/clients')) {
        final category = request.url.queryParameters['category'];
        data = clientRows.where((person) {
          final linked = operationRows.where(
            (op) =>
                op['cliente_id'] == person['id'] ||
                op['cotitular_id'] == person['id'],
          );
          return category == 'VENTA'
              ? linked.any((r) => r['estado'] == 'CONFIRMADA')
              : category == 'SEPARACION'
              ? linked.any((r) => r['estado'] == 'ACTIVA')
              : category == 'POTENCIAL'
              ? !linked.any(
                  (r) => ['ACTIVA', 'CONFIRMADA'].contains(r['estado']),
                )
              : true;
        }).toList();
      } else if (path.endsWith('/reservations') && request.method == 'POST') {
        reservations++;
        reservationInput = jsonDecode(request.body);
        data = {
          'id': 99,
          'monto': 500,
          'fecha_registro': '2026-10-27T10:00:00-05:00',
          'estado': 'ACTIVA',
          'numero_cuotas_acordado': 24,
        };
      } else if (path.endsWith('/reservations')) {
        data = operationRows;
      } else {
        data = {'ok': true};
      }
      return http.Response(
        jsonEncode(data),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }),
  );
}

void dimensions(WidgetTester t) {
  t.view.physicalSize = const Size(430, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

Future<void> tapText(WidgetTester t, String text, {bool last = false}) async {
  final button = find.widgetWithText(FilledButton, text);
  final match = button.evaluate().isNotEmpty ? button : find.text(text);
  final target = last ? match.last : match.first;
  await t.ensureVisible(target);
  await t.pumpAndSettle();
  await t.tap(target);
  await t.pumpAndSettle();
}

Future<void> enter(
  WidgetTester t,
  String label,
  String value, {
  bool last = false,
}) async {
  final match = find.byKey(ValueKey(label));
  await t.ensureVisible(last ? match.last : match.first);
  await t.enterText(last ? match.last : match.first, value);
  await t.pumpAndSettle();
}

Future<void> login(WidgetTester t) async {
  await enter(t, 'Correo corporativo', 'asesor@casavip.pe');
  await enter(t, 'Contraseña', 'CasaVIP-demo-2026!');
  await tapText(t, 'Ingresar');
}

Future<void> openLot(WidgetTester t) async {
  await login(t);
  await tapText(t, 'Buscar lote');
  await tapText(t, 'Shennan House');
  await tapText(t, 'Manzana B');
  await tapText(t, 'Lote 6');
}

Future<void> fillPerson(WidgetTester t, {bool co = false}) async {
  await enter(
    t,
    'Nombres y apellidos',
    co ? 'Cotitular de prueba' : 'Cliente de prueba',
    last: co,
  );
  await enter(t, 'DNI', co ? '00000112' : '00000111', last: co);
  await enter(t, 'Teléfono', co ? '900000112' : '900000111', last: co);
  await enter(
    t,
    'Dirección',
    co ? 'Dirección del cotitular' : 'Dirección demostrativa',
    last: co,
  );
  await enter(
    t,
    'Correo',
    co ? 'co@example.test' : 'cliente@example.test',
    last: co,
  );
  await enter(t, 'Ocupación', 'Comerciante', last: co);
}

void mockFiles() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('pe.casavip/files'),
        (call) async => call.method == 'pickImage'
            ? {
                'bytes': Uint8List.fromList(
                  base64Decode(
                    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aX1sAAAAASUVORK5CYII=',
                  ),
                ),
                'name': 'foto.png',
              }
            : null,
      );
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('pe.casavip/files'),
          null,
        ),
  );
}

Future<void> photos(WidgetTester t, {bool co = false}) async {
  for (final label
      in co
          ? [
              'DNI titular · Anverso',
              'DNI titular · Reverso',
              'DNI cotitular · Anverso',
              'DNI cotitular · Reverso',
            ]
          : ['DNI · Anverso', 'DNI · Reverso']) {
    await tapText(t, label);
  }
}

void main() {
  testWidgets('El formulario exige credenciales antes de enviar', (t) async {
    dimensions(t);
    final f = Fixture();
    await t.pumpWidget(CasaVipApp(api: f.api));
    await tapText(t, 'Ingresar');
    expect(f.loginCalls, 0);
    expect(find.text('Completa este campo.'), findsNWidgets(2));
    expect(t.takeException(), isNull);
  });
  testWidgets('El login no muestra servidor, IP ni configuración técnica', (
    t,
  ) async {
    dimensions(t);
    final f = Fixture();
    await t.pumpWidget(CasaVipApp(api: f.api));
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Conexión'), findsNothing);
    expect(find.text('Dirección del servidor'), findsNothing);
    expect(find.textContaining('192.0.2.1'), findsNothing);
    expect(find.textContaining('http://'), findsNothing);
    expect(find.text('ACCESO'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('El error de acceso conserva el diseño y no revela el endpoint', (
    t,
  ) async {
    dimensions(t);
    final f = Fixture()..reject = true;
    await t.pumpWidget(CasaVipApp(api: f.api));
    await login(t);
    expect(find.text('Credenciales no válidas.'), findsOneWidget);
    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.textContaining('192.0.2.1'), findsNothing);
    expect(t.takeException(), isNull);
  });
  testWidgets('El catálogo recupera tarjetas, filtros y planes del prototipo', (
    t,
  ) async {
    dimensions(t);
    final f = Fixture();
    await t.pumpWidget(CasaVipApp(api: f.api));
    await openLot(t);
    expect(find.text('Lote 06'), findsOneWidget);
    expect(find.text('Ver condiciones'), findsOneWidget);
    for (final n in ['12 meses', '24 meses', '36 meses', '48 meses']) {
      expect(find.text(n), findsOneWidget);
    }
    expect(find.text('Ficha'), findsOneWidget);
    expect(find.text('Separar lote'), findsOneWidget);
    await tapText(t, 'Ficha');
    expect(find.textContaining('Etapa 1'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'El plan elegido y los campos del cliente llegan a la API al confirmar',
    (t) async {
      dimensions(t);
      mockFiles();
      final f = Fixture();
      await t.pumpWidget(CasaVipApp(api: f.api));
      await openLot(t);
      await tapText(t, '24 meses');
      await tapText(t, 'Separar lote');
      await fillPerson(t);
      await tapText(t, 'Continuar');
      expect(f.clientInput!['direccion'], 'Dirección demostrativa');
      expect(f.clientInput!['ocupacion'], 'Comerciante');
      await photos(t);
      await tapText(t, 'Continuar');
      expect(find.text('Condiciones acordadas'), findsOneWidget);
      await tapText(t, 'Revisar separación');
      expect(f.reservations, 0);
      final button = find.widgetWithText(FilledButton, 'Confirmar separación');
      expect(t.widget<FilledButton>(button).onPressed, isNull);
      await t.ensureVisible(find.byType(Checkbox));
      await t.tap(find.byType(Checkbox));
      await t.pumpAndSettle();
      await tapText(t, 'Confirmar separación');
      expect(f.reservations, 1);
      expect(f.reservationInput!['plan_id'], 24);
      expect(find.text('¡Lote reservado!'), findsOneWidget);
      expect(find.text('SEP-2026-0099'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('El cotitular conserva sus datos y sus cuatro documentos', (
    t,
  ) async {
    dimensions(t);
    mockFiles();
    final f = Fixture();
    await t.pumpWidget(CasaVipApp(api: f.api));
    await openLot(t);
    await tapText(t, 'Separar lote');
    await fillPerson(t);
    await t.ensureVisible(find.byType(Switch));
    await t.tap(find.byType(Switch));
    await t.pumpAndSettle();
    await fillPerson(t, co: true);
    await tapText(t, 'Guardar cotitular');
    await tapText(t, 'Continuar');
    expect(f.clientInput!['cotitular']['numero_documento'], '00000112');
    await photos(t, co: true);
    expect(f.documents['10']!.length, 2);
    expect(f.documents['11']!.length, 2);
    await tapText(t, 'Continuar');
    await tapText(t, 'Revisar separación');
    expect(find.text('Cotitular'), findsOneWidget);
    expect(find.text('Cotitular de prueba'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('Los filtros por disponibilidad ocultan lotes reservados', (
    t,
  ) async {
    dimensions(t);
    final f = Fixture();
    await t.pumpWidget(CasaVipApp(api: f.api));
    await login(t);
    await tapText(t, 'Buscar lote');
    await tapText(t, 'Shennan House');
    await tapText(t, 'Manzana B');
    expect(find.text('Lote 7'), findsOneWidget);
    await tapText(t, 'Disponibles');
    expect(find.text('Lote 7'), findsNothing);
    expect(find.text('1 lotes mostrados'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('La sesión se cierra desde el avatar sin cambiar la cabecera', (
    t,
  ) async {
    dimensions(t);
    final f = Fixture();
    await t.pumpWidget(CasaVipApp(api: f.api));
    await login(t);
    expect(find.text('Hola, Andrea'), findsOneWidget);
    await t.tap(find.byTooltip('Mi cuenta'));
    await t.pumpAndSettle();
    await tapText(t, 'Cerrar sesión');
    expect(find.text('Bienvenido'), findsOneWidget);
    expect(f.api.token, isNull);
    expect(t.takeException(), isNull);
  });
  testWidgets('El catálogo y el formulario caben en una pantalla de 360 px', (
    t,
  ) async {
    dimensions(t);
    t.view.physicalSize = const Size(360, 800);
    final f = Fixture();
    await t.pumpWidget(CasaVipApp(api: f.api));
    await openLot(t);
    await tapText(t, 'Separar lote');
    await fillPerson(t);
    expect(t.takeException(), isNull);
  });
  test('El cliente HTTP revoca la sesión ante 401', () async {
    final api = ApiClient(
      'http://localhost',
      client: MockClient(
        (_) async => http.Response(
          '{"message":"Sesión vencida"}',
          401,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    )..token = 'temporal';
    await expectLater(
      api.call('GET', '/projects'),
      throwsA(isA<ApiException>()),
    );
    expect(api.token, isNull);
  });
  test(
    'El controlador conserva el identificador real y envía el plan seleccionado',
    () async {
      final f = Fixture(), c = cv.CasaController(Fixture().api);
      final controller = cv.CasaController(f.api);
      await controller.login('asesor@casavip.pe', 'clave');
      controller.lot = f.lot;
      controller.selectedClient = {'id': 10};
      controller.selectedPlan = f.selectedPlans[1];
      await controller.reserve(500, 'Prueba');
      expect(controller.result!['id'], 99);
      expect(f.reservationInput!['plan_id'], 24);
      expect(controller.screen, 'success');
      c.dispose();
      controller.dispose();
    },
  );
  testWidgets(
    'El login rechaza el exceso de caracteres sin enviar credenciales',
    (t) async {
      dimensions(t);
      final f = Fixture();
      await t.pumpWidget(CasaVipApp(api: f.api));
      await enter(t, 'Correo corporativo', '${'a' * 250}@a.pe');
      await enter(t, 'Contraseña', 'CasaVIP-demo-2026!');
      await tapText(t, 'Ingresar');
      expect(f.loginCalls, 0);
      expect(find.text('Máximo 254 caracteres.'), findsOneWidget);
      await enter(t, 'Correo corporativo', 'asesor@casavip.pe');
      await enter(t, 'Contraseña', 'x' * 65);
      await tapText(t, 'Ingresar');
      expect(f.loginCalls, 0);
      expect(find.text('Máximo 64 caracteres.'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('Inicial y cuotas negociadas se envían sin cambiar el catálogo', (
    t,
  ) async {
    dimensions(t);
    mockFiles();
    final f = Fixture();
    await t.pumpWidget(CasaVipApp(api: f.api));
    await openLot(t);
    await tapText(t, 'Separar lote');
    await fillPerson(t);
    await tapText(t, 'Continuar');
    await photos(t);
    await tapText(t, 'Continuar');
    await enter(t, 'Inicial acordada (S/)', '5000');
    await enter(t, 'Número de cuotas acordado', '31');
    await tapText(t, 'Revisar separación');
    await t.ensureVisible(find.byType(Checkbox));
    await t.tap(find.byType(Checkbox));
    await t.pumpAndSettle();
    await tapText(t, 'Confirmar separación');
    expect(f.reservationInput!['inicial_acordada'], 5000);
    expect(f.reservationInput!['numero_cuotas_acordado'], 31);
    expect(f.reservationInput!['precio_acordado'], 21000);
    expect(f.lot['precio'], 21000);
    expect(t.takeException(), isNull);
  });
  testWidgets('Seleccionar un cliente registrado permite agregar cotitular', (
    t,
  ) async {
    dimensions(t);
    final f = Fixture();
    f.clientRows = [
      {
        'id': 10,
        'nombre': 'Cliente existente',
        'tipo_documento': 'DNI',
        'numero_documento': '00123456',
        'telefono': '900123456',
        'proyecto_id': 1,
      },
    ];
    await t.pumpWidget(CasaVipApp(api: f.api));
    await openLot(t);
    await tapText(t, 'Separar lote');
    await tapText(t, 'Seleccionar cliente existente');
    await tapText(t, 'Cliente existente');
    await t.ensureVisible(find.byType(Switch));
    await t.tap(find.byType(Switch));
    await t.pumpAndSettle();
    await fillPerson(t, co: true);
    await tapText(t, 'Guardar cotitular');
    await tapText(t, 'Continuar');
    expect(f.clientInput!['numero_documento'], '00123456');
    expect(f.clientInput!['cotitular']['numero_documento'], '00000112');
    expect(find.text('Documentos de identidad'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('Clientes distingue separaciones y ventas', (t) async {
    dimensions(t);
    final f = Fixture();
    f.clientRows = [
      {
        'id': 10,
        'nombre': 'Cliente reservado',
        'numero_documento': '00123456',
        'tipo_documento': 'DNI',
      },
      {
        'id': 11,
        'nombre': 'Cliente vendido',
        'numero_documento': '00123457',
        'tipo_documento': 'DNI',
      },
    ];
    f.operationRows = [
      {
        'id': 1,
        'cliente_id': 10,
        'estado': 'ACTIVA',
        'monto': 500,
        'proyecto': 'SHENNAN HOUSE',
        'manzana': 'B',
        'lote': '6',
        'cliente': 'Cliente reservado',
      },
      {
        'id': 2,
        'cliente_id': 11,
        'estado': 'CONFIRMADA',
        'monto': 500,
        'proyecto': 'SHENNAN HOUSE',
        'manzana': 'B',
        'lote': '7',
        'cliente': 'Cliente vendido',
      },
    ];
    await t.pumpWidget(CasaVipApp(api: f.api));
    await login(t);
    await tapText(t, 'Clientes');
    await t.tap(find.textContaining(' · ').first);
    await t.pumpAndSettle();
    await t.tap(find.byType(DropdownButtonFormField<String>).first);
    await t.pumpAndSettle();
    await tapText(t, 'Con venta', last: true);
    await tapText(t,'Aplicar filtros');
    expect(find.text('Cliente vendido'), findsOneWidget);
    expect(find.text('Cliente reservado'), findsNothing);
    await t.tap(find.textContaining(' · ').first);
    await t.pumpAndSettle();
    await t.tap(find.byType(DropdownButtonFormField<String>).first);
    await t.pumpAndSettle();
    await tapText(t, 'Con separación', last: true);
    await tapText(t,'Aplicar filtros');
    expect(find.text('Cliente reservado'), findsOneWidget);
    expect(find.text('Cliente vendido'), findsNothing);
    expect(find.text('Operaciones'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
