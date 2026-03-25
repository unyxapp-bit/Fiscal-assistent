import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../domain/entities/colaborador.dart';
import '../../../../domain/entities/outro_setor.dart';
import '../../../providers/colaborador_provider.dart';
import '../../../providers/outro_setor_provider.dart';

const Color _kOutroSetorColor = Color(0xFF5C6BC0); // índigo

/// Seções de colaboradores em outro setor no Mapa
class OutroSetorSection extends StatelessWidget {
  const OutroSetorSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OutroSetorProvider>(context);
    final colaboradorProvider =
        Provider.of<ColaboradorProvider>(context, listen: false);

    if (provider.lista.isEmpty) return const SizedBox.shrink();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        side: const BorderSide(color: _kOutroSetorColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                const Icon(Icons.swap_horiz,
                    color: _kOutroSetorColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Em Outro Setor',
                  style: AppTextStyles.subtitle.copyWith(
                    color: _kOutroSetorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kOutroSetorColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${provider.lista.length} agora',
                    style: AppTextStyles.caption.copyWith(
                      color: _kOutroSetorColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: Dimensions.spacingMD),

            // Lista de colaboradores
            ...provider.lista.map((item) {
              final colaborador = colaboradorProvider.colaboradores
                  .cast<Colaborador?>()
                  .firstWhere(
                    (c) => c?.id == item.colaboradorId,
                    orElse: () => null,
                  );

              return _OutroSetorItem(
                item: item,
                colaborador: colaborador,
                onRemover: () => provider.remover(item.id),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _OutroSetorItem extends StatefulWidget {
  final OutroSetor item;
  final Colaborador? colaborador;
  final VoidCallback onRemover;

  const _OutroSetorItem({
    required this.item,
    required this.colaborador,
    required this.onRemover,
  });

  @override
  State<_OutroSetorItem> createState() => _OutroSetorItemState();
}

class _OutroSetorItemState extends State<_OutroSetorItem> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _tempo() {
    final d = DateTime.now().difference(widget.item.criadoEm);
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}min';
    return '${d.inMinutes}min';
  }

  @override
  Widget build(BuildContext context) {
    final nome = widget.colaborador?.nome ?? 'Colaborador';
    final iniciais =
        widget.colaborador?.iniciais ?? nome.substring(0, 1).toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _kOutroSetorColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kOutroSetorColor.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _kOutroSetorColor.withValues(alpha: 0.10),
            child: Text(
              iniciais,
              style: const TextStyle(
                color: _kOutroSetorColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome.split(' ').first,
                  style: AppTextStyles.h4,
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 11, color: _kOutroSetorColor),
                    const SizedBox(width: 3),
                    Text(
                      widget.item.setor,
                      style: AppTextStyles.caption.copyWith(
                        color: _kOutroSetorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _tempo(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _kOutroSetorColor,
                ),
              ),
              Text(
                'no setor',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: widget.onRemover,
          ),
        ],
      ),
    );
  }
}
