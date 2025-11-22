// lib/view/pedido_detalle.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/data_base_helper.dart';

class PedidoDetalle extends StatefulWidget {
  final int pedidoId;
  const PedidoDetalle({required this.pedidoId, super.key});

  @override
  State<PedidoDetalle> createState() => _PedidoDetalleState();
}

class _PedidoDetalleState extends State<PedidoDetalle> {
  final DataBaseHelper db = DataBaseHelper();
  Map<String, dynamic>? pedido;
  List<Map<String, dynamic>> estados = [];
  int? estadoActual;
  bool cargando = true;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => cargando = true);
    final p = await db.obtenerPedidoPorId(widget.pedidoId);
    final listaEstados = db.obtenerEstadosLocal();

    int? current;
    if (p != null) {
      if (p['id_estado'] != null) {
        current = p['id_estado'] is int ? p['id_estado'] : int.tryParse(p['id_estado'].toString());
      } else if (p['estado'] is Map && p['estado']['id'] != null) {
        current = p['estado']['id'] is int ? p['estado']['id'] : int.tryParse(p['estado']['id'].toString());
      }
    }

    setState(() {
      pedido = p != null ? Map<String, dynamic>.from(p) : null;
      estados = List<Map<String, dynamic>>.from(listaEstados);
      estadoActual = current;
      cargando = false;
    });
  }

  /// Devuelve el siguiente estado permitido para el repartidor o null si no hay.
  /// regla:
  /// - si estadoActual < 4 => next = 4 (En camino)
  /// - si estadoActual == 4 => next = 5 (Entregado)
  /// - si estadoActual >= 5 => null
  Map<String, dynamic>? _nextStateForRepartidor() {
    if (estadoActual == null) return null;
    if (estadoActual! < 4) {
      final found = estados.where((e) => e['id'] == 4);
      return found.isNotEmpty ? found.first : null;
    } else if (estadoActual == 4) {
      final found = estados.where((e) => e['id'] == 5);
      return found.isNotEmpty ? found.first : null;
    } else {
      return null;
    }
  }

  Future<void> _advanceState() async {
    final next = _nextStateForRepartidor();
    if (next == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay cambio de estado permitido.')));
      return;
    }
    final nextId = next['id'] as int;
    final nextName = next['nombre']?.toString() ?? nextId.toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar cambio de estado'),
        content: Text('¿Deseas marcar el pedido como "$nextName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => guardando = true);
    final ok = await db.actualizarEstadoPedido(widget.pedidoId, nextId);
    setState(() => guardando = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Estado cambiado a "$nextName"')));
      await _cargar();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al actualizar estado')));
    }
  }

  Future<void> _openMaps() async {
    if (pedido == null) return;
    final lat = pedido!['latitud'] ?? pedido!['latitude'] ?? pedido!['lat'];
    final lng = pedido!['longitud'] ?? pedido!['longitude'] ?? pedido!['lng'];

    String uri;
    if (lat != null && lng != null) {
      uri = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    } else {
      final address = Uri.encodeComponent(pedido!['direccion'] ?? pedido!['direccion_entrega'] ?? pedido!['address'] ?? '');
      uri = 'https://www.google.com/maps/search/?api=1&query=$address';
    }

    final url = Uri.parse(uri);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir Maps')));
    }
  }

  Future<void> _callClient() async {
    if (pedido == null) return;
    final phone = pedido!['cliente']?['telefono'] ?? pedido!['cliente']?['telefono_celular'] ?? pedido!['cliente']?['phone'];
    if (phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teléfono no disponible')));
      return;
    }
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
    else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo iniciar la llamada')));
  }

  Widget _productTile(Map<String, dynamic> det) {
    final nombre = det['producto']?['nombre'] ?? det['nombre'] ?? 'Producto';
    final qty = det['cantidad'] ?? det['qty'] ?? 1;
    final personal = det['personalizaciones'] ?? det['personal'] ?? {};
    final tamano = (personal is Map) ? (personal['id_tamano'] ?? personal['tamano'] ?? '') : '';
    final ingredientes = (personal is Map) ? (personal['ingredientes'] ?? []) : [];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(nombre.toString(), style: const TextStyle(fontWeight: FontWeight.w600))), Text('x$qty')]),
        if (tamano != null && tamano.toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Tamaño: $tamano', style: const TextStyle(color: Colors.black54))),
        if (ingredientes is List && ingredientes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              children: ingredientes.map<Widget>((ing) {
                final ingName = ing['nombre'] ?? ing['id_ingrediente']?.toString() ?? ing.toString();
                final ingQty = ing['cantidad'] ?? '';
                return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)), child: Text('${ingName.toString()} ${ingQty != '' ? 'x$ingQty' : ''}'));
              }).toList(),
            ),
          ),
      ]),
    );
  }

  String? _lookupEstadoNombre(int? id) {
    if (id == null) return null;
    try {
      final found = estados.firstWhere((e) => e['id'] == id, orElse: () => {});
      return (found['nombre']?.toString());
    } catch (_) {
      return id.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Pedido #${widget.pedidoId}'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          actions: [
            IconButton(onPressed: _openMaps, icon: const Icon(Icons.map)),
            IconButton(onPressed: _callClient, icon: const Icon(Icons.call)),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (pedido == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Pedido #${widget.pedidoId}')),
        body: const Center(child: Text('No se pudo cargar el pedido')),
      );
    }

    final cliente = pedido!['cliente']?['nombre'] ?? 'Cliente';
    final direccion = pedido!['direccion'] ?? pedido!['direccion_entrega'] ?? pedido!['address'] ?? '';
    final detalles = (pedido!['detalles'] is List) ? List<Map<String, dynamic>>.from(pedido!['detalles']) : [];
    final next = _nextStateForRepartidor();

    // Build nextButton label and disabled status
    String nextLabel = '';
    bool buttonEnabled = false;
    if (next != null && next.isNotEmpty) {
      nextLabel = 'Marcar como ${next['nombre'] ?? next['id'].toString()}';
      buttonEnabled = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido #${widget.pedidoId}', style: const TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(onPressed: _openMaps, icon: const Icon(Icons.map)),
          IconButton(onPressed: _callClient, icon: const Icon(Icons.call)),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cliente.toString(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Text(direccion.toString(), style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 8),
            if (pedido!['cliente']?['telefono'] != null) Text('Tel: ${pedido!['cliente']?['telefono']}', style: const TextStyle(color: Colors.black54)),
          ]),
        ),
        const SizedBox(height: 12),
        const Text('Productos', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (detalles.isEmpty) const Text('No hay productos.')
        else ...detalles.map((d) => _productTile(Map<String, dynamic>.from(d))).toList(),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 8),
        const Text('Estado', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),

        // Estado actual - chip centrado
        Center(
          child: Chip(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            label: Text(
              _lookupEstadoNombre(estadoActual) ?? '—',
              style: const TextStyle(fontSize: 14),
            ),
            backgroundColor: Colors.grey.shade200,
          ),
        ),

        const SizedBox(height: 16),

        // Botón centrado y con ancho fijo para evitar overflow
        Center(
          child: SizedBox(
            width: 220,
            child: ElevatedButton(
              onPressed: (buttonEnabled && !guardando) ? _advanceState : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonEnabled ? Colors.black87 : Colors.grey.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      nextLabel.isNotEmpty ? nextLabel : 'Sin acciones',
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
        ),

        const SizedBox(height: 24),
      ]),
    );
  }
}


