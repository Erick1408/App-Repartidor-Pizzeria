// lib/models/pedido.dart
import 'dart:convert';
import 'cliente.dart';

num? _parseNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) {
    final s = value.trim();
    if (s.isEmpty) return null;
    final normalized = s.replaceAll(',', '.').replaceAll(RegExp(r'[^\d\.\-]'), '');
    return num.tryParse(normalized);
  }
  return null;
}

// --------------------------------------------------------------
// DETALLE
// --------------------------------------------------------------
class Detalle {
  final int? id;
  final String? nombre;
  final num? precio;
  final int? cantidad;
  final Map<String, dynamic>? personalizaciones;

  Detalle({
    this.id,
    this.nombre,
    this.precio,
    this.cantidad,
    this.personalizaciones,
  });

  factory Detalle.fromJson(Map<String, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);

    // ---------------------------
    // 1. PRODUCTO COMO MAP
    // ---------------------------
    if (json["producto"] is Map) {
      final p = Map<String, dynamic>.from(json["producto"]);

      return Detalle(
        id: p["id"] is int ? p["id"] : int.tryParse(p["id"]?.toString() ?? ""),
        nombre: (p["nombre"] ?? p["name"] ?? "Producto").toString(),
        precio: _parseNum(p["precio"] ?? p["valor"] ?? p["price"]),
        cantidad: json["cantidad"] is int
            ? json["cantidad"]
            : int.tryParse(json["cantidad"]?.toString() ?? "1") ?? 1,
        personalizaciones: p["personalizaciones"] is Map
            ? Map<String, dynamic>.from(p["personalizaciones"])
            : null,
      );
    }

    // ---------------------------
    // 2. PRODUCTO COMO STRING NORMAL (ej. "Pizza Hawaiana")
    // ---------------------------
    if (json["producto"] is String &&
        !(json["producto"] as String).contains("{")) {
      final nombre = json["producto"].toString();

      return Detalle(
        id: json["id"] is int ? json["id"] : int.tryParse(json["id"]?.toString() ?? ""),
        nombre: nombre,
        precio: _parseNum(json["precio"] ?? json["valor"] ?? json["amount"]),
        cantidad: json["cantidad"] is int
            ? json["cantidad"]
            : int.tryParse(json["cantidad"]?.toString() ?? "1") ?? 1,
        personalizaciones: json["personalizaciones"] is Map
            ? Map<String, dynamic>.from(json["personalizaciones"])
            : null,
      );
    }

    // ---------------------------
    // 3. NOMBRE DIRECTO
    // ---------------------------
    final nombre = json["nombre"]?.toString() ??
        json["name"]?.toString() ??
        json["producto"]?.toString();

    // ---------------------------
    // 4. PRODUCTO COMO STRING MAP (ej. "{id:2,...}")
    // Intentar decodificar si es JSON REAL, no MAP-string pobre
    // ---------------------------
    if (nombre != null &&
        nombre.startsWith("{") &&
        nombre.endsWith("}")) {
      try {
        final decoded = jsonDecode(nombre);
        if (decoded is Map && decoded["nombre"] != null) {
          return Detalle(
            id: decoded["id"] is int
                ? decoded["id"]
                : int.tryParse(decoded["id"]?.toString() ?? ""),
            nombre: decoded["nombre"].toString(),
            precio: _parseNum(decoded["precio"]),
            cantidad: decoded["cantidad"] is int
                ? decoded["cantidad"]
                : int.tryParse(decoded["cantidad"]?.toString() ?? "1") ?? 1,
            personalizaciones: decoded["personalizaciones"] is Map
                ? Map<String, dynamic>.from(decoded["personalizaciones"])
                : null,
          );
        }
      } catch (_) {
        // No es JSON real → seguimos abajo
      }
    }

    // ---------------------------
    // 5. CASO PLANO FINAL
    // ---------------------------
    return Detalle(
      id: json["id"] is int ? json["id"] : int.tryParse(json["id"]?.toString() ?? ""),
      nombre: nombre ?? "Producto",
      precio: _parseNum(json["precio"] ?? json["valor"] ?? json["price"]),
      cantidad: json["cantidad"] is int
          ? json["cantidad"]
          : int.tryParse(json["cantidad"]?.toString() ?? "1") ?? 1,
      personalizaciones: json["personalizaciones"] is Map
          ? Map<String, dynamic>.from(json["personalizaciones"])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) "id": id,
      "nombre": nombre,
      "precio": precio,
      "cantidad": cantidad,
      "personalizaciones": personalizaciones,
    };
  }
}

// --------------------------------------------------------------
// PEDIDO
// --------------------------------------------------------------
class Pedido {
  final int? id;
  final Cliente cliente;
  final String? direccion;
  final num? total;
  final int? idEstado;
  final List<Detalle> detalles;
  final String? fecha;

  Pedido({
    this.id,
    required this.cliente,
    this.direccion,
    this.total,
    this.idEstado,
    this.detalles = const [],
    this.fecha,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    // Cliente
    Cliente cliente;
    if (json["cliente"] is Map) {
      cliente = Cliente.fromJson(Map<String, dynamic>.from(json["cliente"]));
    } else if (json["user"] is Map) {
      cliente = Cliente.fromJson(Map<String, dynamic>.from(json["user"]));
    } else {
      cliente = Cliente(
        id: null,
        nombre: (json["nombre_cliente"] ??
                json["cliente_nombre"] ??
                json["name"] ??
                "Cliente")
            .toString(),
      );
    }

    // Detalles
    List<Detalle> detalles = [];
    final rawDetalles = json["detalles"] ?? json["productos"];
    if (rawDetalles is List) {
      for (final item in rawDetalles) {
        if (item is Map) {
          detalles.add(Detalle.fromJson(Map<String, dynamic>.from(item)));
        } else if (item is String) {
          try {
            final decoded = jsonDecode(item);
            if (decoded is Map) {
              detalles.add(Detalle.fromJson(Map<String, dynamic>.from(decoded)));
            } else {
              detalles.add(Detalle(nombre: item, cantidad: 1));
            }
          } catch (_) {
            detalles.add(Detalle(nombre: item, cantidad: 1));
          }
        } else {
          detalles.add(Detalle(nombre: item.toString(), cantidad: 1));
        }
      }
    }

    return Pedido(
      id: json["id"] is int ? json["id"] : int.tryParse(json["id"]?.toString() ?? ""),
      cliente: cliente,
      direccion: (json["direccion"] ??
              json["direccion_entrega"] ??
              json["address"])
          ?.toString(),
      total: _parseNum(json["total"] ?? json["valor_total"] ?? json["amount_total"]),
      idEstado: json["id_estado"] is int
          ? json["id_estado"]
          : int.tryParse(json["estado"]?.toString() ?? json["status"]?.toString() ?? ""),
      detalles: detalles,
      fecha: json["fecha"]?.toString() ?? json["created_at"]?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "cliente": {
        "id": cliente.id,
        "nombre": cliente.nombre,
        "telefono": cliente.telefono,
      },
      "direccion": direccion,
      "total": total,
      "id_estado": idEstado,
      "detalles": detalles.map((d) => d.toJson()).toList(),
      "fecha": fecha,
    };
  }
}

