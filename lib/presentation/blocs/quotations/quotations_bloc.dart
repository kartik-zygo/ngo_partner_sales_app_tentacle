import 'package:bloc/bloc.dart';

import '../../../domain/entities/quotation_request.dart';
import '../../../domain/usecases/sales_usecases.dart';
import 'quotations_event.dart';
import 'quotations_state.dart';

export 'quotations_event.dart';
export 'quotations_state.dart';

class QuotationsBloc extends Bloc<QuotationsEvent, QuotationsState> {
  QuotationsBloc({
    required GetQuotationsUseCase getQuotationsUseCase,
    required GetQuotationByIdUseCase getQuotationByIdUseCase,
    required GetSalesRepsUseCase getSalesRepsUseCase,
    required AssignQuotationUseCase assignQuotationUseCase,
    required UpdateQuotationStatusUseCase updateQuotationStatusUseCase,
    required AddQuotationNoteUseCase addQuotationNoteUseCase,
  })  : _getQuotations = getQuotationsUseCase,
        _getQuotationById = getQuotationByIdUseCase,
        _getSalesReps = getSalesRepsUseCase,
        _assignQuotation = assignQuotationUseCase,
        _updateQuotationStatus = updateQuotationStatusUseCase,
        _addQuotationNote = addQuotationNoteUseCase,
        super(const QuotationsState()) {
    on<QuotationsLoaded>(_onLoaded);
    on<QuotationsFilterChanged>(_onFilterChanged);
    // The search field debounces its own keystrokes before dispatching.
    on<QuotationsSearchChanged>(_onSearchChanged);
    on<QuotationDetailOpened>(_onDetailOpened);
    on<QuotationDetailClosed>(_onDetailClosed);
    on<QuotationAssigned>(_onAssigned);
    on<QuotationStatusUpdated>(_onStatusUpdated);
    on<QuotationNoteAdded>(_onNoteAdded);
    on<SalesRepsLoaded>(_onSalesRepsLoaded);
    on<QuotationSubmissionReceived>(_onSubmissionReceived);
    on<QuotationInboxSeen>(_onInboxSeen);
    on<QuotationMessageCleared>(_onMessageCleared);
    on<QuotationReplaced>(_onReplaced);
  }

  final GetQuotationsUseCase _getQuotations;
  final GetQuotationByIdUseCase _getQuotationById;
  final GetSalesRepsUseCase _getSalesReps;
  final AssignQuotationUseCase _assignQuotation;
  final UpdateQuotationStatusUseCase _updateQuotationStatus;
  final AddQuotationNoteUseCase _addQuotationNote;

  Future<void> _onLoaded(
    QuotationsLoaded event,
    Emitter<QuotationsState> emit,
  ) async {
    final assignedTo = event.assignedTo ?? state.assignedToFilter;
    final status = event.status ?? state.statusFilter;
    final search = event.search ?? state.search;

    emit(state.copyWith(
      status: QuotationsStatus.loading,
      assignedToFilter: assignedTo,
      statusFilter: status,
      search: search,
    ));

    await _fetch(emit, assignedTo: assignedTo, status: status, search: search);
  }

  Future<void> _onFilterChanged(
    QuotationsFilterChanged event,
    Emitter<QuotationsState> emit,
  ) async {
    final assignedTo =
        event.clearAssignedTo ? null : (event.assignedTo ?? state.assignedToFilter);
    final status = event.clearStatus ? null : (event.status ?? state.statusFilter);

    emit(state.copyWith(
      status: QuotationsStatus.loading,
      assignedToFilter: assignedTo,
      statusFilter: status,
      clearAssignedToFilter: event.clearAssignedTo,
      clearStatusFilter: event.clearStatus,
    ));

    await _fetch(
      emit,
      assignedTo: assignedTo,
      status: status,
      search: state.search,
    );
  }

  Future<void> _onSearchChanged(
    QuotationsSearchChanged event,
    Emitter<QuotationsState> emit,
  ) async {
    emit(state.copyWith(
      status: QuotationsStatus.loading,
      search: event.search,
    ));
    await _fetch(
      emit,
      assignedTo: state.assignedToFilter,
      status: state.statusFilter,
      search: event.search,
    );
  }

  Future<void> _fetch(
    Emitter<QuotationsState> emit, {
    String? assignedTo,
    String? status,
    String? search,
  }) async {
    try {
      final quotations = await _getQuotations(
        assignedTo: assignedTo,
        status: status,
        search: (search == null || search.isEmpty) ? null : search,
      );
      emit(state.copyWith(
        status: QuotationsStatus.ready,
        quotations: quotations,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: QuotationsStatus.failure,
        errorMessage: _clean(error),
      ));
    }
  }

  Future<void> _onDetailOpened(
    QuotationDetailOpened event,
    Emitter<QuotationsState> emit,
  ) async {
    // Show whatever the list already has so the sheet is never empty, then
    // replace it with the full record.
    final cached = _findById(event.id);
    emit(state.copyWith(selected: cached, isDetailLoading: true));
    try {
      final full = await _getQuotationById(event.id);
      emit(state.copyWith(
        selected: full,
        isDetailLoading: false,
        quotations: _replaceIn(state.quotations, full),
      ));
    } catch (error) {
      emit(state.copyWith(
        isDetailLoading: false,
        errorMessage: _clean(error),
      ));
    }
  }

