import 'package:flutter_test/flutter_test.dart';
import 'package:casa_vip/listing_filter.dart';
void main(){
 test('El mes de Lima respeta el límite UTC de medianoche',(){expect(businessMonth(DateTime.utc(2026,11,1,4,59)),'2026-10');expect(businessMonth(DateTime.utc(2026,11,1,5)),'2026-11');});
 test('Los filtros combinados conservan período categoría y usuario',(){final url=Uri.parse(listingUrl('/admin/history',{'month':'2026-01','entity':'CLIENTE','user':'3'}));expect(url.queryParameters,{'month':'2026-01','entity':'CLIENTE','user':'3'});});
 test('Todos los períodos omite parámetros vacíos',(){expect(listingUrl('/clients',{'month':'','category':''}),'/clients');expect(listingUrl('/clients',{'month':'','category':'POTENCIAL'}),'/clients?category=POTENCIAL');});
 test('El período visible identifica mes y año',(){expect(monthLabel('2025-12'),'Diciembre 2025');expect(monthLabel(''),'Todos los períodos');});
}
