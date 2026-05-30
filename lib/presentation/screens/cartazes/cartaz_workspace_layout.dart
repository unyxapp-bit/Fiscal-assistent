import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/text_styles.dart';

class CartazWorkspaceAction {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool selected;

  const CartazWorkspaceAction({
    required this.label,
    required this.icon,
    this.onPressed,
    this.selected = false,
  });
}

class CartazWorkspaceBar extends StatelessWidget {
  final String badge;
  final List<CartazWorkspaceAction> actions;

  const CartazWorkspaceBar({
    super.key,
    required this.badge,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingMD),
          child: Row(
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 320),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  badge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: Dimensions.spacingSM),
              for (final action in actions)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: TextButton.icon(
                    onPressed: action.onPressed ?? () {},
                    icon: Icon(action.icon, size: 17),
                    label: Text(action.label),
                    style: TextButton.styleFrom(
                      foregroundColor: action.selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      visualDensity: VisualDensity.compact,
                      textStyle: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
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

class CartazWorkspacePanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  final bool expandChild;
  final EdgeInsets childPadding;

  const CartazWorkspacePanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.trailing,
    this.expandChild = false,
    this.childPadding = const EdgeInsets.all(Dimensions.paddingMD),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(Dimensions.radiusSM),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: expandChild ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSection,
                    borderRadius: BorderRadius.circular(Dimensions.radiusSM),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: Dimensions.spacingSM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.cardBorder),
          if (expandChild)
            Expanded(
              child: Padding(
                padding: childPadding,
                child: child,
              ),
            )
          else
            Padding(
              padding: childPadding,
              child: child,
            ),
        ],
      ),
    );
  }
}