  void _onDetailClosed(
    QuotationDetailClosed event,
    Emitter<QuotationsState> emit,
  ) {
    emit(state.copyWith(clearSelected: true, isDetailLoading: false));
  }

  Future<void> _onAssigned(
    QuotationAssigned event,
    Emitter<QuotationsState> emit,
  ) async {
    emit(state.copyWith(isMutating: true));
    try {
      final updated = await _assignQuotation(
        event.id,
        assignedTo: event.assignedTo,
        note: event.note,
      );
      emit(state.copyWith(
        isMutating: false,
        quotations: _applyToList(updated),
        selected: state.selected?.id == updated.id ? updated : null,
        message: 'Assigned to ${updated.assignedToName ?? 'the rep'}',
      ));
      // Workloads on the picker are now stale.
      add(const SalesRepsLoaded());
    } on QuotationForbiddenException catch (e) {
      emit(state.copyWith(isMutating: false, errorMessage: e.message));
    } on QuotationConflictException catch (e) {
      emit(state.copyWith(isMutating: false, errorMessage: e.message));
      add(const QuotationsLoaded());
    } catch (error) {
      emit(state.copyWith(isMutating: false, errorMessage: _clean(error)));
    }
  }

  Future<void> _onStatusUpdated(
    QuotationStatusUpdated event,
    Emitter<QuotationsState> emit,
  ) async {
    emit(state.copyWith(isMutating: true));
    try {
      final updated = await _updateQuotationStatus(
        event.id,
        status: event.status,
        note: event.note,
      );
      emit(state.copyWith(
        isMutating: false,
        quotations: _applyToList(updated),
        selected: state.selected?.id == updated.id ? updated : null,
        message: updated.status == QuotationStatus.closedWon
            ? 'Marked won — a case has been opened'
            : 'Moved to ${updated.status.label}',
      ));
    } on InvalidStatusTransitionException catch (e) {
      emit(state.copyWith(isMutating: false, errorMessage: e.message));
    } on QuotationConflictException catch (e) {
      // Someone else moved it — refetch rather than retry blind.
      emit(state.copyWith(
        isMutating: false,
        errorMessage: '${e.message} Refreshing…',
      ));
      add(const QuotationsLoaded());
      if (state.selected != null) {
        add(QuotationDetailOpened(state.selected!.id));
      }
    } catch (error) {
      emit(state.copyWith(isMutating: false, errorMessage: _clean(error)));
    }
  }

  Future<void> _onNoteAdded(
    QuotationNoteAdded event,
    Emitter<QuotationsState> emit,
  ) async {
    emit(state.copyWith(isMutating: true));
    try {
      final updated = await _addQuotationNote(event.id, event.content);
      emit(state.copyWith(
        isMutating: false,
        quotations: _applyToList(updated),
        selected: state.selected?.id == updated.id ? updated : null,
        message: 'Note added',
      ));
    } catch (error) {
      emit(state.copyWith(isMutating: false, errorMessage: _clean(error)));
    }
  }

  Future<void> _onSalesRepsLoaded(
    SalesRepsLoaded event,
    Emitter<QuotationsState> emit,
  ) async {
    try {
      final reps = await _getSalesReps();
      emit(state.copyWith(salesReps: reps));
    } catch (_) {
      // The picker falls back to whatever it already has; the assign sheet
      // surfaces the real failure when the call itself fails.
    }
  }

  Future<void> _onSubmissionReceived(
    QuotationSubmissionReceived event,
    Emitter<QuotationsState> emit,
  ) async {
    emit(state.copyWith(unseenCount: state.unseenCount + 1));
    await _fetch(
      emit,
      assignedTo: state.assignedToFilter,
      status: state.statusFilter,
      search: state.search,
    );
  }

  void _onInboxSeen(
    QuotationInboxSeen event,
    Emitter<QuotationsState> emit,
  ) {
    if (state.unseenCount == 0) return;
    emit(state.copyWith(unseenCount: 0));
  }

  void _onMessageCleared(
    QuotationMessageCleared event,
    Emitter<QuotationsState> emit,
  ) {
    emit(state.copyWith());
  }

  void _onReplaced(
    QuotationReplaced event,
    Emitter<QuotationsState> emit,
  ) {
    emit(state.copyWith(
      quotations: _applyToList(event.quotation),
      selected: state.selected?.id == event.quotation.id
          ? event.quotation
          : null,
    ));
  }

  QuotationRequest? _findById(String id) {
    for (final quotation in state.quotations) {
      if (quotation.id == id) return quotation;
    }
    return null;
  }

  /// Swaps the row in place, and drops it when it no longer matches the
  /// active `assignedTo` filter — assigning from the unassigned inbox should
  /// make the row leave the list.
  List<QuotationRequest> _applyToList(QuotationRequest updated) {
    final next = _replaceIn(state.quotations, updated);
    if (state.assignedToFilter == 'unassigned' && !updated.isUnassigned) {
      return next.where((q) => q.id != updated.id).toList();
    }
    return next;
  }

  List<QuotationRequest> _replaceIn(
    List<QuotationRequest> list,
    QuotationRequest updated,
  ) {
    return list.map((q) => q.id == updated.id ? updated : q).toList();
  }

  String _clean(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
