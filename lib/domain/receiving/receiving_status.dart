/// Represents the operational state of a Receiving transaction.
enum ReceivingStatus {
  draft('draft', 'Draft'),
  completed('completed', 'Completed'),
  voided('voided', 'Voided');

  final String value;
  final String label;

  const ReceivingStatus(this.value, this.label);

  static ReceivingStatus fromValue(String value) {
    return ReceivingStatus.values.firstWhere(
      (s) => s.value.toLowerCase() == value.toLowerCase(),
      orElse: () => ReceivingStatus.draft,
    );
  }

  bool get isDraft => this == ReceivingStatus.draft;
  bool get isCompleted => this == ReceivingStatus.completed;
  bool get isVoided => this == ReceivingStatus.voided;
}
