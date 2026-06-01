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
          width: 30,
          height: 30,
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

class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 1040,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: padding ??
                  EdgeInsets.symmetric(
                    horizontal: Dimensions.hPad(constraints.maxWidth),
                    vertical: Dimensions.paddingMD,
                  ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class OperationalPageFrame extends StatelessWidget {
  final Widget child;
  final double top;
  final double bottom;

  const OperationalPageFrame({
    super.key,
    required this.child,
    this.top = Dimensions.paddingMD,
    this.bottom = Dimensions.paddingLG,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hPad = Dimensions.operationalHPad(constraints.maxWidth);
        return Padding(
          padding: EdgeInsets.fromLTRB(hPad, top, hPad, bottom),
          child: child,
        );
      },
    );
  }
}

class AppSurface extends StatelessWidget {
  final Widget child;
  final Color? tint;
  final EdgeInsetsGeometry padding;
  final bool elevated;

  const AppSurface({
    super.key,
    required this.child,
    this.tint,
    this.padding = const EdgeInsets.all(Dimensions.paddingMD),
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: AppStyles.softCard(
        context: context,
        tint: tint,
        radius: context.appTheme.cardRadius,
        elevated: elevated,
      ),
      child: child,
    );
  }
}

class AppSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  const AppSection({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OperationalSectionHeader(
          icon: icon,
          title: title,
          trailing: trailing,
        ),
        const SizedBox(height: Dimensions.spacingSM),
        Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ],
    );
  }
}

class AppPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget body;
  final Widget? floatingActionButton;

  const AppPage({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actions,
    this.bottom,
    required this.body,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        toolbarHeight: subtitle == null ? 52 : 64,
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: Dimensions.spacingXS),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h3,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: actions,
        bottom: bottom,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

class OperationalEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const OperationalEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: AppSurface(
            tint: AppColors.inactive,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: AppStyles.softTile(
                    context: context,
                    tint: AppColors.primary,
                    radius: 999,
                  ),
                  child: Icon(icon, size: 28, color: AppColors.primary),
                ),
                const SizedBox(height: Dimensions.spacingMD),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h4,
                ),
                const SizedBox(height: Dimensions.spacingXS),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: Dimensions.spacingMD),
                  ElevatedButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OperationalLoadingState extends StatelessWidget {
  final String message;

  const OperationalLoadingState({
    super.key,
    this.message = 'Carregando...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: Dimensions.spacingMD),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class OperationalErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const OperationalErrorState({
    super.key,
    this.title = 'Nao foi possivel carregar',
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return OperationalEmptyState(
      icon: Icons.cloud_off_rounded,
      title: title,
      message: message,
      actionLabel: onRetry == null ? null : 'Tentar novamente',
      onAction: onRetry,
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
        vertical: 10,
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
        constraints: const BoxConstraints(minHeight: 62),
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
              constraints: const BoxConstraints(minHeight: 62),
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
    this.minTileWidth = 154,
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
            mainAxisExtent: 74,
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

class OperationalSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final bool showClear;

  const OperationalSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.onClear,
    this.showClear = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
        suffixIcon: showClear
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Limpar busca',
                onPressed: onClear,
              )
            : null,
        isDense: true,
      ),
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
    );
  }
}

class OperationalChipOption<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Color? color;
  final int? count;

  const OperationalChipOption({
    required this.value,
    required this.label,
    this.icon,
    this.color,
    this.count,
  });
}

class OperationalFilterChips<T> extends StatelessWidget {
  final List<OperationalChipOption<T>> options;
  final T? selected;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;

