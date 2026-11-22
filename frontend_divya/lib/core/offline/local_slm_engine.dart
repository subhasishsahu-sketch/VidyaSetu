import 'dart:async';
import '../../data/models/diagnostic_model.dart';

/// Pluggable interface for on-device edge SLM generation.
abstract class LocalSlmEngine {
  /// Generates text from the given prompt.
  Future<String> generate({
    required String prompt,
    int maxTokens = 256,
  });

  /// Synthesizes the 3-Way Language Bridge intervention.
  Future<InterventionOutput> generateIntervention({
    required String chunkText,
    required List<KeyTermPair> importantEnglishTerms,
    required GroundedReference groundedReference,
    required int studentEnglishLevel,
    String? misconception,
    String? questionText,
  });
}

/// Deterministic, high-quality grounded offline fallback engine.
/// Synthesizes authentic Odia Unicode Script (ଓଡ଼ିଆ ଲିପି) with English technical terms inline.
/// Never generates Romanised Odia.
class GroundedFallbackSlmEngine implements LocalSlmEngine {
  const GroundedFallbackSlmEngine();

  @override
  Future<String> generate({
    required String prompt,
    int maxTokens = 256,
  }) async {
    // Deterministic fallback response for general text generation
    return 'ଏହା ବିଦ୍ୟାସେତୁ ଅଫଲାଇନ୍ ଶିକ୍ଷଣ ସହାୟକ ଅଟେ। (VidyaSetu Offline Academic Assistant).';
  }

  @override
  Future<InterventionOutput> generateIntervention({
    required String chunkText,
    required List<KeyTermPair> importantEnglishTerms,
    required GroundedReference groundedReference,
    required int studentEnglishLevel,
    String? misconception,
    String? questionText,
  }) async {
    final secHeading = groundedReference.sectionHeading ?? 'ମୁଖ୍ୟ ବିଷୟବସ୍ତୁ (Core Concept)';

    final bilingual = 'ଧାରଣା ବୁଝାମଣା ($secHeading):\n\n'
        '$chunkText\n\n'
        'ଶିକ୍ଷଣ ପରାମର୍ଶ (Learning Tip): ମନେରଖନ୍ତୁ, ପରୀକ୍ଷାରେ ଉଭୟ ଇଂରାଜୀ ବୈଷୟିକ ଶବ୍ଦ (English technical terms) '
        'ଓ ଏହାର ଓଡ଼ିଆ ଅର୍ଥ ବୁଝିବା ନିହାତି ଜରୁରୀ।';

    final pureOdia = _cleanOdiaText(chunkText).isNotEmpty
        ? _cleanOdiaText(chunkText)
        : 'ଏହି ପାଠ୍ୟ ବିଷୟବସ୍ତୁର ମୂଳ ଧାରଣାକୁ ସଠିକ୍ ଭାବରେ ମନେରଖନ୍ତୁ ଏବଂ ଅଭ୍ୟାସ କରନ୍ତୁ।';

    final termsSummary = importantEnglishTerms
        .where((t) => t.odiaMeaning.isNotEmpty)
        .take(4)
        .map((t) => '${t.englishTerm} (${t.odiaMeaning})')
        .join(', ');

    final pureEnglish =
        'According to ${groundedReference.textbookName} (Chapter ${groundedReference.chapterNo}), '
        "the topic '$secHeading' covers essential state curriculum concepts including "
        '${termsSummary.isNotEmpty ? termsSummary : 'fundamental principles'}. '
        'Mastering these definitions and laws ensures accurate exam recall.';

    return InterventionOutput(
      bilingualExplanationOdiaEnglish: bilingual,
      pureOdiaExplanation: pureOdia,
      pureEnglishExplanation: pureEnglish,
      englishTermsWithOdiaMeanings: importantEnglishTerms,
      groundedTextbookReference: groundedReference,
      recordedEnglishExposureLevel: studentEnglishLevel,
    );
  }

  /// Removes Latin characters from Odia text while preserving digits and punctuation.
  String _cleanOdiaText(String rawText) {
    // Remove parentheticals containing English words (e.g. '(Reflection of Light)')
    var cleaned = rawText.replaceAll(RegExp(r'\([A-Za-z\s,\-\./]+\)'), '');
    // Remove stray Latin characters
    cleaned = cleaned.replaceAll(RegExp(r'[A-Za-z]+'), '');
    // Remove empty parentheses
    cleaned = cleaned.replaceAll(RegExp(r'\(\s*\)'), '');
    // Clean spaces before punctuation
    cleaned = cleaned.replaceAll(RegExp(r'\s+([,.:;?!|।\)])'), r'\1');
    // Normalize spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned;
  }
}
