import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_dimensions.dart';

class WaveformAnimation extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  final int barCount;
  final double maxHeight;

  const WaveformAnimation({
    super.key,
    required this.isPlaying,
    this.color = AppColors.primary,
    this.barCount = 20,
    this.maxHeight = 40.0,
  });

  @override
  State<WaveformAnimation> createState() => _WaveformAnimationState();
}

class _WaveformAnimationState extends State<WaveformAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(WaveformAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = widget.barCount <= 0 ? 1 : widget.barCount;
        const gap = 3.0;
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : count * 11.0;
        final barWidth = ((availableWidth - (count * gap)) / count).clamp(
          2.0,
          AppDimensions.paddingSM,
        );

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(count, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final delay = index * 0.05;
                final value = (_controller.value + delay).abs() % 1.0;
                final height = (10 + value * (widget.maxHeight - 10)).clamp(
                  4.0,
                  widget.maxHeight,
                );
                return Container(
                  width: barWidth,
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: gap / 2),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.6 + value * 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
            );
          }),
        );
      },
    );
  }
}
