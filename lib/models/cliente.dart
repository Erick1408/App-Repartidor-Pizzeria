// lib/models/cliente.dart
class Cliente {
  final int? id;
  final String nombre;
  final String? telefono;
  final String? direccion;

  Cliente({
    this.id,
    required this.nombre,
    this.telefono,
    this.direccion,
  });

  factory Cliente.fromJson(dynamic json) {
    if (json == null) return Cliente(nombre: 'Cliente');

    final map = Map<String, dynamic>.from(json as Map);

    return Cliente(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
      nombre: (map['nombre'] ??
              map['nombre_completo'] ??
              map['cliente'] ??
              'Cliente')
          .toString(),
      telefono: (map['telefono'] ??
              map['phone'] ??
              map['celular'] ??
              map['movil'])
          ?.toString(),
      direccion: (map['direccion'] ??
              map['direccion_entrega'] ??
              map['address'])
          ?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'nombre': nombre,
        if (telefono != null) 'telefono': telefono,
        if (direccion != null) 'direccion': direccion,
      };
}
