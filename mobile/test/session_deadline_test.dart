import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:casa_vip/api.dart';
import 'package:casa_vip/controller.dart';
import 'package:casa_vip/deadline.dart';
import 'package:casa_vip/session_store.dart';

class MemorySessions extends SessionStore {
  Map<String,dynamic>? value;
  @override Future<Map<String,dynamic>?> read() async => value;
  @override Future<void> save(String base,String token,String expires) async {value={'base':base,'token':token,'expires':expires};}
  @override Future<void> clear() async {value=null;}
}
void main(){
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Plazos definidos y montos que requieren plazo manual',(){
    expect(defaultDeadline(100),3);expect(defaultDeadline(200),5);expect(defaultDeadline(500),14);expect(defaultDeadline(750),isNull);expect(defaultDeadline(150),isNull);
    expect(validateDeadline('15',500),isNotNull);expect(validateDeadline('14',500),isNull);expect(validateDeadline('',750),isNotNull);expect(validateDeadline('30',750),isNull);expect(validateDeadline('0',750),isNotNull);
  });
  test('Recordar guarda token y vencimiento sin credenciales y salir lo borra',()async{
    final store=MemorySessions();Map<String,dynamic>? sent;
    final api=ApiClient('http://localhost:8080',client:MockClient((request)async{
      dynamic data=[];
      if(request.url.path.endsWith('/auth/login')){sent=jsonDecode(request.body);data={'token':'opaque-token','expires':DateTime.now().add(const Duration(days:30)).toIso8601String(),'user':{'id':1,'name':'Asesor','role':'ASESOR'}};}
      if(request.url.path.endsWith('/notifications'))data={'items':[],'pendientes':0};
      if(request.url.path.endsWith('/auth/logout'))data={'ok':true};
      return http.Response(jsonEncode(data),200);
    }));
    final controller=CasaController(api,sessionStore:store);
    await controller.login('asesor@example.invalid','clave',remember:true);
    expect(sent!['remember'],true);expect(store.value!['token'],'opaque-token');expect(store.value!.containsKey('password'),false);expect(store.value!.containsKey('email'),false);
    await controller.logout();expect(store.value,isNull);expect(api.token,isNull);expect(controller.user,isNull);expect(controller.screen,'login');controller.dispose();
  });
  test('La sesión sin recordar queda solo en memoria',()async{
    final store=MemorySessions();
    final api=ApiClient('http://localhost:8080',client:MockClient((request)async{
      dynamic data=[];if(request.url.path.endsWith('/auth/login'))data={'token':'temporary','user':{'id':1,'role':'ASESOR'}};if(request.url.path.endsWith('/notifications'))data={'items':[],'pendientes':0};return http.Response(jsonEncode(data),200);
    }));
    final c=CasaController(api,sessionStore:store);await c.login('a@b.com','clave');expect(store.value,isNull);expect(api.token,'temporary');c.dispose();
  });
  test('Una sesión vencida o de otro servidor no se restaura',()async{
    final store=MemorySessions()..value={'base':'http://localhost:8080','token':'expired','expires':DateTime.now().subtract(const Duration(days:1)).toIso8601String()};
    int requests=0;final api=ApiClient('http://localhost:8080',client:MockClient((r)async{requests++;return http.Response('{}',200);}));
    final c=CasaController(api,sessionStore:store);await c.restoreSession();expect(requests,0);expect(store.value,isNull);expect(c.screen,'login');c.dispose();
  });
}
