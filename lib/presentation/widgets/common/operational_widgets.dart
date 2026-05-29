import 'package:flutter/material.dart';

import '../../../core/constants/app_styles.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/theme/app_theme.dart';

class OperationalSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const OperationalSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: AppStyles.softTile(
            context: context,
            tint: tokens.primary,
            radius: tokens.inputRadius,
          ),
          child: Icon(icon, color: tokens.primary, size: 16),
        ),
        const SizedBox(width: Dimensions.spacingSM),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.h4,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: Dimensions.spacingSM),
          trailing!,
        ],
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final bool compact;

  const StatusPill({
    super.key,
    this.icon,
    required this.label,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 7,
      ),
      decoration: AppStyles.softTile(
        context: context,
        tint: color,
        radius: 999,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 13 : 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class OperationalMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;
  final String? helper;
  final VoidCallback? onTap;

  const OperationalMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
    this.helper,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    final radius = BorderRadius.circular(tokens.inputRadius);
    final decoration = AppStyles.softTile(
      context: context,
      tint: color,
      radius: tokens.inputRadius,
    );
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSM,
        vertical: Dimensions.paddingSM,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h3.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (helper != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    helper!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.78),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: color.withValues(alpha: 0.72),
              size: 18,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return Container(
        constraints: const BoxConstraints(minHeight: 68),
        decoration: decoration,
        child: content,
      );
    }

    return Semantics(
      button: true,
      label: '$label: $value',
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            decoration: decoration,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 68),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

class OperationalMetricData {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final String? helper;
  final VoidCallback? onTap;

  const OperationalMetricData({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.helper,
    this.onTap,
  });
}

class OperationalMetricGrid extends StatelessWidget {
  final List<OperationalMetricData> metrics;
  final double minTileWidth;

  const OperationalMetricGrid({
    super.key,
    required this.metrics,
    this.minTileWidth = 168,
  });

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / minTileWidth)
            .floor()
            .clamp(1, metrics.length);

        return GridView.builder(
          itemCount: metrics.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: Dimensions.spacingSM,
            mainAxisSpacing: Dimensions.spacingSM,
            mainAxisExtent: 86,
          ),
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return OperationalMetricTile(
              label: metric.label,
              value: metric.value,
              color: metric.color,
              icon: metric.icon,
              helper: metric.helper,
              onTap: metric.onTap,
            );
          },
        );
      },
    );
  }
}

class OperationalActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? badge;
  final bool framed;
  final bool dense;

  const OperationalActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
    this.framed = true,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    final radius = BorderRadius.circular(tokens.cardRadius);
    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.paddingMD,
        vertical: dense ? 10 : Dimensions.paddingSM,
      ),
      child: Row(
        children: [
          _ActionIcon(icon: icon, color: color, badge: badge),
          const SizedBox(width: Dimensions.spacingSM),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                fontWeight: dense ? FontWeight.w600 : FontWeight.w700,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: framed
                ? color.withValues(alpha: 0.72)
                : AppColors.textSecondary,
            size: 20,
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: framed
            ? Ink(
                decoration: AppStyles.softCard(
                  context: context,
                  tint: color,
                  radius: tokens.cardRadius,
                  elevated: false,
                ),
                child: content,
              )
            : content,
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? badge;

  const _ActionIcon({
    required this.icon,
    required this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: AppStyles.softTile(
            context: context,
            tint: color,
            radius: tokens.inputRadius,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        if (badge != null)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: tokens.cardBackground,
                  width: 1.5,
                ),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
