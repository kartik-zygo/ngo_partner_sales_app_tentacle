import 'package:equatable/equatable.dart';

class RevenueRecord extends Equatable {
  const RevenueRecord({
    required this.id,
    required this.date,
    required this.amount,
    required this.source,
  });

  final String id;
  final DateTime date;
  final double amount;
  final String source;

  @override
  List<Object?> get props => [id, date, amount, source];
}
