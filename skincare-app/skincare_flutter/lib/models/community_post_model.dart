class CommunityPost {
  final int    id;
  final String question;
  final String? details;
  final String category;
  final String? skinType;
  final int    likes;
  final int    answerCount;
  final String author;
  final DateTime createdAt;

  const CommunityPost({
    required this.id,
    required this.question,
    this.details,
    required this.category,
    this.skinType,
    required this.likes,
    required this.answerCount,
    required this.author,
    required this.createdAt,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> j) {
    return CommunityPost(
      id:          j['id'] as int,
      question:    j['question'] as String,
      details:     j['details'] as String?,
      category:    j['category'] as String,
      skinType:    j['skinType'] as String?,
      likes:       j['likes'] as int,
      answerCount: j['answerCount'] as int,
      author:      j['author'] as String,
      createdAt:   DateTime.parse(j['createdAt'] as String),
    );
  }
}

class CommunityAnswer {
  final int    id;
  final String answer;
  final int    isHelpful;
  final String author;
  final DateTime createdAt;

  const CommunityAnswer({
    required this.id,
    required this.answer,
    required this.isHelpful,
    required this.author,
    required this.createdAt,
  });

  factory CommunityAnswer.fromJson(Map<String, dynamic> j) {
    return CommunityAnswer(
      id:        j['id'] as int,
      answer:    j['answer'] as String,
      isHelpful: j['isHelpful'] as int,
      author:    j['author'] as String,
      createdAt: DateTime.parse(j['createdAt'] as String),
    );
  }
}

class CommunityPostDetail {
  final int    id;
  final String question;
  final String? details;
  final String category;
  final String? skinType;
  final int    likes;
  final String author;
  final DateTime createdAt;
  final List<CommunityAnswer> answers;

  const CommunityPostDetail({
    required this.id,
    required this.question,
    this.details,
    required this.category,
    this.skinType,
    required this.likes,
    required this.author,
    required this.createdAt,
    required this.answers,
  });

  factory CommunityPostDetail.fromJson(Map<String, dynamic> j) {
    return CommunityPostDetail(
      id:        j['id'] as int,
      question:  j['question'] as String,
      details:   j['details'] as String?,
      category:  j['category'] as String,
      skinType:  j['skinType'] as String?,
      likes:     j['likes'] as int,
      author:    j['author'] as String,
      createdAt: DateTime.parse(j['createdAt'] as String),
      answers:   (j['answers'] as List)
          .map((a) => CommunityAnswer.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}