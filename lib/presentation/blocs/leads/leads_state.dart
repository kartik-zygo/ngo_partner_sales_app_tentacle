part of 'leads_bloc.dart';

enum LeadsStatus { initial, loading, success, failure }

class LeadsState extends Equatable {
  const LeadsState({
    this.status = LeadsStatus.initial,
    this.userId,
    this.allLeads = const [],
    this.visibleLeads = const [],
    this.cases = const [],
    this.searchQuery = '',
    this.statusFilter,
    this.sourceFilter,
    this.sortNewestFirst = true,
    this.selectedLead,
    this.supportTickets = const [],
    this.selectedTicket,
    this.supportCalls = const [],
    this.queuedNotificationEvents = const [],
    this.collaborationOpportunities = const [],
    this.connectivityEvents = const [],
    this.message,
  });

  final LeadsStatus status;
  final String? userId;
  final List<Lead> allLeads;
  final List<Lead> visibleLeads;
  final List<ClientCase> cases;
  final String searchQuery;
  final LeadStatus? statusFilter;
  final LeadSource? sourceFilter;
  final bool sortNewestFirst;
  final Lead? selectedLead;
  final List<SupportTicket> supportTickets;
  final SupportTicket? selectedTicket;
  final List<SupportCallRequest> supportCalls;
  final List<CrossAppNotificationEvent> queuedNotificationEvents;
  final List<CollaborationOpportunity> collaborationOpportunities;
  final List<String> connectivityEvents;
  final String? message;

  LeadsState copyWith({
    LeadsStatus? status,
    String? userId,
    List<Lead>? allLeads,
    List<Lead>? visibleLeads,
    List<ClientCase>? cases,
    String? searchQuery,
    LeadStatus? statusFilter,
    bool clearStatusFilter = false,
    LeadSource? sourceFilter,
    bool clearSourceFilter = false,
    bool? sortNewestFirst,
    Lead? selectedLead,
    List<SupportTicket>? supportTickets,
    SupportTicket? selectedTicket,
    bool clearSelectedTicket = false,
    List<SupportCallRequest>? supportCalls,
    List<CrossAppNotificationEvent>? queuedNotificationEvents,
    List<CollaborationOpportunity>? collaborationOpportunities,
    List<String>? connectivityEvents,
    String? message,
    bool clearMessage = false,
  }) {
    return LeadsState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      allLeads: allLeads ?? this.allLeads,
      visibleLeads: visibleLeads ?? this.visibleLeads,
      cases: cases ?? this.cases,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      sourceFilter: clearSourceFilter ? null : (sourceFilter ?? this.sourceFilter),
      sortNewestFirst: sortNewestFirst ?? this.sortNewestFirst,
      selectedLead: selectedLead ?? this.selectedLead,
      supportTickets: supportTickets ?? this.supportTickets,
      selectedTicket: clearSelectedTicket ? null : (selectedTicket ?? this.selectedTicket),
      supportCalls: supportCalls ?? this.supportCalls,
      queuedNotificationEvents: queuedNotificationEvents ?? this.queuedNotificationEvents,
      collaborationOpportunities: collaborationOpportunities ?? this.collaborationOpportunities,
      connectivityEvents: connectivityEvents ?? this.connectivityEvents,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
        status,
        userId,
        allLeads,
        visibleLeads,
        cases,
        searchQuery,
        statusFilter,
        sourceFilter,
        sortNewestFirst,
        selectedLead,
        supportTickets,
        selectedTicket,
        supportCalls,
        queuedNotificationEvents,
        collaborationOpportunities,
        connectivityEvents,
        message,
      ];
}
