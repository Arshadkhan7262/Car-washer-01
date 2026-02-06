import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Shimmer effect widget for job card loading state
class JobCardShimmer extends StatelessWidget {
  const JobCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.black, width: 1),
        color: AppColors.white,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildShimmerBox(44, 44, borderRadius: 8),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShimmerBox(120, 20, borderRadius: 4),
                          const SizedBox(height: 8),
                          _buildShimmerBox(100, 15, borderRadius: 4),
                        ],
                      ),
                    ),
                    _buildShimmerBox(70, 30, borderRadius: 14),
                  ],
                ),
                const SizedBox(height: 18),
                _buildShimmerRow(),
                const SizedBox(height: 10),
                _buildShimmerRow(),
                const SizedBox(height: 10),
                _buildShimmerRow(),
              ],
            ),
          ),
          Divider(height: 1, color: Color(0xFF0A2540).withOpacity(0.49)),
          Padding(
            padding: const EdgeInsets.only(
              left: 9,
              right: 12,
              top: 16,
              bottom: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildShimmerBox(28, 28, borderRadius: 4),
                    const SizedBox(width: 3),
                    _buildShimmerBox(60, 20, borderRadius: 4),
                  ],
                ),
                _buildShimmerBox(100, 30, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox(double width, double height, {double borderRadius = 4}) {
    return _ShimmerEffect(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  Widget _buildShimmerRow() {
    return Row(
      children: [
        _buildShimmerBox(18, 11, borderRadius: 2),
        const SizedBox(width: 8),
        Expanded(
          child: _buildShimmerBox(double.infinity, 14, borderRadius: 4),
        ),
      ],
    );
  }
}

/// Shimmer animation effect
class _ShimmerEffect extends StatefulWidget {
  final Widget child;

  const _ShimmerEffect({required this.child});

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 - _controller.value * 2, 0.0),
              end: Alignment(1.0 - _controller.value * 2, 0.0),
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
