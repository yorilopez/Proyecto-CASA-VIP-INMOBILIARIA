import 'package:flutter/foundation.dart';
import 'api.dart';

typedef Row = Map<String, dynamic>;

/// Coordina navegación y casos de uso. La vista no conoce SQL ni credenciales de BD.
class CasaController extends ChangeNotifier {
  final ApiClient api;
  CasaController(this.api);
  String screen = 'login';
  Row? user, project, block, lot, selectedClient, result;
  List<Row> projects = [],
      blocks = [],
      lots = [],
      clients = [],
      reservations = [],
      documents = [];
  bool get manager => user?['role'] != 'ASESOR';
  bool get admin => user?['role'] == 'ADMINISTRADOR';
  static List<Row> rows(dynamic data) =>
      (data as List).map((x) => Map<String, dynamic>.from(x)).toList();
  Future<void> login(String email, String password) async {
    final data = await api.call('POST', '/auth/login', {
      'email': email,
      'password': password,
    });
    api.token = data['token'];
    user = Map<String, dynamic>.from(data['user']);
    await refresh();
    screen = 'home';
    notifyListeners();
  }

  Future<void> refresh() async {
    projects = rows(await api.call('GET', '/projects'));
    clients = rows(await api.call('GET', '/clients'));
    reservations = rows(await api.call('GET', '/reservations'));
  }

  Future<void> logout() async {
    try {
      await api.call('POST', '/auth/logout');
    } finally {
      clear();
    }
  }

  void clear() {
    api.token = null;
    user = null;
    project = null;
    block = null;
    lot = null;
    selectedClient = null;
    projects = [];
    blocks = [];
    lots = [];
    clients = [];
    reservations = [];
    documents = [];
    result = null;
    screen = 'login';
    notifyListeners();
  }

  void go(String page) {
    screen = page;
    notifyListeners();
  }

  Future<void> selectProject(Row p) async {
    project = p;
    blocks = rows(await api.call('GET', '/projects/${p['id']}/blocks'));
    go('blocks');
  }

  Future<void> selectBlock(Row b) async {
    block = b;
    lots = rows(await api.call('GET', '/lots?block=${b['id']}'));
    go('lots');
  }

  Future<void> selectLot(Row l) async {
    lot = Map<String, dynamic>.from(await api.call('GET', '/lots/${l['id']}'));
    go('lot-detail');
  }

  Future<void> saveClient(Row input) async {
    selectedClient = Map<String, dynamic>.from(
      await api.call('POST', '/clients', input),
    );
    await refresh();
    if (lot == null) {
      go('clients');
    } else {
      documents = rows(
        await api.call('GET', '/clients/${selectedClient!['id']}/documents'),
      );
      go('documents');
    }
  }

  Future<void> chooseClient(Row c) async {
    selectedClient = c;
    documents = rows(await api.call('GET', '/clients/${c['id']}/documents'));
    go('documents');
  }

  Future<void> reserve(num amount, String observation) async {
    result = Map<String, dynamic>.from(
      await api.call('POST', '/reservations', {
        'lote_id': lot!['id'],
        'cliente_id': selectedClient!['id'],
        'monto': amount,
        'observacion': observation,
      }),
    );
    await refresh();
    go('success');
  }

  Future<void> upload(String side, Uint8List bytes, String name) async {
    await api.upload(selectedClient!['id'], side, bytes, name);
    documents = rows(
      await api.call('GET', '/clients/${selectedClient!['id']}/documents'),
    );
    notifyListeners();
  }
}
