import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:centrode/shared/elements/elements.dart';
import 'package:flutter/material.dart';

/// Reusable top-level section container with a pinned live showcase header.
class ShowcaseSectionShell extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final String? badgeText;
  final Widget showcase;
  final Widget child;

  const ShowcaseSectionShell({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    this.badgeText,
    required this.showcase,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _ShowcaseSectionHeaderDelegate(
            title: title,
            icon: icon,
            accentColor: accentColor,
            badgeText: badgeText,
            showcase: showcase,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 6.0, bottom: 16.0),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _ShowcaseSectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final IconData icon;
  final Color accentColor;
  final String? badgeText;
  final Widget showcase;

  _ShowcaseSectionHeaderDelegate({
    required this.title,
    required this.icon,
    required this.accentColor,
    this.badgeText,
    required this.showcase,
  });

  @override
  double get minExtent => 124.0;

  @override
  double get maxExtent => 124.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          color: CentrodeDerivedPalette.of(context)
              .glassBackground(isHeader: overlapsContent),
          borderRadius: BorderRadius.circular(UiRadius.panel),
          border: Border.all(
            color: CentrodeDerivedPalette.of(context)
                .border(accentColor, strong: overlapsContent),
            width: UiStrokeWidth.subtle,
          ),
          boxShadow: overlapsContent
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header outside of box at top-left corner
            Padding(
              padding: const EdgeInsets.only(left: 2.0, right: 2.0, bottom: 4.0),
              child: Row(
                children: [
                  Icon(icon, size: UiIconSize.dense, color: accentColor),
                  const SizedBox(width: UiSpacing.tight),
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: UiFont.compact,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: accentColor.withValues(alpha: 0.95),
                    ),
                  ),
                  const Spacer(),
                  if (badgeText != null)
                    _SectionScopeBadge(
                      label: badgeText!,
                      accentColor: accentColor,
                    ),
                ],
              ),
            ),
            showcase,
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ShowcaseSectionHeaderDelegate oldDelegate) {
    return oldDelegate.title != title ||
        oldDelegate.badgeText != badgeText ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.showcase != showcase;
  }
}

/// Reusable top-level outer shell container for inspector property sections.
class GlassSectionShell extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final String? badgeText;
  final Widget child;

  const GlassSectionShell({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    this.badgeText,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header outside of box at top-left corner
          Padding(
            padding: const EdgeInsets.only(left: 2.0, right: 2.0, bottom: 6.0),
            child: Row(
              children: [
                Icon(icon, size: UiIconSize.dense, color: accentColor),
                const SizedBox(width: UiSpacing.tight),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: UiFont.compact,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.95),
                  ),
                ),
                const Spacer(),
                if (badgeText != null)
                  _SectionScopeBadge(
                    label: badgeText!,
                    accentColor: accentColor,
                  ),
              ],
            ),
          ),
          // Glass Content Box
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(UiRadius.panel),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.22),
                width: UiStrokeWidth.subtle,
              ),
            ),
            padding: UiInsets.standard,
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Non-button, lightweight selection scope indicator.
class _SectionScopeBadge extends StatelessWidget {
  final String label;
  final Color accentColor;

  const _SectionScopeBadge({
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isGlobal = label.toUpperCase().contains('GLOBAL');

    if (isGlobal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.public_rounded,
            size: 13,
            color: Colors.white.withValues(alpha: 0.55),
          ),
          const SizedBox(width: UiSpacing.tight),
          Text(
            'GLOBAL',
            style: TextStyle(
              fontSize: UiFont.compact,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accentColor.withValues(alpha: 0.95),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.6),
                blurRadius: 4,
                spreadRadius: 0.5,
              ),
            ],
          ),
        ),
        const SizedBox(width: UiSpacing.tight),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: UiFont.compact,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
            color: accentColor.withValues(alpha: 0.95),
          ),
        ),
      ],
    );
  }
}
