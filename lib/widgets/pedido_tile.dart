// lib/widgets/pedido_tile.dart
import 'package:flutter/material.dart';
import '../models/pedido.dart';

class PedidoTile extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback? onTap;
  final bool useHero;

  const PedidoTile({
    required this.pedido,
    this.onTap,
    this.useHero = true,
    super.key,
  });

  Color _estadoColor(BuildContext context, int? id) {
    final cs = Theme.of(context).colorScheme;
    switch (id) {
      case 1: // Pendiente
        return cs.primary.withOpacity(0.12);
      case 2: // Pagado
        return Colors.blue.withOpacity(0.12);
      case 3: // Preparando
        return Colors.amber.withOpacity(0.12);
      case 4: // En camino
        return Colors.green.withOpacity(0.12);
      case 5: // Entregado
        return Colors.grey.withOpacity(0.12);
      default:
        return cs.primary.withOpacity(0.08);
    }
  }

  Color _estadoTextColor(BuildContext context, int? id) {
    switch (id) {
      case 1:
        return Theme.of(context).colorScheme.primary;
      case 2:
        return Colors.blue.shade700;
      case 3:
        return Colors.amber.shade800;
      case 4:
        return Colors.green.shade700;
      case 5:
        return Colors.grey.shade700;
      default:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  String _estadoLabel(int? id) {
    switch (id) {
      case 1:
        return 'Pendiente';
      case 2:
        return 'Pagado';
      case 3:
        return 'Preparando';
      case 4:
        return 'En camino';
      case 5:
        return 'Entregado';
      default:
        return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final cliente = pedido.cliente.nombre.isNotEmpty ? pedido.cliente.nombre : 'Cliente';
    final direccion = pedido.direccion ?? '';
    final total = pedido.total != null ? '\$${pedido.total!.toStringAsFixed(2)}' : '';

    final estadoId = pedido.idEstado;
    final estadoLabel = _estadoLabel(estadoId);
    final estadoBg = _estadoColor(context, estadoId);
    final estadoTxt = _estadoTextColor(context, estadoId);

    final content = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // avatar + basic info
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: cs.primary.withOpacity(0.12),
              child: Text(
                cliente.isNotEmpty ? cliente[0].toUpperCase() : 'R',
                style: textTheme.titleMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          // main texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // primera línea: id + estado (compact) - mayor jerarquía
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Pedido #${pedido.id ?? '—'}',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // estado chip minimal
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: estadoBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        estadoLabel,
                        style: textTheme.bodySmall?.copyWith(color: estadoTxt, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // segunda línea: cliente y direccion (sutil)
                Text(
                  cliente,
                  style: textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  direccion,
                  style: textTheme.bodySmall?.copyWith(color: textTheme.bodySmall?.color?.withOpacity(0.7)),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),

          // total & chevron
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                total,
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Icon(Icons.chevron_right, color: Theme.of(context).iconTheme.color),
            ],
          ),
        ],
      ),
    );

    final tile = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        splashFactory: InkRipple.splashFactory,
        child: content,
      ),
    );

    if (useHero && pedido.id != null) {
      return Hero(
        tag: 'pedido-${pedido.id}',
        child: tile,
      );
    }

    return tile;
  }
}
