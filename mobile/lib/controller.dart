import 'package:flutter/foundation.dart';
import 'api.dart';

typedef Row = Map<String, dynamic>;

/// Coordina el flujo del prototipo con datos devueltos por la API.
class CasaController extends ChangeNotifier {
  final ApiClient api;
  CasaController(this.api);
  String screen = 'login';
  Row? user,
      project,
      block,
      lot,
      selectedClient,
      result,
      selectedPlan,
      coClient;
  List<Row> projects = [],
      blocks = [],
      lots = [],
      clients = [],
      reservations = [],
      documents = [],
      coDocuments = [],
      stages = [];
  bool get manager => user?['role'] != 'ASESOR';
  bool get admin => user?['role'] == 'ADMINISTRADOR';
  static List<Row> rows(dynamic d) =>
      (d as List).map((x) => Map<String, dynamic>.from(x)).toList();
  Future<void> login(String email, String password) async {
    final data = await api.call('POST', '/auth/login', {
      'email': email,
      'password': password,
    });
    api.token = data['token'];
    user = Map<String, dynamic>.from(data['user']);
    await refresh();
    go('home');
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
    result = null;
    selectedPlan = null;
    coClient = null;
    projects = [];
    blocks = [];
    lots = [];
    clients = [];
    reservations = [];
    documents = [];
    coDocuments = [];
    stages = [];
    screen = 'login';
    notifyListeners();
  }

  void go(String s) {
    screen = s;
    notifyListeners();
  }

  Future<void> selectProject(Row p) async {
    project = p;
    blocks = rows(await api.call('GET', '/projects/${p['id']}/blocks'));
    stages = rows(await api.call('GET', '/projects/${p['id']}/stages'));
    go('blocks');
  }

  Future<void> selectBlock(Row b) async {
    block = b;
    lots = rows(await api.call('GET', '/lots?block=${b['id']}'));
    go('lots');
  }

  Future<void> selectLot(Row l) async {
    lot = Map<String, dynamic>.from(await api.call('GET', '/lots/${l['id']}'));
    final p = rows(lot!['planes']);
    selectedPlan = p.isEmpty ? null : p.last;
    go('lot-detail');
  }

  Future<void> saveClient(Row input) async {
    selectedClient = Map<String, dynamic>.from(
      await api.call(
        selectedClient != null &&
                selectedClient!['numero_documento'] == input['numero_documento']
            ? 'PUT'
            : 'POST',
        selectedClient != null &&
                selectedClient!['numero_documento'] == input['numero_documento']
            ? '/clients/${selectedClient!['id']}'
            : '/clients',
        input,
      ),
    );
    coClient = selectedClient!['cotitular'] == null
        ? null
        : Map<String, dynamic>.from(selectedClient!['cotitular']);
    await refresh();
    if (lot == null) {
      go('clients');
    } else {
      await loadDocuments();
      go('documents');
    }
  }

  Future<void> loadDocuments() async {
    documents = rows(
      await api.call('GET', '/clients/${selectedClient!['id']}/documents'),
    );
    coDocuments = coClient == null
        ? []
        : rows(await api.call('GET', '/clients/${coClient!['id']}/documents'));
  }

  Future<void> chooseClient(Row input) async {
    selectedClient = Map<String, dynamic>.from(
      await api.call('GET', '/clients/${input['id']}'),
    );
    coClient = selectedClient!['cotitular'] == null
        ? null
        : Map<String, dynamic>.from(selectedClient!['cotitular']);
    await loadDocuments();
    go('documents');
  }

  Future<void> reserve(num amount, String observation) async {
    result = Map<String, dynamic>.from(
      await api.call('POST', '/reservations', {
        'lote_id': lot!['id'],
        'cliente_id': selectedClient!['id'],
        'monto': amount,
        'observacion': observation,
        if (selectedPlan != null) 'plan_id': selectedPlan!['id'],
        if (coClient != null) 'cotitular_id': coClient!['id'],
      }),
    );
    await refresh();
    go('success');
  }

  Future<void> upload(
    String side,
    Uint8List bytes,
    String name, {
    bool cotitular = false,
  }) async {
    final person = cotitular ? coClient : selectedClient;
    await api.upload(person!['id'], side, bytes, name);
    await loadDocuments();
    notifyListeners();
  }
}
