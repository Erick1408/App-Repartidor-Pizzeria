// lib/view/list_pedidos.dart
import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/pedido.dart';
import '../providers/pedidos_provider.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/pedido_tile.dart';
import 'pedido_detalle.dart';
import 'login_page.dart';
=======
import '../controllers/data_base_helper.dart';
import 'pedido_detalle.dart';
import '../view/login_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const FlutterSecureStorage secureStorage = FlutterSecureStorage();
>>>>>>> 6876e94f5c454d6a1ac15e072a89cc194d903b44

class ListPedidos extends StatefulWidget {
  const ListPedidos({super.key});

  @override
  State<ListPedidos> createState() => _ListPedidosState();
}

<<<<<<< HEAD
class _ListPedidosState extends State<ListPedidos> {
  bool _redirectingToLogin = false;

  // Search state
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // Filter state (null = todos)
  int? _filterEstadoId;

  final FocusNode _searchFocus = FocusNode();

  // Selected tab index: 0 = Activos, 1 = Historial
  int _selectedTab = 0;

  // Animation config
  final Duration _tabChangeDuration = const Duration(milliseconds: 300);
  final Curve _tabChangeCurve = Curves.easeInOutCubic;
=======
class _ListPedidosState extends State<ListPedidos> with SingleTickerProviderStateMixin {
  final DataBaseHelper db = DataBaseHelper();
  late TabController _tabController;
  Future<List<dynamic>>? _futurePedidos;
>>>>>>> 6876e94f5c454d6a1ac15e072a89cc194d903b44

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<PedidosProvider>(context, listen: false);
      if (prov.authenticated) prov.cargarPedidos();
    });

    _searchController.addListener(() {
      final q = _searchController.text.trim();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // Aplica filtros por activos/historial, estado y query
  List<Pedido> _applyFilters(List<Pedido> source, {required bool activos}) {
    final base = source.where((p) {
      final estado = p.idEstado ?? 0;
      return activos ? estado < 5 : estado >= 5;
    }).toList();

    final byEstado = (_filterEstadoId == null)
        ? base
        : base.where((p) => (p.idEstado ?? 0) == _filterEstadoId).toList();

    if (_query.isEmpty) return byEstado;

    final q = _query.toLowerCase();
    return byEstado.where((p) {
      final idStr = p.id?.toString() ?? '';
      final cliente = p.cliente.nombre.toLowerCase();
      final direccion = (p.direccion ?? '').toLowerCase();
      return idStr.contains(q) || cliente.contains(q) || direccion.contains(q);
    }).toList();
  }

  // Mostrar confirmación de logout y ejecutar
  Future<void> _confirmLogout(PedidosProvider provider) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar sesión ahora?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Cerrar sesión')),
        ],
      ),
    );

    if (ok == true) {
      await provider.logout();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  // Abrir dialogo de selección de filtro (bottom sheet)
  Future<void> _showFilterSheet(PedidosProvider provider) async {
    final estados = provider.estadosLocal();
    final selected = await showModalBottomSheet<int?>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (_) {
        return SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Todos'),
              leading: Radio<int?>(value: null, groupValue: _filterEstadoId, onChanged: (v) => Navigator.of(context).pop(v)),
              onTap: () => Navigator.of(context).pop(null),
            ),
            ...estados.map((e) => ListTile(
                  title: Text(e['nombre'].toString()),
                  leading: Radio<int?>(value: e['id'] as int?, groupValue: _filterEstadoId, onChanged: (v) => Navigator.of(context).pop(v)),
                  onTap: () => Navigator.of(context).pop(e['id'] as int?),
                )),
            const SizedBox(height: 12),
          ]),
        );
      },
    );

    if (mounted) setState(() => _filterEstadoId = selected);
  }

  // AppBar builder: search mode or normal mode
  PreferredSizeWidget _buildAppBar(PedidosProvider provider, SystemUiOverlayStyle overlayStyle) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    if (_isSearching) {
      // Minimal M3 search AppBar with pill input
      return AppBar(
        systemOverlayStyle: overlayStyle,
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        titleSpacing: 0,
        title: Row(children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: cs.onSurface.withOpacity(0.9)),
            onPressed: () {
              setState(() {
                _isSearching = false;
                _searchController.clear();
                _query = '';
              });
              _searchFocus.unfocus();
            },
          ),
          Expanded(
            child: Container(
              height: 44,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: cs.surfaceVariant,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: cs.shadow.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(children: [
                Icon(Icons.search, size: 20, color: cs.onSurfaceVariant.withOpacity(0.7)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    focusNode: _searchFocus,
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar cliente, id o dirección',
                      hintStyle: txt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.5)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: txt.bodyMedium,
                    textInputAction: TextInputAction.search,
                  ),
                ),
                if (_query.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    child: Icon(Icons.close, size: 18, color: cs.onSurface.withOpacity(0.6)),
                  ),
                const SizedBox(width: 6),
              ]),
            ),
          ),

          // quick filter
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: IconButton(
              tooltip: 'Filtrar estados',
              icon: Icon(Icons.filter_list, color: cs.onSurface.withOpacity(0.9)),
              onPressed: () => _showFilterSheet(provider),
            ),
          ),
        ]),
      );
    }

    // Normal AppBar (minimal M3)
    return AppBar(
      systemOverlayStyle: overlayStyle,
      title: Text('Pedidos', style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: cs.onSurface),
          onPressed: () {
            setState(() => _isSearching = true);
            Future.delayed(const Duration(milliseconds: 150), () => _searchFocus.requestFocus());
          },
          tooltip: 'Buscar',
        ),
        IconButton(
          tooltip: 'Filtrar',
          icon: Icon(Icons.filter_list, color: cs.onSurface),
          onPressed: () => _showFilterSheet(provider),
        ),
        IconButton(
          tooltip: 'Cerrar sesión',
          icon: Icon(Icons.logout, color: cs.error),
          onPressed: () => _confirmLogout(provider),
        ),
      ],
      // SegmentedButton (M3) as replacement for tabs
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<int>(
                  segments: const <ButtonSegment<int>>[
                    ButtonSegment(value: 0, label: Text('Activos')),
                    ButtonSegment(value: 1, label: Text('Historial')),
                  ],
                  selected: <int>{_selectedTab},
                  onSelectionChanged: (newSelection) {
                    if (newSelection.isEmpty) return;
                    final value = newSelection.first;
                    setState(() => _selectedTab = value);
                  },
                  multiSelectionEnabled: false,
                  showSelectedIcon: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(PedidosProvider provider, List<Pedido> source, {required bool activos, required Key pageKey}) {
    final filtered = _applyFilters(source, activos: activos);

    return RefreshIndicator(
      key: pageKey is PageStorageKey ? pageKey : null,
      onRefresh: () async => await provider.cargarPedidos(),
      edgeOffset: 8,
      child: filtered.isEmpty
          ? ListView(
              key: pageKey,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              children: [
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 56, color: Theme.of(context).iconTheme.color?.withOpacity(0.28)),
                      const SizedBox(height: 12),
                      Text(
                        provider.lastError ?? (provider.pedidos.isEmpty ? 'No hay pedidos' : 'No hay coincidencias'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 12),
                      if (provider.pedidos.isNotEmpty) FilledButton(onPressed: () => setState(() => _filterEstadoId = null), child: const Text('Ver todo')),
                    ],
                  ),
                ),
              ],
            )
          : ListView.separated(
              key: pageKey,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final pedido = filtered[index];
                return GestureDetector(
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PedidoDetalle(pedidoId: pedido.id!)));
                    await provider.cargarPedidos();
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    color: Theme.of(context).cardColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: PedidoTile(pedido: pedido),
                    ),
                  ),
                );
              },
            ),
