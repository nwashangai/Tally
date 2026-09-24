import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// Strongly-typed identifier for a Receiving transaction.
class ReceivingId extends Equatable {
  final String value;

  const ReceivingId(this.value);

  factory ReceivingId.generate() {
    return ReceivingId(const Uuid().v4());
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
