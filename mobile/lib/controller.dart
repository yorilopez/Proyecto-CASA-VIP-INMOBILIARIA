import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api.dart';

typedef Row = Map<String, dynamic>;

/// Coordina el flujo del prototipo con datos devueltos por la API.
class CasaController extends ChangeNotifier {
  final ApiClient api;
  Timer? _notificationsTimer;
  bool _polling = false;
  Row? operation;
  List<Row> notifications = [], users = [], catalog = [], history = [];
  int unread = 0;
  num? agreedPrice, agreedInitial;
  int? agreedCount;
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
    _notificationsTimer?.cancel();
    _notificationsTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => pollNotifications(),
    );
    go('home');
  }

  Future<void> refresh() async {
    projects = rows(await api.call('GET', '/projects'));
    clients = rows(await api.call('GET', '/clients'));
    reservations = rows(await api.call('GET', '/reservations'));
    await pollNotifications();
  }

  Future<void> pollNotifications() async {
    if (_polling || api.token == null) return;
    _polling = true;
    try {
      final data = await api.call('GET', '/notifications');
      notifications = rows(data['items']);
      unread = (data['pendientes'] as num).toInt();
      notifyListeners();
    } catch (e) {
      if (e is ApiException && e.status == 401) clear();
    } finally {
      _polling = false;
    }
  }

  @override
  void dispose() {
    _notificationsTimer?.cancel();
    super.dispose();
  }

  Future<void> logout() async {
    try {
      await api.call('POST', '/auth/logout');
    } finally {
      clear();
    }
  }

  void clear() {
    _notificationsTimer?.cancel();
    notifications = [];
    users = [];
    catalog = [];
    history = [];
    unread = 0;
    operation = null;
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
    agreedPrice = null;
    agreedInitial = null;
    agreedCount = null;
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
    if (input['quitar_cotitular'] == true) {
      await api.call('DELETE', '/clients/${selectedClient!['id']}/cotitular');
      selectedClient!.remove('cotitular');
    }
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
    go('client-form');
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
        if (agreedPrice != null) 'precio_acordado': agreedPrice,
        if (agreedInitial != null) 'inicial_acordada': agreedInitial,
        if (agreedCount != null) 'numero_cuotas_acordado': agreedCount,
        if (lot!['version'] != null) 'version_catalogo': lot!['version'],
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
