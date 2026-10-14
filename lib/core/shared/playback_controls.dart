import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:taxi_driver_app/core/shared/loading_gif.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';

/// Shared building blocks for the route playback panels (history tracking and
/// ride details) so both screens stay visually and behaviourally identical.

/// A colored stretch of a playback timeline, expressed as fractions of the
/// whole route (0 = departure, 1 = arrival).
@immutable
class PlaybackSegment {
  final double start;
  final double end;
  final Color color;

  const PlaybackSegment({
    required this.start,
    required this.end,
    required this.color,
  });

  @override
  bool operator ==(Object other) =>
      other is PlaybackSegment &&
      other.start == start &&
      other.end == end &&
      other.color == color;

  @override
  int get hashCode => Object.hash(start, end, color);
}

/// Monospaced-ish style so the timers do not jitter while playing.
final TextStyle playbackTimeLabelStyle = AppTextStyles.labelSmall.copyWith(
  color: AppColors.textSecondary,
  fontSize: 10,
  fontFeatures: const [ui.FontFeature.tabularFigures()],
);

/// True on short or narrow devices, where the panel tightens its spacing and
/// shrinks its touch targets so everything still fits.
bool isCompactPlayback(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.height < 700 || size.width < 360;
}

/// Bottom offset for a playback panel floating over a full screen map.
///
/// The history tab sits inside the home scaffold, so its bottom navigation bar
/// already lifts the panel off the screen edge. Screens without that bar add
/// the equivalent gap here, scaled to the device instead of hard coded.
double playbackPanelBottomInset(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final navigationBarEquivalent =
      (mediaQuery.size.height * 0.085).clamp(52.0, 88.0);
  return mediaQuery.padding.bottom + navigationBarEquivalent;
}

/// Formats a playback duration as `mm:ss`, or `h:mm:ss` past an hour.
String formatPlaybackDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  final hours = duration.inHours;
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

/// Blurred overlay with a card telling the driver what is being loaded. Used
/// by every route playback screen so the waiting state looks the same.
class PlaybackLoadingOverlay extends StatelessWidget {
  final String message;

