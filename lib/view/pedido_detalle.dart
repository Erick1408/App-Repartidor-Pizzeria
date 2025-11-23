// lib/view/pedido_detalle.dart
<<<<<<< HEAD
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/pedido.dart';
import '../providers/pedidos_provider.dart';
import '../widgets/loading_indicator.dart';
=======
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/data_base_helper.dart';
>>>>>>> 6876e94f5c454d6a1ac15e072a89cc194d903b44

class PedidoDetalle extends StatefulWidget {
  final int pedidoId;
  const PedidoDetalle({required this.pedidoId, super.key});

  @override
  State<PedidoDetalle> createState() => _PedidoDetalleState();
}

class _PedidoDetalleState extends State<PedidoDetalle> {
<<<<<<< HEAD
  Pedido? pedido;
  bool loading = true;
  bool saving = false;
  String? errorMsg;

  // Lista normalizada usada por la UI (siempre Detalle)
  List<Detalle> detallesNormalizados = [];
=======
  final DataBaseHelper db = DataBaseHelper();
  Map<String, dynamic>? pedido;
  List<Map<String, dynamic>> estados = [];
  int? estadoActual;
  bool cargando = true;
  bool guardando = false;
>>>>>>> 6876e94f5c454d6a1ac15e072a89cc194d903b44

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    _load();
  }

  // -------------------------
  // Funciones de normalización
  // -------------------------
  num? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) {
      final s = value.trim();
      if (s.isEmpty) return null;
      final normalized = s.replaceAll(',', '.').replaceAll(RegExp(r'[^^\d\.\-]'), '');
      return num.tryParse(normalized);
    }
    return null;
  }

  Detalle _detalleFromDynamic(dynamic raw) {
    try {
      if (raw == null) return Detalle(nombre: 'Producto', cantidad: 1);

      // Si ya es Detalle
      if (raw is Detalle) return raw;

      // Si es String que contiene JSON
      if (raw is String) {
        // intentar parse JSON
        try {
          final decoded = json.decode(raw);
          if (decoded is Map) {
            return Detalle.fromJson(Map<String, dynamic>.from(decoded));
          } else {
            return Detalle(nombre: raw, cantidad: 1);
          }
        } catch (_) {
          // no es JSON: usar string como nombre
          return Detalle(nombre: raw, cantidad: 1);
        }
      }

      // Si es Map (puede venir Map<String,dynamic> o Map)
      if (raw is Map) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(raw);

        // Si el item está anidado dentro de 'producto', 'item' o 'detalle'
        if (map['producto'] is Map) return Detalle.fromJson(Map<String, dynamic>.from(map['producto']));
        if (map['item'] is Map) return Detalle.fromJson(Map<String, dynamic>.from(map['item']));
        if (map['detalle'] is Map) return Detalle.fromJson(Map<String, dynamic>.from(map['detalle']));

        // Si las claves están planas, construir un map reducido aceptable
        final m = <String, dynamic>{};

        // nombre
        if (map['nombre'] != null) m['nombre'] = map['nombre'];
        else if (map['name'] != null) m['nombre'] = map['name'];
        else if (map['producto'] != null && map['producto'] is String) m['nombre'] = map['producto'];

        // precio
        if (map['precio'] != null) m['precio'] = _parseNum(map['precio']);
        else if (map['price'] != null) m['precio'] = _parseNum(map['price']);
        else if (map['valor'] != null) m['precio'] = _parseNum(map['valor']);

        // cantidad
        if (map['cantidad'] != null) m['cantidad'] = (map['cantidad'] is int) ? map['cantidad'] : int.tryParse(map['cantidad'].toString()) ?? 1;
        else if (map['qty'] != null) m['cantidad'] = (map['qty'] is int) ? map['qty'] : int.tryParse(map['qty'].toString()) ?? 1;

        // id
        if (map['id'] != null) m['id'] = map['id'];

        // personalizaciones
        if (map['personalizaciones'] is Map) m['personalizaciones'] = Map<String, dynamic>.from(map['personalizaciones']);
        else if (map['personalizacion'] is Map) m['personalizaciones'] = Map<String, dynamic>.from(map['personalizacion']);

        // Si no encontramos nombre, fallback a toString de map
        if (m['nombre'] == null && map['toString'] == null) {
          m['nombre'] = map['nombre'] ?? map['name'] ?? map.values.join(' ');
        }

        return Detalle.fromJson(m);
      }
    } catch (e, st) {
      debugPrint('Error normalizando detalle: $e\n$st');
    }

    // fallback
    return Detalle(nombre: raw?.toString() ?? 'Producto', cantidad: 1);
  }

  // -------------------------
  // Carga y normalización
  // -------------------------
  Future<void> _load() async {
    setState(() => loading = true);
    final prov = Provider.of<PedidosProvider>(context, listen: false);
    try {
      final cached = prov.findById(widget.pedidoId);
      if (cached != null) {
        pedido = cached;
      } else {
        pedido = await prov.obtenerPedidoDetalle(widget.pedidoId);
      }

      // debug: imprimir tipo y contenido crudo de detalles
      if (pedido != null) {
        debugPrint('DEBUG: pedido.id=${pedido!.id}');
        debugPrint('DEBUG: pedido.detalles.runtimeType = ${pedido!.detalles.runtimeType}');
        for (var i = 0; i < pedido!.detalles.length; i++) {
          final raw = pedido!.detalles[i];
          debugPrint('DEBUG: raw detalle[$i] type=${raw.runtimeType} value= $raw');
        }

        // Normalizar y guardar en estado local
        detallesNormalizados = pedido!.detalles.map((d) => _detalleFromDynamic(d)).toList();

        // debug: imprimir normalizados
        for (var i = 0; i < detallesNormalizados.length; i++) {
          final dn = detallesNormalizados[i];
          debugPrint('DEBUG: normalized[$i] -> nombre="${dn.nombre}", cantidad=${dn.cantidad}, precio=${dn.precio}');
        }
      }
    } catch (e, st) {
      errorMsg = e.toString();
      debugPrint('ERROR cargando pedido detalle: $e\n$st');
    } finally {
      if (mounted) setState(() {
        loading = false;
      });
=======
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
>>>>>>> 6876e94f5c454d6a1ac15e072a89cc194d903b44
    }
  }

  Future<void> _callClient() async {
    if (pedido == null) return;
<<<<<<< HEAD
    final phone = pedido!.cliente.telefono;
    if (phone == null || phone.isEmpty) {
      if (!mounted) return;
=======
    final phone = pedido!['cliente']?['telefono'] ?? pedido!['cliente']?['telefono_celular'] ?? pedido!['cliente']?['phone'];
    if (phone == null) {
>>>>>>> 6876e94f5c454d6a1ac15e072a89cc194d903b44
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teléfono no disponible')));
      return;
    }
    final uri = Uri.parse('tel:$phone');
<<<<<<< HEAD
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo iniciar la llamada')));
    }
  }

  Map<String, dynamic>? _nextState(int? current, List<Map<String, dynamic>> estados) {
    if (current == null) return null;
    if (current < 4) return estados.firstWhere((e) => e['id'] == 4, orElse: () => {});
    if (current == 4) return estados.firstWhere((e) => e['id'] == 5, orElse: () => {});
    return null;
  }

  Future<void> _advanceState() async {
    if (pedido == null) return;
    final prov = Provider.of<PedidosProvider>(context, listen: false);
    final estados = prov.estadosLocal();
    final current = pedido!.idEstado;
    final next = _nextState(current, estados);
    if (next == null || next['id'] == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay cambio de estado permitido')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text('Marcar como "${next['nombre']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => saving = true);
    final ok = await prov.cambiarEstado(widget.pedidoId, next['id'] as int);
    setState(() => saving = false);

    if (ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Estado cambiado a "${next['nombre']}"')));
      await prov.cargarPedidos();
      await _load();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al actualizar estado')));
    }
  }

  // -------------------------
  // UI helpers
  // -------------------------
  String _formatTotal(num? value) {
    if (value == null) return '-';
    final val = (value as num).toDouble();
    return val % 1 == 0 ? '\$${val.toInt()}' : '\$${val.toStringAsFixed(2)}';
  }

  Widget _productTile(Detalle det, ThemeData theme) {
    final nombre = det.nombre ?? 'Producto';
    final qty = det.cantidad ?? 1;
    final precioStr = det.precio != null ? _formatTotal(det.precio) : '';
    final personal = det.personalizaciones ?? {};
    final tamano = personal['tamano'] ?? personal['id_tamano'] ?? '';

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: theme.colorScheme.primary.withOpacity(0.10),
        child: Text(qty.toString(), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
      ),
      title: Text(nombre, style: theme.textTheme.bodyLarge),
      subtitle: tamano != null && tamano.toString().isNotEmpty ? Text(tamano.toString(), style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7))) : null,
      trailing: Text(precioStr, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<PedidosProvider>(context, listen: false);
    final estados = prov.estadosLocal();
    final currentEstado = pedido?.idEstado;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = theme.textTheme;

    if (loading) return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      ),
      body: LoadingIndicator(label: 'Cargando pedido...'),
    );

    if (pedido == null) {
      return Scaffold(
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
          title: Text('Pedido #${widget.pedidoId}'),
        ),
        body: Center(child: Text(errorMsg ?? 'No se pudo cargar el pedido')),
      );
    }

    // Si por alguna razón la normalización no se llenó (fallback), normalizar aquí
    if (detallesNormalizados.isEmpty && pedido!.detalles.isNotEmpty) {
      detallesNormalizados = pedido!.detalles.map((d) => _detalleFromDynamic(d)).toList();
    }

    final totalStr = _formatTotal(pedido!.total);

    // HEADER
    final header = Card(
      surfaceTintColor: cs.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: cs.primary.withOpacity(0.12),
            child: Text(pedido!.cliente.nombre.isNotEmpty ? pedido!.cliente.nombre[0].toUpperCase() : 'P', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(pedido!.cliente.nombre, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                const SizedBox(width: 8),
                Chip(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  label: Text(
                    estados.firstWhere((e) => e['id'] == currentEstado, orElse: () => {'nombre': '—'})['nombre'].toString(),
                    style: text.bodySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w700),
                  ),
                  backgroundColor: cs.primary.withOpacity(0.08),
                ),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: Text(pedido!.direccion ?? '-', style: text.bodyMedium?.copyWith(color: text.bodyMedium?.color?.withOpacity(0.8)))),
              ]),
            ]),
          ),
        ]),
      ),
    );

    // Product header
    final productHeader = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(children: [
        Text('Productos', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const Spacer(),
        Text('${detallesNormalizados.length}', style: text.bodySmall?.copyWith(color: text.bodySmall?.color?.withOpacity(0.7))),
      ]),
    );

    // Products list using normalized list
    final productsList = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ...List.generate(detallesNormalizados.length, (i) {
            final det = detallesNormalizados[i];
            return Column(children: [
              _productTile(det, theme),
              if (i < detallesNormalizados.length - 1) const Divider(height: 1),
            ]);
          }),
        ]),
      ),
    );

    // bottom bar
    final bottomBar = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: cs.shadow.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Total', style: text.bodySmall?.copyWith(color: text.bodySmall?.color?.withOpacity(0.7))),
            const SizedBox(height: 4),
            Text(totalStr, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ]),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 44,
          child: FilledButton.icon(
            onPressed: saving ? null : _advanceState,
            icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.local_shipping_outlined),
            label: Text(
              (() {
                final next = _nextState(currentEstado, estados);
                if (next != null && next['nombre'] != null) return next['nombre'].toString();
                return 'Sin acciones';
              })(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),
      ]),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido #${pedido!.id ?? ''}'),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
        actions: [
          IconButton(onPressed: _callClient, icon: Icon(Icons.call, color: cs.onSurface)),
        ],
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Hero(tag: 'pedido-${pedido!.id}', child: header)),
        productHeader,
        const SizedBox(height: 6),
        Expanded(child: SingleChildScrollView(child: productsList)),
        bottomBar,
=======
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
>>>>>>> 6876e94f5c454d6a1ac15e072a89cc194d903b44
      ]),
    );
  }
}


<<<<<<< HEAD

=======
>>>>>>> 6876e94f5c454d6a1ac15e072a89cc194d903b44
