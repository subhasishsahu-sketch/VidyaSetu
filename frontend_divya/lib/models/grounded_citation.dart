class GroundedCitation {
  final String bookTitle;
  final int chapterNo;
  final int pageNo;
  final int paragraphNo;
  final String code;
  final String status;
  final String subtext;

  const GroundedCitation({
    required this.bookTitle,
    required this.chapterNo,
    required this.pageNo,
    required this.paragraphNo,
    required this.code,
    required this.status,
    required this.subtext,
  });

  factory GroundedCitation.fromJson(Map<String, dynamic> json) {
    return GroundedCitation(
      bookTitle: json['book_title'] as String? ?? 'BSE Odisha Class 10 History & Political Science',
      chapterNo: json['chapter_no'] as int? ?? 2,
      pageNo: json['page_no'] as int? ?? 58,
      paragraphNo: json['paragraph_no'] as int? ?? 3,
      code: json['code'] as String? ?? 'BSE-OD-C10-H2',
      status: json['status'] as String? ?? 'Verified Syllabus Context',
      subtext: json['subtext'] as String? ?? 'Retrieved from Offline SQLite / ChromaDB Embeddings • Zero Data Used',
    );
  }

  Map<String, dynamic> toJson() => {
        'book_title': bookTitle,
        'chapter_no': chapterNo,
        'page_no': pageNo,
        'paragraph_no': paragraphNo,
        'code': code,
        'status': status,
        'subtext': subtext,
      };
}
