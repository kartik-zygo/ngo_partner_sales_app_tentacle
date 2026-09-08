import 'dart:convert';
import 'dart:io';

class BridgeLeadRequest {
  const BridgeLeadRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.organization,
    required this.serviceId,
    required this.serviceName,
    required this.createdAt,
    this.message,
    this.processed = false,
    this.processedAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String organization;
  final String serviceId;
  final String serviceName;
  final DateTime createdAt;
  final String? message;
  final bool processed;
  final DateTime? processedAt;

  factory BridgeLeadRequest.fromJson(Map<String, dynamic> json) {
    return BridgeLeadRequest(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userEmail: json['userEmail'] as String,
      userPhone: json['userPhone'] as String? ?? '',
      organization: json['organization'] as String? ?? 'Unknown Organization',
      serviceId: json['serviceId'] as String? ?? 'unknown_service',
      serviceName: json['serviceName'] as String? ?? 'General Inquiry',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      message: json['message'] as String?,
      processed: json['processed'] as bool? ?? false,
      processedAt: DateTime.tryParse(json['processedAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'organization': organization,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'createdAt': createdAt.toIso8601String(),
      'message': message,
      'processed': processed,
      'processedAt': processedAt?.toIso8601String(),
    };
  }

  BridgeLeadRequest copyWith({
    bool? processed,
    DateTime? processedAt,
  }) {
    return BridgeLeadRequest(
      id: id,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userPhone: userPhone,
      organization: organization,
      serviceId: serviceId,
      serviceName: serviceName,
      createdAt: createdAt,
      message: message,
      processed: processed ?? this.processed,
      processedAt: processedAt ?? this.processedAt,
    );
  }
}

class BridgeCallRequest {
  const BridgeCallRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.organization,
    required this.targetTeam,
    required this.callType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.message,
    this.salesAgentId,
    this.salesAgentName,
  });

  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String organization;
  final String targetTeam;
  final String callType;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? message;
  final String? salesAgentId;
  final String? salesAgentName;

  factory BridgeCallRequest.fromJson(Map<String, dynamic> json) {
    return BridgeCallRequest(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userEmail: json['userEmail'] as String? ?? '',
      userPhone: json['userPhone'] as String? ?? '',
      organization: json['organization'] as String? ?? 'Unknown Organization',
      targetTeam: json['targetTeam'] as String? ?? 'support',
      callType: json['callType'] as String? ?? 'voice',
      status: json['status'] as String? ?? 'ringing',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      message: json['message'] as String?,
      salesAgentId: json['salesAgentId'] as String?,
      salesAgentName: json['salesAgentName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'organization': organization,
      'targetTeam': targetTeam,
      'callType': callType,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'message': message,
      'salesAgentId': salesAgentId,
      'salesAgentName': salesAgentName,
    };
  }

  BridgeCallRequest copyWith({
    String? status,
    DateTime? updatedAt,
    String? salesAgentId,
    String? salesAgentName,
  }) {
    return BridgeCallRequest(
      id: id,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userPhone: userPhone,
      organization: organization,
      targetTeam: targetTeam,
      callType: callType,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      message: message,
      salesAgentId: salesAgentId ?? this.salesAgentId,
      salesAgentName: salesAgentName ?? this.salesAgentName,
    );
  }
}

class CrossAppBridgeDataSource {
  static const _fileName = 'ngo_partner_cross_app_bridge.json';

  Future<List<BridgeLeadRequest>> getPendingLeadRequests() async {
    final store = await _readStore();
    final raw = (store['leadRequests'] as List<dynamic>? ?? const []);
    final list = raw
        .whereType<Map<String, dynamic>>()
        .map(BridgeLeadRequest.fromJson)
        .where((item) => !item.processed)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<void> markLeadRequestsProcessed(List<String> requestIds) async {
    if (requestIds.isEmpty) {
      return;
    }

    final store = await _readStore();
    final raw = (store['leadRequests'] as List<dynamic>? ?? const []);
    final next = raw
        .whereType<Map<String, dynamic>>()
        .map((json) {
          final item = BridgeLeadRequest.fromJson(json);
          if (!requestIds.contains(item.id)) {
            return item;
          }
          return item.copyWith(processed: true, processedAt: DateTime.now());
        })
        .map((item) => item.toJson())
        .toList();

    store['leadRequests'] = next;
    await _writeStore(store);
  }

  Future<List<BridgeCallRequest>> getSalesCallRequests() async {
    final store = await _readStore();
    final raw = (store['callRequests'] as List<dynamic>? ?? const []);

    final list = raw
        .whereType<Map<String, dynamic>>()
        .map(BridgeCallRequest.fromJson)
        .where((item) => item.status != 'ended' && item.status != 'rejected')
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return list;
  }

  Future<BridgeCallRequest?> updateCallStatus({
    required String callId,
    required String status,
    required String salesAgentId,
    required String salesAgentName,
  }) async {
    final store = await _readStore();
    final raw = (store['callRequests'] as List<dynamic>? ?? const []);

    BridgeCallRequest? updated;
    final next = raw
        .whereType<Map<String, dynamic>>()
        .map((json) {
          final item = BridgeCallRequest.fromJson(json);
          if (item.id != callId) {
            return item;
          }
          updated = item.copyWith(
            status: status,
            updatedAt: DateTime.now(),
            salesAgentId: salesAgentId,
            salesAgentName: salesAgentName,
          );
          return updated!;
        })
        .map((item) => item.toJson())
        .toList();

    store['callRequests'] = next;
    await _writeStore(store);
    return updated;
  }

  Future<Map<String, dynamic>> _readStore() async {
    final file = await _storeFile();
    if (!file.existsSync()) {
      return _emptyStore();
    }

    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return _emptyStore();
      }

      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) {
        return {
          'leadRequests': decoded['leadRequests'] is List ? decoded['leadRequests'] : <dynamic>[],
          'callRequests': decoded['callRequests'] is List ? decoded['callRequests'] : <dynamic>[],
        };
      }
      return _emptyStore();
    } catch (_) {
      return _emptyStore();
    }
  }

  Future<void> _writeStore(Map<String, dynamic> store) async {
    final file = await _storeFile();
    await file.writeAsString(jsonEncode(store), flush: true);
  }

  Future<File> _storeFile() async {
    final path = '${Directory.systemTemp.path}${Platform.pathSeparator}$_fileName';
    final file = File(path);
    if (!file.existsSync()) {
      await file.writeAsString(jsonEncode(_emptyStore()), flush: true);
    }
    return file;
  }

  Map<String, dynamic> _emptyStore() {
    return {
      'leadRequests': <dynamic>[],
      'callRequests': <dynamic>[],
    };
  }
}
