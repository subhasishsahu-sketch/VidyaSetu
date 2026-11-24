import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/student.dart';
import '../../models/subject.dart';
import '../../models/question.dart';
import '../../models/answer_option.dart';
import '../../models/diagnostic_result.dart';
import '../../models/explanation.dart';
import '../../models/grounded_citation.dart';
import '../../models/study_plan.dart';

/// Centralized Local Mock Data Store
/// Loads sample JSON data from assets or fallback memory models.
/// Isolates UI components and provides fallback data for offline preview and tests.
class MockDataStore {
  static Student? _cachedStudent;
  static List<Subject>? _cachedSubjects;
  static Map<String, dynamic>? _cachedRoadmapRaw;
  static List<Question>? _cachedQuestions;
  static Map<String, dynamic>? _cachedDiagnosisRaw;
  static Map<String, dynamic>? _cachedExplanationsRaw;
  static StudyPlan? _cachedStudyPlan;

  static Future<Student> getStudent() async {
    if (_cachedStudent != null) return _cachedStudent!;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/student.json');
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      _cachedStudent = Student.fromJson(map);
      return _cachedStudent!;
    } catch (_) {
      return const Student(
        studentId: '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d',
        name: 'Sunita',
        classGrade: 10,
        board: 'BSE Odisha',
        preferredLanguage: 'Odia',
        englishExposureLevel: 1,
        subject: 'History',
        dailyGoalMinutes: 15,
        completedMinutes: 10,
        remainingMinutes: 5,
        goalPercentage: 65,
        streakDays: 7,
        schoolMeshPeersSynced: 22,
        offlineSlmActive: true,
        activeChapter: ActiveChapter(
          subject: 'History',
          titleEn: 'India After Independence',
          titleOr: 'ସ୍ୱାଧୀନତା ପରବର୍ତ୍ତୀ ଭାରତ',
          chapterNo: 1,
          sectionNo: 2,
          status: 'Ready Offline',
        ),
      );
    }
  }

  static Future<List<Subject>> getSubjects() async {
    if (_cachedSubjects != null) return _cachedSubjects!;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/subjects.json');
      final list = jsonDecode(jsonStr) as List<dynamic>;
      _cachedSubjects = list
          .map((e) => Subject.fromJson(e as Map<String, dynamic>))
          .toList();
      return _cachedSubjects!;
    } catch (_) {
      return const [
        Subject(
          id: 'hist',
          nameEn: 'History',
          nameOr: 'ଇତିହାସ',
          code: 'HIST',
          icon: 'account_balance',
          totalChapters: 4,
          completedChapters: 1,
          masteryPercent: 88,
          isCached: true,
        ),
        Subject(
          id: 'phys',
          nameEn: 'Physical Science',
          nameOr: 'ଭୌତିକ ବିଜ୍ଞାନ',
          code: 'PHYS',
          icon: 'bolt',
          totalChapters: 6,
          completedChapters: 2,
          masteryPercent: 74,
          isCached: true,
        ),
        Subject(
          id: 'bio',
          nameEn: 'Life Science',
          nameOr: 'ଜୀବ ବିଜ୍ଞାନ',
          code: 'BIO',
          icon: 'eco',
          totalChapters: 5,
          completedChapters: 1,
          masteryPercent: 68,
          isCached: true,
        ),
        Subject(
          id: 'math',
          nameEn: 'Mathematics',
          nameOr: 'ଗଣିତ',
          code: 'MATH',
          icon: 'calculate',
          totalChapters: 8,
          completedChapters: 3,
          masteryPercent: 82,
          isCached: true,
        ),
      ];
    }
  }

  static Future<Map<String, dynamic>> getRoadmapRaw() async {
    if (_cachedRoadmapRaw != null) return _cachedRoadmapRaw!;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/roadmap.json');
      _cachedRoadmapRaw = jsonDecode(jsonStr) as Map<String, dynamic>;
      return _cachedRoadmapRaw!;
    } catch (_) {
      return {
        "subject_id": "hist",
        "subject_name_en": "History",
        "subject_name_or": "ଇତିହାସ",
        "overall_milestone": {
          "cleared_units": 1,
          "total_units": 4,
          "exam_target_percent": 85,
          "current_progress_percent": 42
        },
        "completed_chapters": [
          {
            "chapter_id": "HIST_CH1",
            "chapter_no": 1,
            "title_en": "Integration of Princely States",
            "title_or": "ଦେଶୀୟ ରାଜ୍ୟ ମିଶ୍ରଣ",
            "mastery_percent": 88,
            "events_mapped": "12/12 Key events mapped",
            "cleared_date": "14 Oct",
            "status": "completed"
          }
        ],
        "current_chapter": {
          "chapter_id": "HIST_CH2",
          "chapter_no": 2,
          "title_en": "India After Independence & Planning Commission",
          "title_or": "ଭାରତର ଆର୍ଥିକ ବିକାଶ, ପଞ୍ଚବାର୍ଷିକ ଯୋଜନା ଓ ଯୋଜନା ଆୟୋଗର ଭୂମିକା।",
          "status": "in_progress",
          "estimated_mins_left": 35,
          "cleared_topics_count": 3,
          "total_topics_count": 5,
          "progress_percent": 60,
          "topics": [
            {
              "topic_id": "HIST_CH2_T1",
              "title_en": "Post-Partition Challenges & Relief Measures",
              "title_or": "ଦେଶ ବିଭାଜନ ପରବର୍ତ୍ତୀ ଆହ୍ୱାନ ଓ ଥଇଥାନ",
              "status": "completed",
              "status_label": "Completed"
            },
            {
              "topic_id": "HIST_CH2_T2",
              "title_en": "First Five-Year Plan & Agrarian Reforms",
              "title_or": "ପ୍ରଥମ ପଞ୍ଚବାର୍ଷିକ ଯୋଜନା ଓ କୃଷି ସଂସ୍କାର",
              "status": "completed",
              "status_label": "Completed"
            },
            {
              "topic_id": "HIST_CH2_T3",
              "title_en": "Green Revolution & Odisha",
              "title_or": "ସବୁଜ ବିପ୍ଳବ ଏବଂ ରାଉରକେଲା ଇସ୍ପାତ କାରଖାନା",
              "status": "active_focus",
              "status_label": "Current"
            },
            {
              "topic_id": "HIST_CH2_T4",
              "title_en": "Industrial Policy Resolution of 1956",
              "title_or": "୧୯୫୬ ଶିଳ୍ପ ନୀତି ପ୍ରସ୍ତାବ",
              "status": "locked",
              "status_label": "Up next"
            },
            {
              "topic_id": "HIST_CH2_T5",
              "title_en": "Chapter Diagnostic Mastery Assessment",
              "title_or": "ଅଧ୍ୟାୟ ଭିତ୍ତିକ ଦକ୍ଷତା ମୂଲ୍ୟାଙ୍କନ",
              "status": "final_assessment",
              "status_label": "Final"
            }
          ],
          "audio_explainer": {
            "title": "AUDIO EXPLAINER READY",
            "heading": "Rourkela Steel Plant & Green Revolution",
            "description": "Listen in Odia voice assistant (10 mins)"
          }
        },
        "next_goals": [
          {
            "chapter_id": "HIST_CH3",
            "chapter_no": 3,
            "title_en": "India's Foreign Policy & NAM",
            "title_or": "ଭାରତର ବୈଦେଶିକ ନୀତି ଏବଂ ଗୋଷ୍ଠୀ ନିରପେକ୍ଷ ଆନ୍ଦୋଳନ",
            "topics_count": 5,
            "lock_reason": "Unlocks after completing Chapter 2 diagnostic test"
          },
          {
            "chapter_id": "HIST_CH4",
            "chapter_no": 4,
            "title_en": "Odisha's Formation & State Reorganisation",
            "title_or": "ସ୍ୱତନ୍ତ୍ର ଓଡ଼ିଶା ପ୍ରଦେଶ ଗଠନ ଓ ରାଜ୍ୟ ପୁନର୍ଗଠନ ଆଇନ",
            "topics_count": 4,
            "lock_reason": "Unlocks after completing Chapter 3"
          }
        ]
      };
    }
  }

  static Future<List<Question>> getQuestions() async {
    if (_cachedQuestions != null) return _cachedQuestions!;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/questions.json');
      final list = jsonDecode(jsonStr) as List<dynamic>;
      _cachedQuestions = list
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList();
      return _cachedQuestions!;
    } catch (_) {
      return const [
        Question(
          id: 'HIST_CH2_Q01',
          stepNumber: 1,
          totalSteps: 5,
          subject: 'History',
          topic: 'Post-Partition Challenges',
          typeBadgeEn: 'Q1 • Objective Type (1 Mark)',
          typeBadgeOr: 'ପ୍ର୧ • ବସ୍ତୁନିଷ୍ଠ ପ୍ରଶ୍ନ (୧ ମାର୍କ)',
          standard: 'BSE Odisha Standard',
          questionTextEn:
              'In which year did India adopt its Constitution, becoming a sovereign democratic republic?',
          questionTextOr:
              'କେଉଁ ବର୍ଷ ଭାରତ ନିଜର ସମ୍ବିଧାନ ଗ୍ରହଣ କରି ଏକ ସାର୍ବଭୌମ ଗଣତାନ୍ତ୍ରିକ ଗଣରାଜ୍ୟ ହେଲା?',
          options: [
            AnswerOption(id: 'A', textEn: '1947', textOr: '୧୯୪୭'),
            AnswerOption(id: 'B', textEn: '1950', textOr: '୧୯୫୦'),
            AnswerOption(id: 'C', textEn: '1952', textOr: '୧୯୫୨'),
            AnswerOption(id: 'D', textEn: '1948', textOr: '୧୯୪୮'),
          ],
          correctOptionId: 'B',
        ),
        Question(
          id: 'HIST_CH2_Q02',
          stepNumber: 2,
          totalSteps: 5,
          subject: 'History',
          topic: 'First Five-Year Plan',
          typeBadgeEn: 'Q2 • Objective Type (1 Mark)',
          typeBadgeOr: 'ପ୍ର୨ • ବସ୍ତୁନିଷ୍ଠ ପ୍ରଶ୍ନ (୧ ମାର୍କ)',
          standard: 'BSE Odisha Standard',
          questionTextEn:
              'What was the primary sector emphasized during India\'s First Five-Year Plan?',
          questionTextOr:
              'ଭାରତର ପ୍ରଥମ ପଞ୍ଚବାର୍ଷିକ ଯୋଜନାରେ ମୁଖ୍ୟତଃ କେଉଁ କ୍ଷେତ୍ର ଉପରେ ଗୁରୁତ୍ୱ ଦିଆଯାଇଥିଲା?',
          options: [
            AnswerOption(
                id: 'A',
                textEn: 'Agriculture & Irrigation',
                textOr: 'କୃଷି ଓ ଜଳସେଚନ'),
            AnswerOption(
                id: 'B', textEn: 'Heavy Industries', textOr: 'ଭାରୀ ଶିଳ୍ପ'),
            AnswerOption(
                id: 'C',
                textEn: 'Information Technology',
                textOr: 'ସୂଚନା ପ୍ରଯୁକ୍ତିବିଦ୍ୟା'),
            AnswerOption(
                id: 'D', textEn: 'Foreign Trade', textOr: 'ବୈଦେଶିକ ବାଣିଜ୍ୟ'),
          ],
          correctOptionId: 'A',
        ),
        Question(
          id: 'HIST_CH2_Q03',
          stepNumber: 3,
          totalSteps: 5,
          subject: 'History',
          topic: 'Economic Planning & Five-Year Plans',
          typeBadgeEn: 'Q3 • Objective Type (1 Mark)',
          typeBadgeOr: 'ପ୍ର୩ • ବସ୍ତୁନିଷ୍ଠ ପ୍ରଶ୍ନ (୧ ମାର୍କ)',
          standard: 'BSE Odisha Standard',
          questionTextEn:
              'Which commission was responsible for the economic planning of Odisha from 1951 to 1962?',
          questionTextOr:
              '୧୯୫୧ ରୁ ୧୯୬୨ ପର୍ଯ୍ୟନ୍ତ ଓଡ଼ିଶାର ଆର୍ଥିକ ଯୋଜନା ପାଇଁ କେଉଁ ସଂସ୍ଥା ଦାୟୀ ଥିଲା?',
          options: [
            AnswerOption(
                id: 'A',
                textEn: 'Planning Commission of India',
                textOr: 'ଭାରତର ଯୋଜନା ଆୟୋଗ'),
            AnswerOption(
                id: 'B',
                textEn: 'Odisha Planning Commission',
                textOr: 'ଓଡ଼ିଶା ଯୋଜନା ଆୟୋଗ'),
            AnswerOption(
                id: 'C',
                textEn: 'State Planning Board',
                textOr: 'ରାଜ୍ୟ ଯୋଜନା ବୋର୍ଡ'),
            AnswerOption(
                id: 'D',
                textEn: 'Development Council',
                textOr: 'ବିକାଶ ପରିଷଦ'),
          ],
          correctOptionId: 'C',
        ),
        Question(
          id: 'HIST_CH2_Q04',
          stepNumber: 4,
          totalSteps: 5,
          subject: 'History',
          topic: 'Industrial Policy & Odisha',
          typeBadgeEn: 'Q4 • Objective Type (1 Mark)',
          typeBadgeOr: 'ପ୍ର୪ • ବସ୍ତୁନିଷ୍ଠ ପ୍ରଶ୍ନ (୧ ମାର୍କ)',
          standard: 'BSE Odisha Standard',
          questionTextEn:
              'Which major public steel plant in Odisha was established with German technical collaboration under the Second Five-Year Plan?',
          questionTextOr:
              'ଦ୍ୱିତୀୟ ପଞ୍ଚବାର୍ଷିକ ଯୋଜନାରେ ଜର୍ମାନୀ ସହଯୋଗରେ ଓଡ଼ିଶାର କେଉଁ ପ୍ରମୁଖ ଇସ୍ପାତ କାରଖାନା ସ୍ଥାପନ କରାଯାଇଥିଲା?',
          options: [
            AnswerOption(
                id: 'A',
                textEn: 'Bhilai Steel Plant',
                textOr: 'ଭିଲାଇ ଇସ୍ପାତ କାରଖାନା'),
            AnswerOption(
                id: 'B',
                textEn: 'Rourkela Steel Plant',
                textOr: 'ରାଉରକେଲା ଇସ୍ପାତ କାରଖାନା'),
            AnswerOption(
                id: 'C',
                textEn: 'Durgapur Steel Plant',
                textOr: 'ଦୁର୍ଗାପୁର ଇସ୍ପାତ କାରଖାନା'),
            AnswerOption(
                id: 'D',
                textEn: 'Bokaro Steel Plant',
                textOr: 'ବୋକାରୋ ଇସ୍ପାତ କାରଖାନା'),
          ],
          correctOptionId: 'B',
        ),
        Question(
          id: 'HIST_CH2_Q05',
          stepNumber: 5,
          totalSteps: 5,
          subject: 'History',
          topic: 'Agrarian Development & Dams',
          typeBadgeEn: 'Q5 • Objective Type (1 Mark)',
          typeBadgeOr: 'ପ୍ର୫ • ବସ୍ତୁନିଷ୍ଠ ପ୍ରଶ୍ନ (୧ ମାର୍କ)',
          standard: 'BSE Odisha Standard',
          questionTextEn:
              'Hirakud Multipurpose Dam project on river Mahanadi was initiated under which five-year plan period?',
          questionTextOr:
              'ମହାନଦୀ ଉପରେ ହୀରାକୁଦ ବହୁମୁଖୀ ନଦୀବନ୍ଧ ଯୋଜନା କେଉଁ ପଞ୍ଚବାର୍ଷିକ ଯୋଜନା କାଳରେ କାର୍ଯ୍ୟକାରୀ ହୋଇଥିଲା?',
          options: [
            AnswerOption(
                id: 'A',
                textEn: 'First Five-Year Plan',
                textOr: 'ପ୍ରଥମ ପଞ୍ଚବାର୍ଷିକ ଯୋଜନା'),
            AnswerOption(
                id: 'B',
                textEn: 'Third Five-Year Plan',
                textOr: 'ତୃତୀୟ ପଞ୍ଚବାର୍ଷିକ ଯୋଜନା'),
            AnswerOption(
                id: 'C',
                textEn: 'Fourth Five-Year Plan',
                textOr: 'ଚତୁର୍ଥ ପଞ୍ଚବାର୍ଷିକ ଯୋଜନା'),
            AnswerOption(
                id: 'D', textEn: 'Rolling Plan', textOr: 'ରୋଲିଂ ପ୍ଲାନ୍'),
          ],
          correctOptionId: 'A',
        ),
      ];
    }
  }

  static Future<DiagnosticResult> getDiagnosticResult(String questionId) async {
    try {
      if (_cachedDiagnosisRaw == null) {
        final jsonStr = await rootBundle.loadString('assets/data/diagnosis.json');
        _cachedDiagnosisRaw = jsonDecode(jsonStr) as Map<String, dynamic>;
      }
      final raw = _cachedDiagnosisRaw![questionId];
      if (raw != null) {
        return DiagnosticResult.fromJson(raw as Map<String, dynamic>);
      }
    } catch (_) {}
    return const DiagnosticResult(
      questionId: 'HIST_CH2_Q03',
      diagnosisTitle: 'Careless Terminology Confusion',
      diagnosisTitleOr: 'ଅସାବଧାନତା ଜନିତ ଶବ୍ଦାବଳୀ ଭ୍ରାନ୍ତି',
      certaintyPercent: 94,
      sourceEngine: 'Causal Error Mapping • VidyaSetu Cognitive Engine',
      causalWhyTitle: 'କାହିଁକି ଏହି ଭୁଲ୍ ହେଲା? (Causal Why)',
      causalWhyEn:
          'You remembered the timeline (1951) accurately, but confused the official statutory name State Planning Board with the colloquial translation Odisha Planning Commission.\n\nIn the BSE Odisha Class 10 textbook (Chapter 2, Page 43), the apex state organ was formally instituted as the "State Planning Board" (ରାଜ୍ୟ ଯୋଜନା ବୋର୍ଡ) to bridge local targets with Central Five-Year allocations.',
      causalWhyOr:
          'ଆପଣ ସମୟରେଖା (୧୯୫୧) ସଠିକ୍ ଭାବେ ମନେ ରଖିଥିଲେ, କିନ୍ତୁ ଆନୁଷ୍ଠାନିକ ବୈଧାନିକ ନାମ \'ରାଜ୍ୟ ଯୋଜନା ବୋର୍ଡ\' ଏବଂ କଥିତ ଅନୁବାଦ \'ଓଡ଼ିଶା ଯୋଜନା ଆୟୋଗ\' ମଧ୍ୟରେ ଦ୍ୱନ୍ଦ୍ୱରେ ପଡ଼ିଲେ।\n\nBSE ଓଡ଼ିଶା ଦଶମ ଶ୍ରେଣୀ ପାଠ୍ୟପୁସ୍ତକ (ଅଧ୍ୟାୟ ୨, ପୃଷ୍ଠା ୪୩) ଅନୁଯାୟୀ, କେନ୍ଦ୍ରୀୟ ପଞ୍ଚବାର୍ଷିକ ଯୋଜନା ସହିତ ସମନ୍ୱୟ ରଖିବା ପାଇଁ ରାଜ୍ୟର ଶୀର୍ଷ ସଂସ୍ଥା ଭାବେ "ରାଜ୍ୟ ଯୋଜନା ବୋର୍ଡ" ଗଠନ କରାଯାଇଥିଲା।',
      citation: 'BSE Ch 2: Independent Odisha Eco... Pg. 43 § 2.4',
      dbStorageBadge:
          'Diagnostics indexed locally in SQLite DB (32KB cached) • Auto-saved',
    );
  }

  static Future<Explanation> getExplanation(String questionId) async {
    try {
      if (_cachedExplanationsRaw == null) {
        final jsonStr =
            await rootBundle.loadString('assets/data/explanations.json');
        _cachedExplanationsRaw = jsonDecode(jsonStr) as Map<String, dynamic>;
      }
      final raw = _cachedExplanationsRaw![questionId];
      if (raw != null) {
        return Explanation.fromJson(raw as Map<String, dynamic>);
      }
    } catch (_) {}
    return const Explanation(
      questionId: 'HIST_CH2_Q03',
      title: 'State Planning Board vs Plan...',
      subHeader: 'CONCEPT REPAIR • QUESTION 3 BREAKDOWN',
      mistakeTag: 'Mistake Detected: Central vs State jurisdiction confusion',
      subjectTag: 'Class 10 Polity',
      bilingualMix:
          'Planning Commission (ଯୋଜନା ଆୟୋଗ) ର ମୁଖ୍ୟ କାମ ଥିଲା India ପାଇଁ Five Year Plans (ପଞ୍ଚବାର୍ଷିକ ଯୋଜନା) ପ୍ରସ୍ତୁତ କରିବା। Odisha ରେ Green Revolution (ସବୁଜ ବିପ୍ଳବ) ଏବଂ Major Industries ଯେପରି Rourkela Steel Plant ପ୍ରତିଷ୍ଠା ପାଇଁ Mixed Economy model follow କରାଯାଉଥିଲା। ରାଜ୍ୟ ସ୍ତରରେ ସମ୍ବଳ ବଣ୍ଟନ ଓ ଯୋଜନା ପ୍ରସ୍ତୁତି State Planning Board ଦ୍ୱାରା ହୋଇଥିଲା।',
      pureOdia:
          'କେନ୍ଦ୍ର ସ୍ତରରେ ଯୋଜନା ଆୟୋଗର ମୁଖ୍ୟ କାର୍ଯ୍ୟ ଥିଲା ସମଗ୍ର ଭାରତ ପାଇଁ ପଞ୍ଚବାର୍ଷିକ ଯୋଜନା ପ୍ରଣୟନ କରିବା। ଏହାଦ୍ୱାରା ଓଡ଼ିଶାରେ ରାଉରକେଲା ଇସ୍ପାତ କାରଖାନା ଭଳି ବୃହତ ଶିଳ୍ପ ଓ ସବୁଜ ବିପ୍ଳବ କାର୍ଯ୍ୟକାରୀ ହୋଇଥିଲା। ଅନ୍ୟପକ୍ଷରେ, ରାଜ୍ୟ ସ୍ତରରେ ବିକାଶ ଓ ସମ୍ବଳର ଉପଯୁକ୍ତ ବଣ୍ଟନ ପାଇଁ ରାଜ୍ୟ ଯୋଜନା ବୋର୍ଡ ଦାୟୀ ଥିଲା।',
      pureEnglish:
          'The primary function of the Planning Commission was to formulate Five Year Plans at the National level for India. It guided major initiatives such as the Green Revolution and large-scale industrial projects like the Rourkela Steel Plant in Odisha. At the sub-national level, allocation of local resources and decentralized state policies were spearheaded by the State Planning Board.',
      comparisonCards: [
        ComparisonCardData(
          title: 'Planning Commission',
          scope: 'Central Level (National Scope • ଦେଶ ସ୍ତରୀୟ)',
          colorType: 'primary',
        ),
        ComparisonCardData(
          title: 'State Planning Board',
          scope: 'Odisha State Level (ରାଜ୍ୟ ସ୍ତରୀୟ ସମ୍ବଳ ବଣ୍ଟନ)',
          colorType: 'terracotta',
        ),
      ],
      groundedCitation: GroundedCitation(
        bookTitle: 'BSE Odisha Class 10 History & Political Science',
        chapterNo: 2,
        pageNo: 58,
        paragraphNo: 3,
        code: 'BSE-OD-C10-H2',
        status: 'Verified Syllabus Context',
        subtext: 'Retrieved from Offline SQLite / ChromaDB Embeddings • Zero Data Used',
      ),
      historicalReference: HistoricalReference(
        location: 'Rourkela, Odisha Case Study',
        description:
            'Established under India\'s 2nd Five Year Plan for rapid industrial growth...',
        archiveLabel: 'Historic Reference Archive',
      ),
      audio: AudioMeta(
        title: 'Listen in Odia Voice (ଓଡ଼ିଆରେ ଶୁଣନ୍ତୁ)',
        badge: 'Offline Edge TTS',
        currentTime: '01:24',
        totalTime: '02:40',
        currentSeconds: 84,
        totalSeconds: 160,
      ),
      insight:
          'Great insight! Remembering that Central plans the nation while States implement regional priorities will help you in Question 5 too.',
    );
  }

  static Future<StudyPlan> getStudyPlan() async {
    if (_cachedStudyPlan != null) return _cachedStudyPlan!;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/replans.json');
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      _cachedStudyPlan = StudyPlan.fromJson(map);
      return _cachedStudyPlan!;
    } catch (_) {
      return const StudyPlan(
        auditStatus: 'AUTONOMOUS AUDIT COMPLETE',
        engineStatus: 'Local SLM Active',
        title: 'Adaptive Replan & Offline Recovery',
        subtitle: "Sunita's Intelligent Study Engine • BSE Odisha Class 10",
        resolvedGap:
            'Resolved pinpoint gap: 5-Year Plans vs State Board terminology in History Section B.',
        step4Replan: Step4Replan(
          stepLabel: 'STEP 4 • AUTONOMOUS REPLAN',
          title: 'Study Plan Updated Automatically',
          description:
              'Based on your terminology confusion in Question 3, the local agent has seamlessly adapted your personalized roadmap for maximum retention.',
          microLesson: MicroLesson(
            tag: 'SCHEDULED 8-MIN MICRO-LESSON',
            title: 'Five-Year Plans & Odisha\'s Industrial ...',
            focus: 'Focus: Rourkela Steel Plant & Hirakud Dam integration',
            slot: 'Tomorrow 7:00 AM • 15-min phone slot',
            projectedGain: '+12 projected marks in Section B',
            pacingNote:
                '“Syllabus pacing adjusted: You will cover this before tackling the 1971 Industrial Policy module.”',
          ),
        ),
        step5Storage: Step5Storage(
          stepLabel: 'STEP 5 • STORAGE VERIFIED',
          title: 'Offline Diagnostic Pack Cached',
          details:
              '5 Diagnostic Flashcards & 3 MCQs Cached into Device Storage',
          networkBadge: '0 KB Internet Needed',
          commitId: 'SQLite local commit #BSE-402',
          storageUsed: 'Storage used: 142 KB in local SQLite',
          readyPercent: '100% Ready',
          checkpoints: [
            'Odia & English Audio Explanation Cached',
            'Text Flashcards Ready with Vernacular Hints',
            'Zero-Lag Offline Practice Session Prepared',
          ],
        ),
        step6Quiz: Step6Quiz(
          stepLabel: 'STEP 6 • ACTION READY',
          title: 'Recovery Quiz Ready',
          description:
              'Test yourself on Planning Commission vs State Planning Board right now to regain your lost mastery score and keep your streak alive.',
          estimatedTime: '2 Minutes (3 Quick MCQs)',
          rewardXp: '+100 XP',
          buttonLabel: 'Take 2-Min Recovery Check ➔',
          secondaryLabel: 'Back to Home / ମୁଖ୍ୟ ପୃଷ୍ଠାକୁ ଫେରନ୍ତୁ',
        ),
        footerSync:
            'School Mesh Auto-Sync Enabled • Will sync scores with master tablet when at school',
      );
    }
  }
}
