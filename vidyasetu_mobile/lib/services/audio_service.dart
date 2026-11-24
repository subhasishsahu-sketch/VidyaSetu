import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../data/models/voice_model.dart';
import '../data/repositories/vidyasetu_repository.dart';

enum AudioState { stopped, playing, paused, loading, error }

class AudioPlaybackState {
  final AudioState state;
  final Duration position;
  final Duration duration;
  final double speed;
  final String? errorMessage;

  const AudioPlaybackState({
    required this.state,
    required this.position,
    required this.duration,
    required this.speed,
    this.errorMessage,
  });

  AudioPlaybackState copyWith({
    AudioState? state,
    Duration? position,
    Duration? duration,
    double? speed,
    String? errorMessage,
  }) {
    return AudioPlaybackState(
      state: state ?? this.state,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      errorMessage: errorMessage ?? this.errorMessage,
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
  final VidyaSetuRepository? _repository;
  final AudioPlayer _player;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;

  AudioPlaybackState _state = const AudioPlaybackState(
    state: AudioState.paused,
    position: Duration(minutes: 1, seconds: 24),
    duration: Duration(minutes: 2, seconds: 40),
    speed: 1.0,
  );

  AudioPlayerService({VidyaSetuRepository? repository, AudioPlayer? player})
      : _repository = repository,
        _player = player ?? AudioPlayer() {
    _initPlayer();
  }

  AudioPlaybackState get state => _state;

  void _initPlayer() {
    _posSub = _player.onPositionChanged.listen((pos) {
      _state = _state.copyWith(position: pos);
      notifyListeners();
    });

    _durSub = _player.onDurationChanged.listen((dur) {
      _state = _state.copyWith(duration: dur);
      notifyListeners();
    });

    _stateSub = _player.onPlayerStateChanged.listen((playerState) {
      if (playerState == PlayerState.playing) {
        _state = _state.copyWith(state: AudioState.playing);
      } else if (playerState == PlayerState.paused) {
        _state = _state.copyWith(state: AudioState.paused);
      } else if (playerState == PlayerState.completed) {
        _state = _state.copyWith(state: AudioState.stopped, position: Duration.zero);
      }
      notifyListeners();
    });
  }

  /// Synthesizes and plays Odia speech stream via Sarvam AI voice endpoint.
  Future<void> playSynthesizedText({
    required String text,
    String languageCode = 'od-IN',
    String? speaker,
  }) async {
    if (_repository == null) {
      _simulatePlayback();
      return;
    }

    _state = _state.copyWith(state: AudioState.loading, errorMessage: null);
    notifyListeners();

    try {
      final audioBytes = await _repository.synthesizeSpeechAudio(
        TtsRequest(
          text: text,
          languageCode: languageCode,
          speaker: speaker,
          outputAudioCodec: 'mp3',
          speechSampleRate: 24000,
        ),
      );

      final uint8List = Uint8List.fromList(audioBytes);
      await _player.play(BytesSource(uint8List));
    } catch (e) {
      // In offline / error conditions, show clean non-crashing status
      _state = _state.copyWith(
        state: AudioState.error,
        errorMessage: 'Voice playback requires internet connection',
      );
      notifyListeners();
    }
  }

  void play() {
    if (_player.state == PlayerState.paused) {
      _player.resume();
    } else {
      _simulatePlayback();
    }
  }

  void pause() {
    _player.pause();
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

  void _simulatePlayback() {
    _state = _state.copyWith(state: AudioState.playing);
    notifyListeners();
  }

  void seek(Duration newPosition) {
    _player.seek(newPosition);
    _state = _state.copyWith(position: newPosition);
    notifyListeners();
  }

  void seekRelative(int seconds) {
    seek(_state.position + Duration(seconds: seconds));
  }

  void setSpeed(double speed) {
    _player.setPlaybackRate(speed);
    _state = _state.copyWith(speed: speed);
    notifyListeners();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
