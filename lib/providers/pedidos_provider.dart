// lib/providers/pedidos_provider.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../controllers/api_service.dart';
import '../models/pedido.dart';

class PedidosProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  List<Pedido> pedidos = [];
  bool loading = false;

  bool authenticated = false;
  String? lastError;

  // -----------------------------------------------------------
  // findById: retorna un Pedido cacheado si existe (o null)
  // -----------------------------------------------------------
  Pedido? findById(int id) {
    try {
      return pedidos.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // -----------------------------------------------------------
  // LOGIN
  // -----------------------------------------------------------
  Future<bool> login(String email, String password) async {
    final base = 'https://backend-pizzeria-production.up.railway.app/api';
    final url = Uri.parse('$base/auth/login');

    try {
      final resp = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: json.encode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 12));

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);

        // Token puede venir en body
        String? token;
        if (body is Map && body['token'] != null) token = body['token']?.toString();

        // O puede venir en cookie (set-cookie)
        if ((token == null || token.isEmpty) && resp.headers['set-cookie'] != null) {
          final raw = resp.headers['set-cookie']!;
          final m = RegExp(r'token=([^;]+)').firstMatch(raw);
          token = m?.group(1);
        }

        if (token != null && token.isNotEmpty) {
          await _api.saveToken(token);
          authenticated = true;
          lastError = null;
          notifyListeners();

          // carga pedidos después del login
          await cargarPedidos();
          return true;
        } else {
          lastError = 'Token no recibido del servidor';
          return false;
        }
      } else {
        // error desde backend
        String msg = 'Credenciales incorrectas';
        try {
          final body = json.decode(resp.body);
          msg = (body['mensaje'] ?? body['message'] ?? msg).toString();
        } catch (_) {}
        lastError = msg;
        return false;
      }
    } on SocketException {
      lastError = 'Sin conexión a internet';
      return false;
    } catch (e) {
      lastError = e.toString();
      if (kDebugMode) debugPrint('login exception: $e');
      return false;
    }
  }

  // -----------------------------------------------------------
  // LOGOUT
  // -----------------------------------------------------------
  Future<void> logout() async {
    await _api.clearToken();
    authenticated = false;
    pedidos = [];
    lastError = null;
    notifyListeners();
  }

  // -----------------------------------------------------------
  // CARGAR PEDIDOS (manejo de 401)
  // -----------------------------------------------------------
  Future<void> cargarPedidos() async {
    loading = true;
    lastError = null;
    notifyListeners();

    try {
      final raw = await _api.obtenerPedidos(); // puede lanzar ApiException
      final list = (raw ?? []) as List<dynamic>;
      pedidos = list.map<Pedido>((e) => Pedido.fromJson(e)).toList();
    } on ApiException catch (e) {
      if (e.status == 401) {
        // Token inválido -> forzar logout local y notificar UI
        await _api.clearToken();
        authenticated = false;
        pedidos = [];
        lastError = 'Sesión expirada. Por favor inicia sesión de nuevo.';
        notifyListeners();
        return;
      } else {
        lastError = e.message;
      }
    } on SocketException {
      lastError = 'Sin conexión a internet';
      pedidos = [];
    } catch (e) {
      lastError = e.toString();
      pedidos = [];
      if (kDebugMode) debugPrint('cargarPedidos error: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // -----------------------------------------------------------
  // DETALLE DE PEDIDO (manejo de 401)
  // -----------------------------------------------------------
  Future<Pedido?> obtenerPedidoDetalle(int id) async {
    try {
      // intenta desde cache primero
      final local = findById(id);
      if (local != null) return local;

      // si no está, pide al backend
      final raw = await _api.obtenerPedidoPorId(id);
      if (raw == null) return null;
      return Pedido.fromJson(raw);
    } on ApiException catch (e) {
      if (e.status == 401) {
        await _api.clearToken();
        authenticated = false;
        lastError = 'Sesión expirada. Por favor inicia sesión de nuevo.';
        notifyListeners();
        return null;
      }
      if (kDebugMode) debugPrint('obtenerPedidoDetalle ApiException: ${e.message}');
      return null;
    } on SocketException {
      lastError = 'Sin conexión a internet';
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('obtenerPedidoDetalle error: $e');
      return null;
    }
  }

  // -----------------------------------------------------------
  // CAMBIAR ESTADO (manejo de 401)
  // -----------------------------------------------------------
  Future<bool> cambiarEstado(int pedidoId, int estadoId) async {
    try {
      final ok = await _api.actualizarEstadoPedido(pedidoId, estadoId);
      if (ok) await cargarPedidos();
      return ok;
    } on ApiException catch (e) {
      if (e.status == 401) {
        await _api.clearToken();
        authenticated = false;
        lastError = 'Sesión expirada. Por favor inicia sesión de nuevo.';
        notifyListeners();
        return false;
      }
      if (kDebugMode) debugPrint('cambiarEstado ApiException: ${e.message}');
      return false;
    } on SocketException {
      lastError = 'Sin conexión a internet';
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('cambiarEstado error: $e');
      return false;
    }
  }

  // -----------------------------------------------------------
  // ESTADOS LOCALES
  // -----------------------------------------------------------
  List<Map<String, dynamic>> estadosLocal() {
    return _api.obtenerEstadosLocal();
  }
}
