import 'package:equatable/equatable.dart';

/// Model representing a report of a message
class ReportModel extends Equatable {
  final int? reportId;
  final int messageId;
  final int? reportedBy;
  final String? reason;
  final DateTime? reportedAt;

  const ReportModel({
    this.reportId,
    required this.messageId,
    this.reportedBy,
    this.reason,
    this.reportedAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    // Helper to safely convert to int
    int? toInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return ReportModel(
      reportId: toInt(json['report_id']),
      messageId: toInt(json['message_id']) ?? 0,
      reportedBy: toInt(json['reported_by']),
      reason: json['reason'] as String?,
      reportedAt: json['reported_at'] != null
          ? DateTime.parse(json['reported_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'reportedBy': reportedBy,
      'reason': reason,
    };
  }

  @override
  List<Object?> get props =>
      [reportId, messageId, reportedBy, reason, reportedAt];
}
