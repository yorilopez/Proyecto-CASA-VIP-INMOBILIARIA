import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:casa_vip/main.dart';
import 'package:casa_vip/api.dart';
import 'package:casa_vip/controller.dart' as cv;

class Fixture {
  int reservations = 0, loginCalls = 0;
  bool reject = false;
  final lot = <String, dynamic>{
    'id': 3,
    'codigo': '6',
    'manzana': 'B',
    'area_m2': 124.42,
    'precio': 21000,
    'estado': 'DISPONIBLE',
    'proyecto': 'SHENNAN HOUSE',
    'etapa': 'Etapa 1',
    'inicial': 3000,
    'numero_cuotas': 48,
    'planes': [
      {
        'id': 3,
        'nombre': '48 cuotas',
        'inicial': 3000,
        'numero_cuotas': 48,
        'monto_cuota': 375,
      },
    ],
  };
  late final api = ApiClient(
    'http://localhost:8080',
    client: MockClient((request) async {
      final path = request.url.path;
      dynamic data;
      if (path.endsWith('/auth/login')) {
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
          'user': {'id': 1, 'name': 'Andrea Demo', 'role': 'ASESOR'},
        };
      } else if (path.endsWith('/projects')) {
        data = [
          {'id': 1, 'nombre': 'SHENNAN HOUSE', 'ubicacion': 'Piloto comercial'},
        ];
      } else if (path.endsWith('/blocks')) {
        data = [
          {
            'id': 1,
            'codigo': 'B',
            'etapa': 'Etapa 1',
            'total': 7,
            'disponibles': 3,
          },
        ];
      } else if (path.endsWith('/lots')) {
        data = [lot];
      } else if (path.endsWith('/lots/3')) {
        data = lot;
      } else if (path.endsWith('/clients') && request.method == 'POST') {
        data = {...jsonDecode(request.body) as Map<String, dynamic>, 'id': 10};
      } else if (path.endsWith('/clients')) {
        data = [];
      } else if (path.endsWith('/documents')) {
        data = [];
      } else if (path.endsWith('/reservations') && request.method == 'POST') {
        reservations++;
        data = {'id': 99, 'monto': 500};
      } else if (path.endsWith('/reservations')) {
        data = [];
      } else {
        data = {'ok': true};
      }
      return http.Response(
        jsonEncode(data),
        200,
        headers: {'content-type': 'application/json'},
      );
    }),
  );
}

Future<void> tapText(WidgetTester tester, String text) async {
  final action = find.widgetWithText(FilledButton, text);
  final target = action.evaluate().isNotEmpty
      ? action.first
      : find.text(text).first;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void dimensions(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> login(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'asesor@casavip.pe');
  await tester.enterText(
    find.byType(TextFormField).at(1),
    'CasaVIP-demo-2026!',
  );
  await tapText(tester, 'Ingresar');
}

void main() {
  testWidgets('El formulario exige credenciales antes de enviar', (
    tester,
  ) async {
    dimensions(tester);
    final f = Fixture();
    await tester.pumpWidget(CasaVipApp(api: f.api));
    await tapText(tester, 'Ingresar');
    expect(f.loginCalls, 0);
    expect(find.text('Completa este campo.'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
  testWidgets('Un error de autenticación conserva el formulario', (
    tester,
  ) async {
    dimensions(tester);
    final f = Fixture()..reject = true;
    await tester.pumpWidget(CasaVipApp(api: f.api));
    await login(tester);
    expect(find.text('Credenciales no válidas.'), findsOneWidget);
    expect(find.text('Bienvenido'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'El flujo visual registra la separación solo después de confirmar',
    (tester) async {
      dimensions(tester);
      final f = Fixture();
      await tester.pumpWidget(CasaVipApp(api: f.api));
      await login(tester);
      expect(find.text('Hola, Andrea Demo'), findsOneWidget);
      await tapText(tester, 'Buscar lote');
      await tapText(tester, 'Ver manzanas y lotes');
      await tapText(tester, 'Manzana B');
      await tapText(tester, 'Lote 6');
      await tapText(tester, 'Separar este lote');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombres'),
        'Cliente',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Apellidos'),
        'Prueba',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Número de documento'),
        '00123456',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Teléfono'),
        '900123456',
      );
      await tapText(tester, 'Guardar y continuar');
      expect(find.text('Fotografías del documento'), findsOneWidget);
      await tapText(tester, 'Continuar');
      await tapText(tester, 'Revisar separación');
      expect(f.reservations, 0);
      final button = find.widgetWithText(FilledButton, 'Confirmar separación');
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tapText(tester, 'Confirmar separación');
      expect(f.reservations, 1);
      expect(find.text('¡Separación exitosa!'), findsOneWidget);
      expect(find.text('#99'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  test('El cliente HTTP revoca el token cuando la API responde 401', () async {
    final api = ApiClient(
      'http://localhost',
      client: MockClient(
        (_) async => http.Response('{"message":"Sesión vencida"}', 401),
      ),
    )..token = 'temporal';
    await expectLater(
      api.call('GET', '/projects'),
      throwsA(isA<ApiException>()),
    );
    expect(api.token, isNull);
  });
  test(
    'El controlador usa el identificador real devuelto por el servidor',
    () async {
      final f = Fixture();
      final c = cv.CasaController(f.api);
      await c.login('asesor@casavip.pe', 'clave');
      c.lot = f.lot;
      c.selectedClient = {'id': 10};
      await c.reserve(500, 'Prueba');
      expect(c.result!['id'], 99);
      expect(c.screen, 'success');
      expect(f.reservations, 1);
    },
  );
}