  const PlaybackLoadingOverlay({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
      child: Container(
        color: AppColors.black.withOpacity(0.1),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LoadingGif(width: 56, height: 56),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The floating white card hosting the playback controls.
class PlaybackPanel extends StatelessWidget {
  final bool isExpanded;
  final Widget header;
  final Widget timeline;
  final Widget? metrics;
  final Widget? controls;

  const PlaybackPanel({
    super.key,
    required this.isExpanded,
    required this.header,
    required this.timeline,
    this.metrics,
    this.controls,
  });

  @override
  Widget build(BuildContext context) {
    final compact = isCompactPlayback(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.14),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 8 : 10,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              header,
              if (metrics != null)
                _collapsible(
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: metrics!,
                  ),
                ),
              const SizedBox(height: 6),
              // Time always flows left to right, even in Arabic, like any player.
              Directionality(
                textDirection: ui.TextDirection.ltr,
                child: timeline,
              ),
              if (controls != null)
                _collapsible(
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: controls!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _collapsible(Widget child) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: isExpanded ? child : const SizedBox(width: double.infinity),
    );
  }
}

/// Always-visible panel header: status icon, title, live subtitle, play button
/// and the collapse chevron. Tapping the row collapses or expands the panel.
class PlaybackPanelHeader extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  const PlaybackPanelHeader({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.isPlaying,
    required this.onPlayPause,
    required this.isExpanded,
    required this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onToggleExpanded,
      child: Row(
        children: [
          leading,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textDirection: ui.TextDirection.ltr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          PlaybackPlayButton(isPlaying: isPlaying, onTap: onPlayPause),
          const SizedBox(width: 4),
          AnimatedRotation(
            duration: const Duration(milliseconds: 220),
            turns: isExpanded ? 0 : 0.5,
            child: const Icon(
              Icons.expand_more_rounded,
              color: AppColors.textTertiary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded icon badge used as the header leading widget.
class PlaybackStatusIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const PlaybackStatusIcon({
    super.key,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: 17, color: color),
    );
  }
}

class PlaybackPlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const PlaybackPlayButton({
    super.key,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = isCompactPlayback(context) ? 38.0 : 42.0;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.brandBlue.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: AppColors.brandBlue,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                key: ValueKey(isPlaying),
                color: AppColors.white,
                size: size * 0.57,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Scrubbable timeline. Tapping or dragging anywhere on the bar seeks, and the
/// colored segments mirror what is drawn on the map.
class PlaybackTimeline extends StatelessWidget {
  final double progress;
  final List<PlaybackSegment> segments;
  final ValueChanged<double> onSeek;
  final String leadingLabel;
  final String trailingLabel;
  final Widget? center;

  const PlaybackTimeline({
    super.key,
    required this.progress,
    required this.segments,
    required this.onSeek,
    required this.leadingLabel,
    required this.trailingLabel,
    this.center,
  });

  static const double thumbRadius = 8;
  static const double _barHeight = 26;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth =
                math.max(1.0, constraints.maxWidth - thumbRadius * 2);

            void seek(Offset localPosition) {
              onSeek(((localPosition.dx - thumbRadius) / trackWidth)
                  .clamp(0.0, 1.0));
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => seek(details.localPosition),
              onHorizontalDragStart: (details) => seek(details.localPosition),
              onHorizontalDragUpdate: (details) => seek(details.localPosition),
              child: SizedBox(
                width: double.infinity,
                height: _barHeight,
                child: CustomPaint(
                  painter: _TimelinePainter(
                    segments: segments,
                    progress: progress,
                  ),
                ),
              ),
            );
          },
        ),
        Row(
          children: [
            Text(leadingLabel, style: playbackTimeLabelStyle),
            const Spacer(),
            if (center != null) ...[
              // Scales down rather than overflowing with large system fonts.
              Flexible(
                child: FittedBox(fit: BoxFit.scaleDown, child: center!),
              ),
              const Spacer(),
            ],
            Text(trailingLabel, style: playbackTimeLabelStyle),
          ],
        ),
      ],
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final List<PlaybackSegment> segments;
  final double progress;

  const _TimelinePainter({
    required this.segments,
    required this.progress,
  });

  static const double _trackHeight = 8;
  static const double _thumbRadius = PlaybackTimeline.thumbRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final trackWidth = math.max(1.0, size.width - _thumbRadius * 2);
    final top = (size.height - _trackHeight) / 2;
    final bottom = top + _trackHeight;
    final track = Rect.fromLTWH(_thumbRadius, top, trackWidth, _trackHeight);
    final rounded = RRect.fromRectAndRadius(
      track,
      const Radius.circular(_trackHeight / 2),
    );

    canvas.save();
    canvas.clipRRect(rounded);
    canvas.drawRect(track, Paint()..color = AppColors.surfaceMuted);

    final playedEdge = _thumbRadius + trackWidth * progress.clamp(0.0, 1.0);

    for (final segment in segments) {
      final left = _thumbRadius + trackWidth * segment.start;
      final right = _thumbRadius + trackWidth * segment.end;

      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        Paint()..color = segment.color.withOpacity(0.22),
      );

      if (playedEdge > left) {
        canvas.drawRect(
          Rect.fromLTRB(left, top, math.min(right, playedEdge), bottom),
          Paint()..color = segment.color,
        );
      }
    }
    canvas.restore();

    final thumbCenter = Offset(playedEdge, size.height / 2);
    canvas.drawCircle(
      thumbCenter,
      _thumbRadius + 1,
      Paint()..color = AppColors.black.withOpacity(0.12),
    );
    canvas.drawCircle(
      thumbCenter,
      _thumbRadius,
      Paint()..color = AppColors.white,
    );
    canvas.drawCircle(
      thumbCenter,
      _thumbRadius - 3.5,
      Paint()..color = AppColors.brandBlue,
    );
  }

  @override
  bool shouldRepaint(_TimelinePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      !listEquals(oldDelegate.segments, segments);
}

class PlaybackMetricChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const PlaybackMetricChip({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final compact = isCompactPlayback(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: compact ? 13 : 15, color: color),
          SizedBox(width: compact ? 4 : 5),
          Flexible(
            child: Text(
              label,
              textDirection: ui.TextDirection.ltr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 10 : 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlaybackLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const PlaybackLegendDot({
    super.key,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

class PlaybackCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const PlaybackCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final size = isCompactPlayback(context) ? 32.0 : 36.0;

    final button = Material(
      color: AppColors.surfaceColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.56, color: AppColors.textPrimary),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Transport controls laid out so the speed selector drops to a second line
/// instead of overflowing when the panel gets narrow.
class PlaybackControlsRow extends StatelessWidget {
  final List<Widget> buttons;
  final Widget trailing;

  const PlaybackControlsRow({
    super.key,
    required this.buttons,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = isCompactPlayback(context) ? 6.0 : 8.0;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: spacing,
      runSpacing: spacing,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: spacing,
          children: buttons,
        ),
        trailing,
      ],
    );
  }
}

class PlaybackSpeedSelector extends StatelessWidget {
  final double currentSpeed;
  final ValueChanged<double> onSpeedChanged;

  const PlaybackSpeedSelector({
    super.key,
    required this.currentSpeed,
    required this.onSpeedChanged,
  });

  static const _speeds = <(double, String)>[
    (0.5, '0.5x'),
    (1.0, '1x'),
    (2.0, '2x'),
  ];

  @override
  Widget build(BuildContext context) {
    final compact = isCompactPlayback(context);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _speeds.map((speed) {
          final isSelected = currentSpeed == speed.$1;

          return GestureDetector(
            onTap: () => onSpeedChanged(speed.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 11,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brandBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                speed.$2,
                textDirection: ui.TextDirection.ltr,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected ? AppColors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
