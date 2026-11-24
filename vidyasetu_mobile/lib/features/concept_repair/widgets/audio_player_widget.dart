import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../services/audio_service.dart';

class AudioPlayerWidget extends StatefulWidget {
  final AudioPlayerService service;
  final bool isOdia;
  final String? textToSpeak;

  const AudioPlayerWidget({
    Key? key,
    required this.service,
    required this.isOdia,
    this.textToSpeak,
  }) : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    widget.service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.service.state;
    final isPlaying = state.state == AudioState.playing;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE4F0E2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD2E6D0)),
      ),
      child: Column(
        children: [
          // Audio Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.record_voice_over_outlined,
                      size: 16, color: AppColors.accentTerracotta),
                  const SizedBox(width: 6),
                  Text(
                    widget.isOdia
                        ? 'Listen in Odia Voice (ଓଡ଼ିଆରେ ଶୁଣନ୍ତୁ)'
                        : 'Listen in Odia Voice',
                    style: AppTypography.titleSmall(),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD2E6D0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Offline Edge TTS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDarkGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Waveform bars
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(24, (index) {
                final heights = [
                  12.0, 18.0, 26.0, 14.0, 32.0, 20.0, 10.0, 28.0,
                  22.0, 16.0, 34.0, 18.0, 24.0, 12.0, 30.0, 16.0,
                  22.0, 14.0, 26.0, 18.0, 12.0, 20.0, 16.0, 10.0,
                ];
                final isPassed = index < 12;

                return Container(
                  width: 4,
                  height: heights[index % heights.length],
                  decoration: BoxDecoration(
                    color: isPassed
                        ? AppColors.terracottaDark
                        : const Color(0xFFC8DEC6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 4),

          // Time Progress Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                state.positionFormatted,
                style: AppTypography.labelSmallBold(
                  color: AppColors.textHighContrast,
                ),
              ),
              Text(
                state.durationFormatted,
                style: AppTypography.labelSmall(
                  color: AppColors.textMutedOlive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Controls Row: Rewind 10s, Play/Pause, Forward 10s, Speed selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Rewind 10s
                  IconButton(
                    icon: const Icon(Icons.replay_10_rounded),
                    color: AppColors.textHighContrast,
                    onPressed: () => widget.service.seekRelative(-10),
                    constraints:
                        const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                  const SizedBox(width: 4),

                  // Play/Pause circular button
                  GestureDetector(
                    onTap: () {
                      if (state.state == AudioState.stopped &&
                          widget.textToSpeak != null &&
                          widget.textToSpeak!.isNotEmpty) {
                        widget.service.playSynthesizedText(
                          text: widget.textToSpeak!,
                          languageCode: widget.isOdia ? 'od-IN' : 'en-IN',
                        );
                      } else {
                        widget.service.togglePlayPause();
                      }
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: AppColors.accentTerracotta,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          state.state == AudioState.loading
                              ? Icons.hourglass_top_rounded
                              : (isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded),
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Forward 10s
                  IconButton(
                    icon: const Icon(Icons.forward_10_rounded),
                    color: AppColors.textHighContrast,
                    onPressed: () => widget.service.seekRelative(10),
                    constraints:
                        const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                ],
              ),

              // Speed selector pills
              Row(
                children: [0.8, 1.0, 1.2].map((speed) {
                  final isSelected = state.speed == speed;
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: GestureDetector(
                      onTap: () => widget.service.setSpeed(speed),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryDarkGreen
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${speed}x',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
