import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../widgets/cartazes/poster_canvas.dart';
import '../../widgets/cartazes/poster_factory.dart';
import 'cartaz_history_store.dart';
import 'preview_cartaz_page.dart';

class CartazesSalvosPage extends StatefulWidget {
  const CartazesSalvosPage({super.key});

  @override
  State<CartazesSalvosPage> createState() => _CartazesSalvosPageState();
}

class _CartazesSalvosPageState extends State<CartazesSalvosPage> {
  late Future<List<SavedCartaz>> _future;

  @override
  void initState() {
    super.initState();
    _future = CartazHistoryStore.loadAll();
  }

  void _reload() {
    setState(() => _future = CartazHistoryStore.loadAll());
  }

  Future<void> _open(SavedCartaz cartaz) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PreviewCartazPage(
          data: cartaz.data,
          savedCartazId: cartaz.id,
          initialTextAdjustments: cartaz.textAdjustments,
        ),
      ),
    );
    if (mounted) _reload();
  }

  Future<void> _delete(SavedCartaz cartaz) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir cartaz?'),
        content: Text('O cartaz "${cartaz.title}" sera removido do historico.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCC0000),
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await CartazHistoryStore.delete(cartaz.id);
    if (!mounted) return;
    _reload();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cartaz removido')),
    );
  }

  void _novoCartaz() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Cartazes feitos'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Novo cartaz',
            onPressed: _novoCartaz,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<SavedCartaz>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? const <SavedCartaz>[];
          if (items.isEmpty) {
            return _EmptyCartazes(onCreate: _novoCartaz);
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width >= 1100
                    ? 4
                    : width >= 760
                        ? 3
                        : 2;

                return GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.56,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final cartaz = items[index];
                    return _SavedCartazCard(
                      cartaz: cartaz,
                      onTap: () => _open(cartaz),
                      onDelete: () => _delete(cartaz),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SavedCartazCard extends StatelessWidget {
  final SavedCartaz cartaz;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SavedCartazCard({
    required this.cartaz,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final updatedAt = DateFormat('dd/MM HH:mm').format(cartaz.updatedAt);
    final posterSize = PosterCanvas.canvasSizeFor(cartaz.data.tamanho);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: posterSize.width,
                        height: posterSize.height,
                        child: buildPosterWidget(
                          cartaz.data,
                          textAdjustments: cartaz.textAdjustments,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cartaz.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          cartaz.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          updatedAt,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    onSelected: (value) {
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Excluir'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCartazes extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyCartazes({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD6166A).withAlpha(18),
              ),
              child: const Icon(
                Icons.collections_bookmark_rounded,
                color: Color(0xFFD6166A),
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Nenhum cartaz feito ainda',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quando um cartaz chegar na preview, ele aparece aqui para voce abrir de novo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Criar cartaz'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD6166A),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
