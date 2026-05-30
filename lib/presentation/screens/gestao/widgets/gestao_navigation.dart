import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/constants/text_styles.dart';

class GestaoDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Color color;
  final int badgeCount;

  const GestaoDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.color,
    this.badgeCount = 0,
  });
}

class CaixasSidebarV3 extends StatelessWidget {
  final List<GestaoDestination> destinos;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const CaixasSidebarV3({
    super.key,
    required this.destinos,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(right: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Color(0xFF0F766E)),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Marcos',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          'Fiscal de Caixa',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white70),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Online',
                          style: TextStyle(
                            color: Color(0xFFA7F3D0),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            for (int i = 0; i < destinos.length; i++) ...[
              _SidebarTile(
                item: destinos[i],
                selected: i == selectedIndex,
                onTap: () => onSelected(i),
              ),
              const SizedBox(height: 10),
            ],
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _softCard(color: AppColors.background),
              child: const Row(
                children: [
                  Icon(Icons.headset_mic_rounded, color: Color(0xFF64748B)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ajuda e suporte',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GestaoTopNavigation extends StatelessWidget {
  final List<GestaoDestination> destinos;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onRefresh;
  final bool compact;
  final bool showDestinations;

  const GestaoTopNavigation({
    super.key,
    required this.destinos,
    required this.selectedIndex,
    required this.onSelected,
    required this.onRefresh,
    this.compact = false,
    this.showDestinations = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 72 : 76),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 24,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Voltar',
          ),
          if (!compact) ...[
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Text(
                'Centro de Controle dos Caixas',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 16),
          ] else
            const Spacer(),
          if (showDestinations) ...[
            Flexible(
              flex: compact ? 1 : 3,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  children: [
                    for (int i = 0; i < destinos.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      _GestaoChip(
                        item: destinos[i],
                        selected: i == selectedIndex,
                        onTap: () => onSelected(i),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
          ] else ...[
            const Spacer(),
          ],
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar',
          ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final GestaoDestination item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    selected ? item.selectedIcon : item.icon,
                    color: selected ? item.color : AppColors.textSecondary,
                  ),
                  if (item.badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: _Badge(value: item.badgeCount),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w800,
                    color: selected ? item.color : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GestaoChip extends StatelessWidget {
  final GestaoDestination item;
  final bool selected;
  final VoidCallback onTap;

  const _GestaoChip({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingMD,
            vertical: Dimensions.paddingSM,
          ),
          decoration: BoxDecoration(
            color: selected
                ? item.color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? item.color.withValues(alpha: 0.28)
                  : AppColors.cardBorder.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    selected ? item.selectedIcon : item.icon,
                    size: 16,
                    color: selected ? item.color : AppColors.textSecondary,
                  ),
                  if (item.badgeCount > 0)
                    Positioned(
                      top: -7,
                      right: -9,
                      child: _Badge(value: item.badgeCount),
                    ),
                ],
              ),
              const SizedBox(width: 6),
              Text(
                item.label,
                style: AppTextStyles.caption.copyWith(
                  color: selected ? item.color : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int value;

  const _Badge({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        value > 99 ? '99+' : '$value',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

BoxDecoration _softCard({
  Color? color,
  Color? borderColor,
  double radius = 24,
  bool elevated = true,
}) {
  return BoxDecoration(
    color: color ?? AppColors.cardBackground,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? AppColors.cardBorder),
    boxShadow: elevated
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ]
        : null,
  );
}
