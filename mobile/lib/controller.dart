import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api.dart';
import 'listing_filter.dart';
import 'session_store.dart';
import 'platform_io.dart' as platform;

typedef Row = Map<String, dynamic>;

/// Coordina el flujo del prototipo con datos devueltos por la API.
class CasaController extends ChangeNotifier {
  final ApiClient api;
  Timer? _notificationsTimer;
  bool _polling = false;
  Row? operation;
  List<Row> notifications = [], users = [], catalog = [], history = [];
  int unread = 0;
  String clientMonth = businessMonth(),
      operationMonth = businessMonth(),
      historyMonth = businessMonth();
  String clientCategory = '', operationState = '', historyEntity = '';
  int? historyUser;
  List<Row> listedClients = [], listedOperations = [], historyUsers = [];
  int _clientLoad = 0, _operationLoad = 0, _historyLoad = 0;
  Future<void> loadClients() async {
    final serial = ++_clientLoad;
    final value = rows(
      await api.call(
        'GET',
        listingUrl('/clients', {
          'month': clientMonth,
          'category': clientCategory,
        }),
      ),
    );
    if (serial == _clientLoad) {
      listedClients = value;
      notifyListeners();
    }
  }

  Future<void> loadOperations() async {
    final serial = ++_operationLoad;
    final value = rows(
      await api.call(
        'GET',
        listingUrl('/reservations', {
          'month': operationMonth,
          'state': operationState,
        }),
      ),
    );
    if (serial == _operationLoad) {
      listedOperations = value;
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    final serial = ++_historyLoad;
    final value = rows(
      await api.call(
        'GET',
        listingUrl('/admin/history', {
          'month': historyMonth,
          'entity': historyEntity,
          'action': historyAction,
          'user': historyUser?.toString() ?? '',
        }),
      ),
    );
    if (serial == _historyLoad) {
      history = value;
      notifyListeners();
    }
  }

  num? agreedPrice, agreedInitial;
  int? agreedCount;
  final SessionStore sessionStore;
  CasaController(this.api, {SessionStore? sessionStore})
    : sessionStore = sessionStore ?? SessionStore();
  Row dashboard = {};
  String dashboardMonth = businessMonth(),
      dashboardSection = 'general',
      historyAction = '';
  int? dashboardUser, dashboardProject;
  int _dashboardLoad = 0;
  Future<void> loadDashboard() async {
    final serial = ++_dashboardLoad;
    final data = Row.from(
      await api.call(
        'GET',
        listingUrl('/dashboard', {
          'month': dashboardMonth,
          'user': dashboardUser?.toString() ?? '',
          'project': dashboardProject?.toString() ?? '',
        }),
      ),
    );
    if (serial == _dashboardLoad) {
      dashboard = data;
      notifyListeners();
    }
  }

  Future<void> restoreSession() async {
    if (!kIsWeb) {
      final base = await platform.readSetting('server');
      if (base != null && base.isNotEmpty) api.baseUrl = base;
    }
    final saved = await sessionStore.read();
    if (saved == null) return;
    final expires = DateTime.tryParse('${saved['expires']}');
    if (saved['base'] != api.baseUrl ||
        expires == null ||
        !expires.isAfter(DateTime.now())) {
      await sessionStore.clear();
      return;
    }
    api.token = saved['token'] as String?;
    try {
      user = Row.from(await api.call('GET', '/auth/me'));
      await refresh();
      _startPolling();
      go('home');
    } catch (e) {
      api.token = null;
      user = null;
      if (e is ApiException && e.status == 401) await sessionStore.clear();
    }
  }

  void _startPolling() {
    _notificationsTimer?.cancel();
    _notificationsTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => pollNotifications(),
    );
  }

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
  Future<void> login(
    String email,
    String password, {
    bool remember = false,
  }) async {
    await sessionStore.clear();
    final data = await api.call('POST', '/auth/login', {
      'email': email,
      'password': password,
      'remember': remember,
    });
    api.token = data['token'];
    user = Map<String, dynamic>.from(data['user']);
    await refresh();
    if (remember) {
      await sessionStore.save(
        api.baseUrl,
        api.token!,
        data['expires'] as String,
      );
    }
    _startPolling();
    go('home');
  }

  Future<void> refresh() async {
    final data = await Future.wait([
      api.call('GET', '/projects'),
      api.call('GET', '/clients'),
      api.call('GET', '/reservations'),
    ]);
    projects = rows(data[0]);
    clients = rows(data[1]);
    reservations = rows(data[2]);
    await Future.wait([loadClients(), loadOperations()]);
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
    unawaited(sessionStore.clear());
    ++_dashboardLoad;
    dashboard = {};
    dashboardMonth = businessMonth();
    dashboardSection = 'general';
    dashboardUser = null;
    dashboardProject = null;
    historyAction = '';
    _notificationsTimer?.cancel();
    ++_clientLoad;
    ++_operationLoad;
    ++_historyLoad;
    listedClients = [];
    listedOperations = [];
    historyUsers = [];
    clientMonth = operationMonth = historyMonth = businessMonth();
    clientCategory = operationState = historyEntity = '';
    historyUser = null;
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

  Future<void> reserve(num amount, String observation, {int? days}) async {
    result = Map<String, dynamic>.from(
      await api.call('POST', '/reservations', {
        'lote_id': lot!['id'],
        'cliente_id': selectedClient!['id'],
        'monto': amount,
        'plazo_dias': ?days,
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
