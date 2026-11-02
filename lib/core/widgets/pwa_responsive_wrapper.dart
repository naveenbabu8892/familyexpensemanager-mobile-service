import 'package:flutter/material.dart';

/// Responsive wrapper optimizing the UI for Web/PWA and large desktop screens
/// while preserving the native full-bleed experience on mobile phones.
class PwaResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxContentWidth;

  const PwaResponsiveWrapper({
    super.key,
    required this.child,
    this.maxContentWidth = 720,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    // On mobile devices or viewports narrower than the threshold, render full-bleed
    if (screenWidth <= maxContentWidth) {
      return child;
    }

    // On desktop / wide displays, center the application content in a neat container
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backdropColor = isDark ? const Color(0xFF1E1714) : const Color(0xFFEDE5D8);

    return Container(
      color: backdropColor,
      alignment: Alignment.center,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRect(
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