=======
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
>>>>>>> 6876e94f5c454d6a1ac15e072a89cc194d903b44
    );
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final provider = Provider.of<PedidosProvider>(context);

    // redirect if not authenticated
    if (!provider.authenticated) {
      if (!_redirectingToLogin) {
        _redirectingToLogin = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
        });
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // compute overlay style once per build
    final brightness = Theme.of(context).brightness;
    final overlayStyle = brightness == Brightness.dark
        ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
        : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent);

    final activosSource = provider.pedidos.where((p) => (p.idEstado ?? 0) < 5).toList();
    final historialSource = provider.pedidos.where((p) => (p.idEstado ?? 0) >= 5).toList();

    final cs = Theme.of(context).colorScheme;

    // Prepare children widgets with PageStorageKey so scroll pos is kept
    final Widget activosList = _buildList(provider, activosSource, activos: true, pageKey: const PageStorageKey('list_activos'));
    final Widget historialList = _buildList(provider, historialSource, activos: false, pageKey: const PageStorageKey('list_historial'));

    // Wrap Scaffold in AnnotatedRegion so the overlay style applies while this screen is visible
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        appBar: _buildAppBar(provider, overlayStyle),
        body: Column(
          children: [
            // info line: counts and active filter chip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                Expanded(
                  child: Text(
                    'Resultados: ${_applyFilters(provider.pedidos, activos: _selectedTab == 0).length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7)),
                  ),
                ),
                if (_filterEstadoId != null)
                  Chip(
                    label: Text('Filtro: ${provider.estadosLocal().firstWhere((e) => e['id'] == _filterEstadoId)['nombre']}'),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () => setState(() => _filterEstadoId = null),
                    backgroundColor: cs.primary.withOpacity(0.08),
                  ),
              ]),
            ),

            // content
            Expanded(
              child: provider.loading
                  ? const LoadingIndicator(label: 'Cargando pedidos...')
                  : provider.pedidos.isEmpty
                      ? Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(provider.lastError ?? 'No hay pedidos', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7))),
                            const SizedBox(height: 10),
                            FilledButton(onPressed: () => provider.cargarPedidos(), child: const Text('Reintentar')),
                          ]),
                        )
                      : AnimatedSwitcher(
                          duration: _tabChangeDuration,
                          switchInCurve: _tabChangeCurve,
                          switchOutCurve: _tabChangeCurve,
                          transitionBuilder: (child, animation) {
                            // combine slide + fade
                            final inOffset = Tween<Offset>(begin: const Offset(0.0, 0.04), end: Offset.zero).animate(animation);
                            final fade = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
                            return SlideTransition(position: inOffset, child: FadeTransition(opacity: fade, child: child));
                          },
                          child: _selectedTab == 0
                              ? KeyedSubtree(key: const ValueKey<int>(0), child: activosList)
                              : KeyedSubtree(key: const ValueKey<int>(1), child: historialList),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
=======
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

>>>>>>> 6876e94f5c454d6a1ac15e072a89cc194d903b44
