// lib/controllers/data_base_helper.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataBaseHelper {
  final String _serverBaseUrl = 'https://backend-pizzeria-production.up.railway.app/api';

  // Obtener token guardado
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Headers con Authorization y Cookie
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

  // ------------------------------------------------------------
  // GET /pedido → Listar pedidos
  // ------------------------------------------------------------
  Future<List<dynamic>> obtenerPedidos() async {
    debugPrint("→ GET /pedido");

    final resp = await http.get(
      Uri.parse("$_serverBaseUrl/pedido"),
      headers: await _headers(),
    );

    debugPrint("STATUS: ${resp.statusCode}");
    debugPrint("BODY: ${resp.body}");

    if (resp.statusCode != 200 || resp.body.isEmpty) {
      return [];
    }

    final decoded = json.decode(resp.body);

    if (decoded is List) return decoded;

    if (decoded is Map) {
      if (decoded["data"] is List) return decoded["data"];
      if (decoded["pedidos"] is List) return decoded["pedidos"];

      // Buscar la primera lista dentro del map
      for (final e in decoded.entries) {
        if (e.value is List) return e.value;
      }
    }

    return [];
  }

  // ------------------------------------------------------------
  // GET /pedido/{id}
  // ------------------------------------------------------------
  Future<Map<String, dynamic>?> obtenerPedidoPorId(int id) async {
    debugPrint("→ GET /pedido/$id");

    final resp = await http.get(
      Uri.parse("$_serverBaseUrl/pedido/$id"),
      headers: await _headers(),
    );

    debugPrint("STATUS: ${resp.statusCode}");
    debugPrint("BODY: ${resp.body}");

    if (resp.statusCode != 200 || resp.body.isEmpty) {
      return null;
    }

    final dynamic decoded = json.decode(resp.body);

    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);

      if (map["pedido"] is Map) {
        return Map<String, dynamic>.from(map["pedido"]);
      }

      if (map["data"] is Map) {
        return Map<String, dynamic>.from(map["data"]);
      }

      return map;
    }

    return null;
  }

  // ------------------------------------------------------------
  // PUT /pedido/{id}/estado
  // ------------------------------------------------------------
  Future<bool> actualizarEstadoPedido(int id, int estadoId) async {
    debugPrint("→ PUT /pedido/$id/estado  (id_estado=$estadoId)");

    final resp = await http.put(
      Uri.parse("$_serverBaseUrl/pedido/$id/estado"),
      headers: await _headers(jsonBody: true),
      body: json.encode({"id_estado": estadoId}),
    );

    debugPrint("STATUS: ${resp.statusCode}");
    debugPrint("BODY: ${resp.body}");

    return resp.statusCode == 200;
  }

  // ------------------------------------------------------------
  // Lista de estados (estáticos)
  // ------------------------------------------------------------
  List<Map<String, dynamic>> obtenerEstadosLocal() {
    return [
      {'id': 1, 'nombre': 'Pendiente'},
      {'id': 2, 'nombre': 'Pagado'},
      {'id': 3, 'nombre': 'Preparando'},
      {'id': 4, 'nombre': 'En camino'},
      {'id': 5, 'nombre': 'Entregado'},
    ];
  }

  // ------------------------------------------------------------
  // Borrar token
  // ------------------------------------------------------------
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    debugPrint("Token eliminado.");
  }
}
