class GeminiResponse {
  final List<Candidate> candidates;
  final UsageMetadata? usageMetadata;
  final String? modelVersion;
  final String? responseId;

  GeminiResponse({
    required this.candidates,
    this.usageMetadata,
    this.modelVersion,
    this.responseId,
  });

  factory GeminiResponse.fromJson(Map<String, dynamic> json) {
    return GeminiResponse(
      candidates: (json['candidates'] as List<dynamic>? ?? [])
          .map((e) => Candidate.fromJson(e as Map<String, dynamic>))
          .toList(),
      usageMetadata: json['usageMetadata'] != null
          ? UsageMetadata.fromJson(json['usageMetadata'] as Map<String, dynamic>)
          : null,
      modelVersion: json['modelVersion'] as String?,
      responseId: json['responseId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'candidates': candidates.map((e) => e.toJson()).toList(),
        if (usageMetadata != null) 'usageMetadata': usageMetadata!.toJson(),
        if (modelVersion != null) 'modelVersion': modelVersion,
        if (responseId != null) 'responseId': responseId,
      };

  /// Convenience: first candidate's text, or empty string.
  String get text {
    if (candidates.isEmpty) return '';
    final parts = candidates.first.content?.parts;
    if (parts == null || parts.isEmpty) return '';
    return parts.map((p) => p.text ?? '').join();
  }
}

class Candidate {
  final Content? content;
  final String? finishReason;
  final int? index;

  Candidate({
    this.content,
    this.finishReason,
    this.index,
  });

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      content: json['content'] != null
          ? Content.fromJson(json['content'] as Map<String, dynamic>)
          : null,
      finishReason: json['finishReason'] as String?,
      index: json['index'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (content != null) 'content': content!.toJson(),
        if (finishReason != null) 'finishReason': finishReason,
        if (index != null) 'index': index,
      };
}

class Content {
  final List<Part> parts;
  final String? role;

  Content({
    required this.parts,
    this.role,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      parts: (json['parts'] as List<dynamic>? ?? [])
          .map((e) => Part.fromJson(e as Map<String, dynamic>))
          .toList(),
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'parts': parts.map((e) => e.toJson()).toList(),
        if (role != null) 'role': role,
      };
}

class Part {
  final String? text;

  Part({this.text});

  factory Part.fromJson(Map<String, dynamic> json) {
    return Part(text: json['text'] as String?);
  }

  Map<String, dynamic> toJson() => {
        if (text != null) 'text': text,
      };
}

class UsageMetadata {
  final int? promptTokenCount;
  final int? candidatesTokenCount;
  final int? totalTokenCount;
  final List<PromptTokensDetail>? promptTokensDetails;
  final int? thoughtsTokenCount;
  final String? serviceTier;

  UsageMetadata({
    this.promptTokenCount,
    this.candidatesTokenCount,
    this.totalTokenCount,
    this.promptTokensDetails,
    this.thoughtsTokenCount,
    this.serviceTier,
  });

  factory UsageMetadata.fromJson(Map<String, dynamic> json) {
    return UsageMetadata(
      promptTokenCount: json['promptTokenCount'] as int?,
      candidatesTokenCount: json['candidatesTokenCount'] as int?,
      totalTokenCount: json['totalTokenCount'] as int?,
      promptTokensDetails: (json['promptTokensDetails'] as List<dynamic>?)
          ?.map((e) => PromptTokensDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      thoughtsTokenCount: json['thoughtsTokenCount'] as int?,
      serviceTier: json['serviceTier'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (promptTokenCount != null) 'promptTokenCount': promptTokenCount,
        if (candidatesTokenCount != null)
          'candidatesTokenCount': candidatesTokenCount,
        if (totalTokenCount != null) 'totalTokenCount': totalTokenCount,
        if (promptTokensDetails != null)
          'promptTokensDetails':
              promptTokensDetails!.map((e) => e.toJson()).toList(),
        if (thoughtsTokenCount != null)
          'thoughtsTokenCount': thoughtsTokenCount,
        if (serviceTier != null) 'serviceTier': serviceTier,
      };

  bool get hasTokenCounts =>
      promptTokenCount != null ||
      candidatesTokenCount != null ||
      thoughtsTokenCount != null;
}

class PromptTokensDetail {
  final String? modality;
  final int? tokenCount;

  PromptTokensDetail({this.modality, this.tokenCount});

  factory PromptTokensDetail.fromJson(Map<String, dynamic> json) {
    return PromptTokensDetail(
      modality: json['modality'] as String?,
      tokenCount: json['tokenCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (modality != null) 'modality': modality,
        if (tokenCount != null) 'tokenCount': tokenCount,
      };
}