  const OperationalFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (final option in options) ...[
            _OperationalFilterChip<T>(
              option: option,
              selected: option.value == selected,
              onSelected: onSelected,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _OperationalFilterChip<T> extends StatelessWidget {
  final OperationalChipOption<T> option;
  final bool selected;
  final ValueChanged<T> onSelected;

  const _OperationalFilterChip({
    required this.option,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final color = option.color ?? AppColors.primary;
    final label = option.count == null
        ? option.label
        : '${option.label} (${option.count})';

    return FilterChip(
      avatar: option.icon == null
          ? null
          : Icon(
              option.icon,
              size: 16,
              color: selected ? color : AppColors.textSecondary,
            ),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      selected: selected,
      checkmarkColor: color,
      selectedColor: color.withValues(alpha: 0.12),
      labelStyle: AppTextStyles.caption.copyWith(
        color: selected ? color : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
      ),
      onSelected: (_) => onSelected(option.value),
    );
  }
}

class OperationalReferenceHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String statusLabel;
  final String? subtitle;
  final IconData statusIcon;
  final Color statusColor;
  final int? alertCount;
  final String? avatarLabel;
  final VoidCallback? onBack;
  final List<Widget> actions;

  const OperationalReferenceHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.statusLabel,
    this.subtitle,
    this.statusIcon = Icons.circle,
    this.statusColor = const Color(0xFF00856F),
    this.alertCount,
    this.avatarLabel,
    this.onBack,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    final cleanAvatar = avatarLabel?.trim();
    final initial = (cleanAvatar == null || cleanAvatar.isEmpty)
        ? null
        : cleanAvatar.substring(0, 1).toUpperCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (onBack != null) ...[
          _ReferenceCircleButton(
            icon: Icons.arrow_back_rounded,
            onTap: onBack,
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  color: tokens.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h1.copyWith(
                  color: tokens.textPrimary,
                  fontSize: 30,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 15),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      statusLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: statusColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: tokens.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        for (final action in actions) ...[
          const SizedBox(width: 8),
          action,
        ],
        if (alertCount != null) ...[
          const SizedBox(width: 10),
          OperationalNotificationButton(count: alertCount!),
        ],
        if (initial != null) ...[
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 24,
            backgroundColor: tokens.primary,
            child: Text(
              initial,
              style: TextStyle(
                color: tokens.textOnColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class OperationalNotificationButton extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const OperationalNotificationButton({
    super.key,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _ReferenceCircleButton(
          icon: Icons.notifications_none_rounded,
          onTap: onTap,
        ),
        if (count > 0)
          Positioned(
            top: 1,
            right: 1,
            child: Container(
              constraints: const BoxConstraints(minWidth: 20),
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class OperationalHeroPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final List<OperationalHeroMetric> metrics;
  final Color? color;
  final VoidCallback? onTap;

  const OperationalHeroPanel({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.metrics = const [],
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    final base = color ?? tokens.primary;
    final radius = BorderRadius.circular(26);
    final child = Ink(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [base, Color.lerp(base, Colors.black, 0.18) ?? base],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: base.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: tokens.textOnColor, size: 24),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h2.copyWith(
                    color: tokens.textOnColor,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              color: tokens.textOnColor.withValues(alpha: 0.90),
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (metrics.isNotEmpty) ...[
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final metric in metrics)
                  Flexible(child: _OperationalHeroMetricView(metric: metric)),
              ],
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: child,
      ),
    );
  }
}

class OperationalHeroMetric {
  final String value;
  final String label;
  final IconData icon;

  const OperationalHeroMetric({
    required this.value,
    required this.label,
    required this.icon,
  });
}

class _OperationalHeroMetricView extends StatelessWidget {
  final OperationalHeroMetric metric;

  const _OperationalHeroMetricView({required this.metric});

  @override
  Widget build(BuildContext context) {
    final onColor = context.appTheme.textOnColor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(metric.icon, color: onColor.withValues(alpha: 0.90), size: 23),
        const SizedBox(height: 6),
        Text(
          metric.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.h3.copyWith(
            color: onColor,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          metric.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(
            color: onColor.withValues(alpha: 0.88),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class OperationalReferenceKpiCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const OperationalReferenceKpiCard({
    super.key,
    required this.icon,
    required this.value,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    final content = Ink(
      height: 132,
      padding: const EdgeInsets.all(14),
      decoration: _referenceCardDecoration(context, borderColor: color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReferenceIconBox(icon: icon, color: color),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppTextStyles.h2.copyWith(
                color: color,
                fontSize: 27,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(onTap: onTap, borderRadius: radius, child: content),
    );
  }
}

class OperationalReferenceKpiGrid extends StatelessWidget {
  final List<Widget> children;
  final double breakpoint;

  const OperationalReferenceKpiGrid({
    super.key,
    required this.children,
    this.breakpoint = 720,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= breakpoint ? 4 : 2;
        final spacing = columns == 4 ? 12.0 : 10.0;
        final width =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class OperationalReferenceActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color color;
  final VoidCallback onTap;

  const OperationalReferenceActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          height: 142,
          padding: const EdgeInsets.all(14),
          decoration: _referenceCardDecoration(context, borderColor: color),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReferenceIconBox(icon: icon, color: color),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              StatusPill(label: badge, color: color, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

class OperationalTimelineCard extends StatelessWidget {
  final List<OperationalTimelineEntry> entries;
  final String emptyTitle;
  final String emptySubtitle;

  const OperationalTimelineCard({
    super.key,
    required this.entries,
    this.emptyTitle = 'Sem registros recentes',
    this.emptySubtitle = 'As movimentacoes aparecem aqui.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _referenceCardDecoration(context),
      child: entries.isEmpty
          ? _OperationalTimelineEntryView(
              entry: OperationalTimelineEntry(
                time: '',
                icon: Icons.check_circle_outline_rounded,
                title: emptyTitle,
                subtitle: emptySubtitle,
                color: AppColors.success,
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  _OperationalTimelineEntryView(entry: entries[i]),
                  if (i < entries.length - 1)
                    Divider(height: 26, color: AppColors.cardBorder),
                ],
              ],
            ),
    );
  }
}

class OperationalTimelineEntry {
  final String time;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;

  const OperationalTimelineEntry({
    required this.time,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
  });
}

class _OperationalTimelineEntryView extends StatelessWidget {
  final OperationalTimelineEntry entry;

  const _OperationalTimelineEntryView({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ReferenceIconBox(icon: entry.icon, color: entry.color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (entry.subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  entry.subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (entry.time.isNotEmpty) ...[
          const SizedBox(width: 10),
          Text(
            entry.time,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

class ReferenceSectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const ReferenceSectionTitle({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action!),
          ),
      ],
    );
  }
}

class _ReferenceCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ReferenceCircleButton({
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: tokens.cardBackground,
            shape: BoxShape.circle,
            border: Border.all(color: tokens.cardBorder),
          ),
          child: Icon(icon, color: tokens.textPrimary, size: 22),
        ),
      ),
    );
  }
}

class _ReferenceIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _ReferenceIconBox({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }
}

BoxDecoration _referenceCardDecoration(
  BuildContext context, {
  Color? borderColor,
}) {
  final tokens = context.appTheme;
  return BoxDecoration(
    color: tokens.cardBackground,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: borderColor?.withValues(alpha: 0.22) ?? tokens.cardBorder,
    ),
    boxShadow: [
      BoxShadow(
        color: tokens.shadowColor.withValues(alpha: 0.035),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );
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
