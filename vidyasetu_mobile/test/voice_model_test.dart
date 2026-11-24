import 'package:flutter_test/flutter_test.dart';
import 'package:vidyasetu_mobile/data/models/voice_model.dart';

void main() {
  group('Sarvam Voice Models & Contract Defaults', () {
    test('TtsRequest defaults match Sarvam specification', () {
      const req = TtsRequest(text: 'ନମସ୍କାର, ଆପଣ କେମିତି ଅଛନ୍ତି?');
      expect(req.languageCode, equals('od-IN'));
      expect(req.outputAudioCodec, equals('mp3'));
      expect(req.speechSampleRate, equals(24000));
      expect(req.pace, equals(1.0));
      expect(req.speaker, isNull);

      final json = req.toJson();
      expect(json['text'], equals('ନମସ୍କାର, ଆପଣ କେମିତି ଅଛନ୍ତି?'));
      expect(json['language_code'], equals('od-IN'));
      expect(json['output_audio_codec'], equals('mp3'));
      expect(json['speech_sample_rate'], equals(24000));
      expect(json.containsKey('speaker'), isFalse);
    });

    test('TtsRequest roundtrip with custom speaker', () {
      final req = TtsRequest.fromJson({
        'text': 'Hello students',
        'language_code': 'en-IN',
        'speaker': 'simran_en_edtech',
        'pace': 1.1,
        'output_audio_codec': 'wav',
        'speech_sample_rate': 16000,
      });

      expect(req.text, equals('Hello students'));
      expect(req.languageCode, equals('en-IN'));
      expect(req.speaker, equals('simran_en_edtech'));
      expect(req.pace, equals(1.1));
      expect(req.outputAudioCodec, equals('wav'));
      expect(req.speechSampleRate, equals(16000));
    });

    test('TtsResponse JSON serialization and deserialization', () {
      final res = TtsResponse.fromJson({
        'audio_base64': 'AAAA////',
        'audio_codec': 'mp3',
        'language_code': 'od-IN',
        'model': 'bulbul:v3',
        'speaker': 'odia_female_1',
      });

      expect(res.audioBase64, equals('AAAA////'));
      expect(res.audioCodec, equals('mp3'));
      expect(res.languageCode, equals('od-IN'));
      expect(res.model, equals('bulbul:v3'));
      expect(res.speaker, equals('odia_female_1'));

      final json = res.toJson();
      expect(json['audio_base64'], equals('AAAA////'));
      expect(json['audio_codec'], equals('mp3'));
    });

    test('SttResponse defaults to codemix and handles optional fields', () {
      final res = SttResponse.fromJson({
        'transcript': 'What is Five Year Plan?',
        'language_code': 'od-IN',
        'language_probability': 0.94,
        'mode': 'codemix',
        'model': 'saaras:v4',
      });

      expect(res.transcript, equals('What is Five Year Plan?'));
      expect(res.languageCode, equals('od-IN'));
      expect(res.languageProbability, equals(0.94));
      expect(res.mode, equals('codemix'));
      expect(res.model, equals('saaras:v4'));
    });
  });
}
