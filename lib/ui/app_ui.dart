import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';

class AppSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Border? border;

  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: border ?? Border.all(color: ElderLinkTheme.borderLight),
        boxShadow: AppConstants.cardShadow,
      ),
      child: child,
    );
  }
}

class AppScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const AppScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

class AppSummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const AppSummaryCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class AppSectionLabel extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const AppSectionLabel({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final EdgeInsetsGeometry? padding;

  const AppEmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class AppLoadingState extends StatelessWidget {
  final Color color;
  final String message;

  const AppLoadingState({
    super.key,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(color: color, strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class AppPill extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color backgroundColor;
  final EdgeInsetsGeometry? padding;

  const AppPill({
    super.key,
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class AppCategoryChip extends StatelessWidget {
  final RequestCategory category;

  const AppCategoryChip({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppPill(
      label: '${category.emoji} ${category.localizedLabel(l10n)}',
      textColor: category.color,
      backgroundColor: category.bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    );
  }
}

class AppRequestStatusChip extends StatelessWidget {
  final RequestStatus status;

  const AppRequestStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    late final String label;
    late final Color backgroundColor;
    late final Color textColor;

    switch (status) {
      case RequestStatus.pending:
        label = l10n.t('statusFindingVolunteer');
        backgroundColor = ElderLinkTheme.statusPending;
        textColor = ElderLinkTheme.statusPendingText;
        break;
      case RequestStatus.accepted:
        label = l10n.t('statusVolunteerFound');
        backgroundColor = ElderLinkTheme.statusAccepted;
        textColor = ElderLinkTheme.statusAcceptedText;
        break;
      case RequestStatus.inProgress:
        label = l10n.t('statusOnTheWay');
        backgroundColor = ElderLinkTheme.statusCompleted;
        textColor = ElderLinkTheme.statusCompletedText;
        break;
      case RequestStatus.completed:
        label = l10n.t('statusCompleted');
        backgroundColor = ElderLinkTheme.statusCompleted;
        textColor = ElderLinkTheme.statusCompletedText;
        break;
      case RequestStatus.cancelled:
        label = l10n.t('statusCancelled');
        backgroundColor = const Color(0xFFFCEBEB);
        textColor = ElderLinkTheme.danger;
        break;
    }

    return AppPill(
      label: label,
      textColor: textColor,
      backgroundColor: backgroundColor,
    );
  }
}

class AppAvatar extends StatelessWidget {
  final String initials;
  final Color color;
  final double radius;
  final bool showOnline;

  const AppAvatar({
    super.key,
    required this.initials,
    required this.color,
    this.radius = 24,
    this.showOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: color,
          child: Text(
            initials,
            style: TextStyle(
              fontSize: radius * 0.48,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        if (showOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.48,
              height: radius * 0.48,
              decoration: BoxDecoration(
                color: ElderLinkTheme.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class AppSettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const AppSettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(children: children),
    );
  }
}

class AppSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color iconBackground;
  final bool isDestructive;
  final VoidCallback? onTap;

  const AppSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.iconBackground,
    this.isDestructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 10,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: accentColor, size: 20),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDestructive
                  ? ElderLinkTheme.orange
                  : ElderLinkTheme.textPrimary,
            ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: ElderLinkTheme.textSecondary,
      ),
      onTap: onTap,
    );
  }
}

class AppBottomSheetHandle extends StatelessWidget {
  const AppBottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 5,
        decoration: BoxDecoration(
          color: ElderLinkTheme.borderLight,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class AppBottomSheetScaffold extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AppBottomSheetScaffold({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: padding ??
          EdgeInsets.fromLTRB(
            24,
            14,
            24,
            MediaQuery.of(context).padding.bottom + 24,
          ),
      child: child,
    );
  }
}

class AppInlineBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color backgroundColor;

  const AppInlineBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
