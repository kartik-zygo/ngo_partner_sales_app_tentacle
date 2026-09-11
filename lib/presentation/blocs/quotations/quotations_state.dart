import 'package:equatable/equatable.dart';

import '../../../domain/entities/quotation_request.dart';

enum QuotationsStatus { initial, loading, ready, failure }

class QuotationsState extends Equatable {
  const QuotationsState({
    this.status = QuotationsStatus.initial,
    this.quotations = const [],
    this.salesReps = const [],
    this.assignedToFilter,
    this.statusFilter,
    this.search = '',
    this.selected,
    this.isDetailLoading = false,
    this.isMutating = false,
    this.unseenCount = 0,
    this.message,
    this.errorMessage,
  });

  final QuotationsStatus status;
  final List<QuotationRequest> quotations;
  final List<SalesRepOption> salesReps;

  /// A rep's UUID, `me`, or `unassigned`.
  final String? assignedToFilter;
  final String? statusFilter;
  final String search;

  /// The full record behind the open detail sheet, with notes and activity.
  final QuotationRequest? selected;
  final bool isDetailLoading;

  /// True while an assign / status / note call is in flight.
  final bool isMutating;

  /// `quotation:submitted` events since the inbox was last looked at.
  final int unseenCount;
  final String? message;
  final String? errorMessage;

  bool get isLoading => status == QuotationsStatus.loading;

  int get unassignedCount => quotations.where((q) => q.isUnassigned).length;

  QuotationsState copyWith({
    QuotationsStatus? status,
    List<QuotationRequest>? quotations,
    List<SalesRepOption>? salesReps,
    String? assignedToFilter,
    String? statusFilter,
    bool clearAssignedToFilter = false,
    bool clearStatusFilter = false,
    String? search,
    QuotationRequest? selected,
    bool clearSelected = false,
    bool? isDetailLoading,
    bool? isMutating,
    int? unseenCount,
    String? message,
    String? errorMessage,
  }) {
    return QuotationsState(
      status: status ?? this.status,
      quotations: quotations ?? this.quotations,
      salesReps: salesReps ?? this.salesReps,
      assignedToFilter:
          clearAssignedToFilter ? null : (assignedToFilter ?? this.assignedToFilter),
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      search: search ?? this.search,
      selected: clearSelected ? null : (selected ?? this.selected),
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isMutating: isMutating ?? this.isMutating,
      unseenCount: unseenCount ?? this.unseenCount,
      // Messages are one-shot: they are never carried over by copyWith.
      message: message,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        quotations,
        salesReps,
        assignedToFilter,
        statusFilter,
        search,
        selected,
        isDetailLoading,
        isMutating,
        unseenCount,
        message,
        errorMessage,
      ];
}
