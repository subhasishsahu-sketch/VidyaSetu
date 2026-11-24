import 'dart:async';
import 'package:flutter/foundation.dart';

enum AudioState { stopped, playing, paused }

class AudioPlaybackState {
  final AudioState state;
  final Duration position;
  final Duration duration;
  final double speed;

  const AudioPlaybackState({
    required this.state,
    required this.position,
    required this.duration,
    required this.speed,
  });

  AudioPlaybackState copyWith({
    AudioState? state,
    Duration? position,
    Duration? duration,
    double? speed,
  }) {
    return AudioPlaybackState(
      state: state ?? this.state,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
    );
  }

  String get positionFormatted => _format(position);
  String get durationFormatted => _format(duration);

  String _format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class AudioPlayerService extends ChangeNotifier {
  Timer? _ticker;
  AudioPlaybackState _state = const AudioPlaybackState(
    state: AudioState.paused,
    position: Duration(minutes: 1, seconds: 24),
    duration: Duration(minutes: 2, seconds: 40),
    speed: 1.0,
  );

  AudioPlaybackState get state => _state;

  void play() {
    _state = _state.copyWith(state: AudioState.playing);
    notifyListeners();

    _ticker?.cancel();
    _ticker = Timer.periodic(
      Duration(milliseconds: (1000 / _state.speed).round()),
      (timer) {
        if (_state.position >= _state.duration) {
          pause();
        } else {
          _state = _state.copyWith(
            position: _state.position + const Duration(seconds: 1),
          );
          notifyListeners();
        }
      },
    );
  }

  void pause() {
    _ticker?.cancel();
    _state = _state.copyWith(state: AudioState.paused);
    notifyListeners();
  }

  void togglePlayPause() {
    if (_state.state == AudioState.playing) {
      pause();
    } else {
      play();
    }
  }

  void seek(Duration newPosition) {
    final clamped = newPosition < Duration.zero
        ? Duration.zero
        : (newPosition > _state.duration ? _state.duration : newPosition);
    _state = _state.copyWith(position: clamped);
    notifyListeners();
  }

  void seekRelative(int seconds) {
    seek(_state.position + Duration(seconds: seconds));
  }

  void setSpeed(double speed) {
    _state = _state.copyWith(speed: speed);
    notifyListeners();
    if (_state.state == AudioState.playing) {
      play(); // restart timer with adjusted rate
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
