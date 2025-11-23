// lib/view/pedido_detalle.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/pedido.dart';
import '../providers/pedidos_provider.dart';
import '../widgets/loading_indicator.dart';

class PedidoDetalle extends StatefulWidget {
  final int pedidoId;
  const PedidoDetalle({required this.pedidoId, super.key});

  @override
  State<PedidoDetalle> createState() => _PedidoDetalleState();
}

class _PedidoDetalleState extends State<PedidoDetalle> {
  Pedido? pedido;
  bool loading = true;
  bool saving = false;
  String? errorMsg;

  // Lista normalizada usada por la UI (siempre Detalle)
  List<Detalle> detallesNormalizados = [];

  @override
  void initState() {
    super.initState();
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
    }
  }

  Future<void> _callClient() async {
    if (pedido == null) return;
    final phone = pedido!.cliente.telefono;
    if (phone == null || phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teléfono no disponible')));
      return;
    }
    final uri = Uri.parse('tel:$phone');
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
      ]),
    );
  }
}



