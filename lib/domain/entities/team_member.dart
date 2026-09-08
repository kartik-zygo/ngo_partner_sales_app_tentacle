import 'package:equatable/equatable.dart';

class TeamMember extends Equatable {
  const TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.region,
    required this.activeLeads,
    required this.wonDeals,
    this.isActive = true,
    this.tempPassword,
  });

  final String id;
  final String name;
  final String email;
  final String region;
  final int activeLeads;
  final int wonDeals;
  final bool isActive;
  // Only populated on creation; never present in list/get responses.
  final String? tempPassword;

  TeamMember copyWith({
    String? id,
    String? name,
    String? email,
    String? region,
    int? activeLeads,
    int? wonDeals,
    bool? isActive,
  }) {
    return TeamMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      region: region ?? this.region,
      activeLeads: activeLeads ?? this.activeLeads,
      wonDeals: wonDeals ?? this.wonDeals,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, name, email, region, activeLeads, wonDeals, isActive];
}
