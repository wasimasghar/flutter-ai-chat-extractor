import 'package:equatable/equatable.dart';

/// One label-value pair pulled out of any text (bill, receipt, order...).
/// e.g. label: "Due Date", value: "15 Oct 2026"
class ExtractedField extends Equatable {
  final String label;
  final String value;

  const ExtractedField({required this.label, required this.value});

  factory ExtractedField.fromJson(Map<String, dynamic> json) {
    return ExtractedField(
      label: json['label']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [label, value];
}
