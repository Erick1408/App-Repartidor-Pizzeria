// lib/controllers/api_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiException implements Exception {
  final int? status;
  final String message;
  ApiException(this.status, this.message);
  @override
  String toString() => 'ApiException($status): $message';
}

class ApiService {
  ApiService._internal();
  static final ApiService instance = ApiService._internal();

  // Mantengo tu base URL original
  final String _serverBaseUrl = 'https://backend-pizzeria-production.up.railway.app/api';
  final Duration _timeout = const Duration(seconds: 12);

  // Secure storage (encrypted)
  static const _secureStorageKey = 'token';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // ------------------------------------------------------------------
  // Token & headers (incluye cookie si existiera)
  // ------------------------------------------------------------------
  Future<String?> _getToken() async {
    try {
      return await _secureStorage.read(key: _secureStorageKey);
    } catch (e) {
      if (kDebugMode) debugPrint('Error leyendo token seguro: $e');
      return null;
    }
  }

  Future<Map<String, String>> _headers({bool jsonBody = false}) async {
    final token = await _getToken();

    final headers = <String, String>{
      "Accept": "application/json",
    };

    if (token != null && token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
      headers["Cookie"] = "token=$token";
    }

    if (jsonBody) {
      headers["Content-Type"] = "application/json";
    }

    return headers;
  }

  // ------------------------------------------------------------------
  // Helpers HTTP
  // ------------------------------------------------------------------
  Uri _uri(String path) => Uri.parse("$_serverBaseUrl$path");

  Future<http.Response> _getResponse(Uri uri, Map<String, String> headers) {
    return http.get(uri, headers: headers).timeout(_timeout);
  }

  Future<http.Response> _postResponse(Uri uri, Map<String, String> headers, String body) {
    return http.post(uri, headers: headers, body: body).timeout(_timeout);
  }

  Future<http.Response> _putResponse(Uri uri, Map<String, String> headers, String body) {
    return http.put(uri, headers: headers, body: body).timeout(_timeout);
  }

  // ------------------------------------------------------------------
  // Funciones específicas
  // ------------------------------------------------------------------

  /// GET /pedido -> devuelve lista flexible (puede venir lista o map con data/pedidos)
  Future<List<dynamic>> obtenerPedidos() async {
    debugPrint("→ GET /pedido");

    try {
      final resp = await _getResponse(_uri("/pedido"), await _headers());
      debugPrint("STATUS: ${resp.statusCode}");
      debugPrint("BODY: ${resp.body}");

      final processed = _process(resp); // puede lanzar ApiException
      if (processed is List) return processed;
      if (processed is Map) {
        if (processed["data"] is List) return processed["data"];
        if (processed["pedidos"] is List) return processed["pedidos"];
        for (final e in processed.entries) {
          if (e.value is List) return e.value;
        }
      }
    } on SocketException {
      debugPrint("obtenerPedidos: sin conexión");
      rethrow;
    }
    return [];
  }

  /// GET /pedido/{id} -> devuelve map con estructura flexible
  Future<Map<String, dynamic>?> obtenerPedidoPorId(int id) async {
    debugPrint("→ GET /pedido/$id");

    try {
      final resp = await _getResponse(_uri("/pedido/$id"), await _headers());
      debugPrint("STATUS: ${resp.statusCode}");
      debugPrint("BODY: ${resp.body}");

      final processed = _process(resp); // puede lanzar ApiException
      if (processed is Map) {
        final map = Map<String, dynamic>.from(processed);
        if (map["pedido"] is Map) return Map<String, dynamic>.from(map["pedido"]);
        if (map["data"] is Map) return Map<String, dynamic>.from(map["data"]);
        return map;
      }
    } on SocketException {
      debugPrint("obtenerPedidoPorId: sin conexión");
      rethrow;
    }
    return null;
  }

  /// PUT /pedido/{id}/estado
  Future<bool> actualizarEstadoPedido(int id, int estadoId) async {
    debugPrint("→ PUT /pedido/$id/estado  (id_estado=$estadoId)");
    try {
      final resp = await _putResponse(_uri("/pedido/$id/estado"), await _headers(jsonBody: true), json.encode({"id_estado": estadoId}));
      debugPrint("STATUS: ${resp.statusCode}");
      debugPrint("BODY: ${resp.body}");
      _process(resp); // si no lanza excepción, ok
      return true;
    } on SocketException {
      debugPrint("actualizarEstadoPedido: sin conexión");
      rethrow;
    } catch (e) {
      debugPrint("actualizarEstadoPedido: excepción -> $e");
      rethrow;
    }
  }

  /// Lista estática de estados
  List<Map<String, dynamic>> obtenerEstadosLocal() {
    return [
      {'id': 1, 'nombre': 'Pendiente'},
      {'id': 2, 'nombre': 'Pagado'},
      {'id': 3, 'nombre': 'Preparando'},
      {'id': 4, 'nombre': 'En camino'},
      {'id': 5, 'nombre': 'Entregado'},
    ];
  }

  // ------------------------------------------------------------------
  // Storage seguro para token
  // ------------------------------------------------------------------
  Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(key: _secureStorageKey, value: token);
      debugPrint("Token guardado de forma segura.");
    } catch (e) {
      debugPrint("Error guardando token seguro: $e");
    }
  }

  Future<void> clearToken() async {
    try {
      await _secureStorage.delete(key: _secureStorageKey);
      debugPrint("Token eliminado del almacenamiento seguro.");
    } catch (e) {
      debugPrint("Error eliminando token seguro: $e");
    }
  }

  // ------------------------------------------------------------------
  // Proceso común de respuestas: decodificar y lanzar ApiException si procede
  // ------------------------------------------------------------------
  dynamic _process(http.Response resp) {
    final code = resp.statusCode;
    final body = resp.body;
    if (code >= 200 && code < 300) {
      if (body.isEmpty) return null;
      try {
        return json.decode(body);
      } catch (_) {
        return body;
      }
    }

    // Si es 401 -> borrar token local porque ya no sirve y lanzar excepción
    if (code == 401) {
      // limpiar token de forma segura (no await para no bloquear)
      clearToken();
      throw ApiException(401, 'No autorizado: token inválido');
    }

    String message = 'Error $code';
    try {
      final parsed = json.decode(body);
      if (parsed is Map && (parsed['message'] ?? parsed['mensaje'] ?? parsed['error']) != null) {
        message = (parsed['message'] ?? parsed['mensaje'] ?? parsed['error']).toString();
      } else {
        message = body;
      }
    } catch (_) {
      message = body;
    }
    throw ApiException(code, message);
  }
}

