import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/app_theme.dart';

/// Shimmering placeholder blocks shown while data loads, instead of a
/// plain spinner — gives the app a much more "finished product" feel and
/// hints at the shape of the content that's coming.
class ShimmerBox extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius? borderRadius;
  const ShimmerBox({super.key, required this.height, this.width = double.infinity, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppTheme.darkSurface : Colors.grey.shade200,
      highlightColor: isDark ? const Color(0xFF262A48) : Colors.grey.shade100,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(16),
        ),
      ),
    );
  }
}

/// Full skeleton layout matching the dashboard's structure, so the
/// loading state doesn't jarringly jump/reflow once real data arrives.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        ShimmerBox(height: 170, borderRadius: BorderRadius.circular(24)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: ShimmerBox(height: 76, borderRadius: BorderRadius.circular(18))),
            const SizedBox(width: 12),
            Expanded(child: ShimmerBox(height: 76, borderRadius: BorderRadius.circular(18))),
          ],
        ),
        const SizedBox(height: 24),
        const ShimmerBox(height: 18, width: 120),
        const SizedBox(height: 12),
        ShimmerBox(height: 190, borderRadius: BorderRadius.circular(20)),
        const SizedBox(height: 24),
        const ShimmerBox(height: 18, width: 100),
        const SizedBox(height: 12),
        ShimmerBox(height: 80, borderRadius: BorderRadius.circular(18)),
        const SizedBox(height: 12),
        ShimmerBox(height: 80, borderRadius: BorderRadius.circular(18)),
      ],
    );
  }
}

/// Wraps a list item so it fades and slides in with a small per-index
/// delay, producing a "staggered entrance" effect for lists and grids
/// without needing an animation controller in every parent screen.
class StaggeredFadeIn extends StatelessWidget {
  final int index;
  final Widget child;
  const StaggeredFadeIn({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (index * 60).clamp(0, 400)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
