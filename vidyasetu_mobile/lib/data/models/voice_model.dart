/// Request payload for text-to-speech synthesis (Sarvam AI).
class TtsRequest {
  final String text;
  final String languageCode;
  final String? speaker;
  final double pace;
  final String outputAudioCodec;
  final int speechSampleRate;

  const TtsRequest({
    required this.text,
    this.languageCode = 'od-IN',
    this.speaker,
    this.pace = 1.0,
    this.outputAudioCodec = 'mp3',
    this.speechSampleRate = 24000,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'language_code': languageCode,
        if (speaker != null) 'speaker': speaker,
        'pace': pace,
        'output_audio_codec': outputAudioCodec,
        'speech_sample_rate': speechSampleRate,
      };

  factory TtsRequest.fromJson(Map<String, dynamic> json) => TtsRequest(
        text: json['text'] as String,
        languageCode: json['language_code'] as String? ?? 'od-IN',
        speaker: json['speaker'] as String?,
        pace: (json['pace'] as num?)?.toDouble() ?? 1.0,
        outputAudioCodec: json['output_audio_codec'] as String? ?? 'mp3',
        speechSampleRate: json['speech_sample_rate'] as int? ?? 24000,
      );
}

/// Response payload containing base64 encoded synthesized speech.
class TtsResponse {
  final String audioBase64;
  final String audioCodec;
  final String languageCode;
  final String model;
  final String speaker;

  const TtsResponse({
    required this.audioBase64,
    required this.audioCodec,
    required this.languageCode,
    required this.model,
    required this.speaker,
  });

  factory TtsResponse.fromJson(Map<String, dynamic> json) => TtsResponse(
        audioBase64: json['audio_base64'] as String,
        audioCodec: json['audio_codec'] as String? ?? 'mp3',
        languageCode: json['language_code'] as String? ?? 'od-IN',
        model: json['model'] as String? ?? 'bulbul:v3',
        speaker: json['speaker'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'audio_base64': audioBase64,
        'audio_codec': audioCodec,
        'language_code': languageCode,
        'model': model,
        'speaker': speaker,
      };
}

/// Response payload containing transcribed speech-to-text results.
class SttResponse {
  final String transcript;
  final String? languageCode;
  final double? languageProbability;
  final String mode;
  final String model;

  const SttResponse({
    required this.transcript,
    this.languageCode,
    this.languageProbability,
    required this.mode,
    required this.model,
  });

  factory SttResponse.fromJson(Map<String, dynamic> json) => SttResponse(
        transcript: json['transcript'] as String,
        languageCode: json['language_code'] as String?,
        languageProbability:
            (json['language_probability'] as num?)?.toDouble(),
        mode: json['mode'] as String? ?? 'codemix',
        model: json['model'] as String? ?? 'saaras:v4',
      );

  Map<String, dynamic> toJson() => {
        'transcript': transcript,
        if (languageCode != null) 'language_code': languageCode,
        if (languageProbability != null)
          'language_probability': languageProbability,
        'mode': mode,
        'model': model,
      };
}
