import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int status;
  ApiException(this.message, [this.status = 0]);
  @override
  String toString() => message;
}

/// Cliente REST inyectable. El token se mantiene solo en memoria.
class ApiClient {
  final http.Client client;
  String baseUrl;
  String? token;
  ApiClient(this.baseUrl, {http.Client? client})
    : client = client ?? http.Client();
  Uri uri(String path) {
    final base = Uri.parse(baseUrl);
    if (!['http', 'https'].contains(base.scheme) || base.host.isEmpty) {
      throw ApiException('Ingresa una dirección de servidor válida.');
    }
    return base.resolve('/api$path');
  }

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
  Future<dynamic> call(
    String method,
    String path, [
    Map<String, dynamic>? data,
  ]) async {
    try {
      final request = http.Request(method, uri(path))..headers.addAll(headers);
      if (data != null) request.body = jsonEncode(data);
      final response = await http.Response.fromStream(
        await client.send(request).timeout(const Duration(seconds: 25)),
      );
      check(response);
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'No se pudo conectar. Revisa el servidor e inténtalo de nuevo.',
      );
    }
  }

  void check(http.Response response) {
    if (response.statusCode >= 400) {
      String message = 'No fue posible completar la operación.';
      try {
        message =
            jsonDecode(utf8.decode(response.bodyBytes))['message'] ?? message;
      } catch (_) {}
      if (response.statusCode == 401) token = null;
      throw ApiException(message, response.statusCode);
    }
  }

  Future<Uint8List> bytes(String path) async {
    final response = await client
        .get(uri(path), headers: headers)
        .timeout(const Duration(seconds: 25));
    check(response);
    return response.bodyBytes;
  }

  Future<void> upload(
    int clientId,
    String side,
    Uint8List bytes,
    String name,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      uri('/clients/$clientId/documents/$side'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: name),
    );
    final response = await http.Response.fromStream(
      await client.send(request).timeout(const Duration(seconds: 30)),
    );
    check(response);
  }
}
