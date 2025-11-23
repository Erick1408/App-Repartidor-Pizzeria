// lib/models/producto.dart
class Producto {
  final int? id;
  final String nombre;
  final int cantidad;
  final Map<String, dynamic>? personalizaciones;

  Producto({
    this.id,
    required this.nombre,
    required this.cantidad,
    this.personalizaciones,
  });

  factory Producto.fromJson(dynamic json) {
    if (json == null) return Producto(nombre: 'Producto', cantidad: 1);

    final map = Map<String, dynamic>.from(json as Map);

    // Nombre puede venir en distintas claves
    final rawProducto = map['producto'];
    final nombre = rawProducto is Map
        ? (rawProducto['nombre'] ?? 'Producto').toString()
        : (map['nombre'] ?? 'Producto').toString();

    // Cantidad = cantidad | qty
    int qty = 1;
    if (map['cantidad'] != null) {
      qty = int.tryParse(map['cantidad'].toString()) ?? qty;
    }
    if (map['qty'] != null) {
      qty = int.tryParse(map['qty'].toString()) ?? qty;
    }

    // Personalizaciones
    Map<String, dynamic>? personal;
    if (map['personalizaciones'] is Map) {
      personal = Map<String, dynamic>.from(map['personalizaciones']);
    } else if (map['personal'] is Map) {
      personal = Map<String, dynamic>.from(map['personal']);
    }

    return Producto(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
      nombre: nombre,
      cantidad: qty,
      personalizaciones: personal,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'nombre': nombre,
        'cantidad': cantidad,
        if (personalizaciones != null) 'personalizaciones': personalizaciones,
      };
}
