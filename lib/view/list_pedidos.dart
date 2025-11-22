// lib/view/list_pedidos.dart
import 'package:flutter/material.dart';
import '../controllers/data_base_helper.dart';
import 'pedido_detalle.dart';
import '../view/login_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const FlutterSecureStorage secureStorage = FlutterSecureStorage();

class ListPedidos extends StatefulWidget {
  const ListPedidos({super.key});

  @override
  State<ListPedidos> createState() => _ListPedidosState();
}

class _ListPedidosState extends State<ListPedidos> with SingleTickerProviderStateMixin {
  final DataBaseHelper db = DataBaseHelper();
  late TabController _tabController;
  Future<List<dynamic>>? _futurePedidos;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPedidos();
  }

  void _loadPedidos() {
    setState(() {
      _futurePedidos = db.obtenerPedidos();
    });
  }

  Future<void> _logout() async {
    await secureStorage.delete(key: 'token');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => LoginPage()), (route) => false);
  }

  Widget _buildPedidoTile(Map<String, dynamic> p) {
    final id = p['id']?.toString() ?? '—';
    final cliente = p['cliente']?['nombre'] ?? p['cliente']?['nombre_completo'] ?? 'Cliente';
    final total = p['total'] != null ? p['total'].toString() : '';
    final estadoId = p['id_estado'] ?? p['estado']?['id'];
    final estadoNombre = db.obtenerEstadosLocal().firstWhere(
      (e) => e['id'] == estadoId,
      orElse: () => {'nombre': estadoId?.toString() ?? '—'},
    )['nombre'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        title: Text('Pedido #$id — $cliente', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Estado: ${estadoNombre ?? ''}${total != '' ? ' · Total: \$${total}' : ''}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          // Navegar a detalle y refrescar al volver
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PedidoDetalle(pedidoId: int.parse(id))));
          _loadPedidos();
        },
      ),
    );
  }

  Widget _buildList(List<dynamic> pedidos, bool showHistory) {
    // showHistory == true -> mostrar id_estado >= 5
    final filtered = pedidos.where((p) {
      final estado = p['id_estado'] ?? p['estado']?['id'];
      if (estado == null) return !showHistory; // si no tiene estado, meterlo en activos
      try {
        final id = estado is int ? estado : int.tryParse(estado.toString()) ?? 0;
        return showHistory ? id >= 5 : id < 5;
      } catch (_) {
        return !showHistory;
      }
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(showHistory ? 'No hay pedidos en historial.' : 'No hay pedidos activos.'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadPedidos();
        await _futurePedidos; // espera que se vuelva a cargar
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: filtered.length,
        itemBuilder: (_, i) {
          final p = Map<String, dynamic>.from(filtered[i]);
          return _buildPedidoTile(p);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si quieres mostrar una imagen de referencia local (ej: pantalla de ayuda) aquí está la ruta:
    // /mnt/data/96e23063-9662-43fb-ab76-572df37f4d20.png

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Activos'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futurePedidos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // mientras carga
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error al cargar pedidos: ${snapshot.error}'));
          } else {
            final pedidos = snapshot.data ?? [];
            return TabBarView(
              controller: _tabController,
              children: [
                _buildList(pedidos, false), // Activos
                _buildList(pedidos, true),  // Historial (Entregados)
              ],
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadPedidos,
        tooltip: 'Refrescar',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

