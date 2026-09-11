import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/app_constants.dart';

typedef CallEventCallback = void Function(Map<String, dynamic> callData);

class SocketService {
  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String accessToken) {
    if (isConnected) return;

    _socket = io.io(
      AppConstants.socketBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath(AppConstants.socketPath)
          .setAuth({'token': accessToken})
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void onPaymentRequestSubmitted(CallEventCallback callback) {
    _socket?.on('order:paymentRequestSubmitted', (data) {
      final map = _toMap(data);
      if (map != null) callback(map);
    });
  }

  void offPaymentRequestSubmitted() {
    _socket?.off('order:paymentRequestSubmitted');
  }

  /// Fires in the `sales-team` room whenever a client submits the quotation
  /// form — ADMIN and SALES tokens join that room automatically.
  void onQuotationSubmitted(CallEventCallback callback) {
    _socket?.on('quotation:submitted', (data) {
      final map = _toMap(data);
      if (map != null) callback(map);
    });
  }

  void offQuotationSubmitted() {
    _socket?.off('quotation:submitted');
  }

  /// Fires in the rep's own user room when a request is assigned to them.
  void onQuotationAssigned(CallEventCallback callback) {
    _socket?.on('quotation:assigned', (data) {
      final map = _toMap(data);
      if (map != null) callback(map);
    });
  }

  void offQuotationAssigned() {
    _socket?.off('quotation:assigned');
  }

  Map<String, dynamic>? _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List && data.isNotEmpty) {
      final first = data[0];
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    return null;
  }

  void onCallIncoming(CallEventCallback callback) {
    _socket?.on('call:incoming', (data) {
      if (data is Map<String, dynamic>) callback(data);
    });
  }

  void onCallStatusChanged(CallEventCallback callback) {
    _socket?.on('call:status-changed', (data) {
      if (data is Map<String, dynamic>) callback(data);
    });
  }

  void offCallIncoming() {
    _socket?.off('call:incoming');
  }

  void onCallCancelled(CallEventCallback callback) {
    _socket?.on('call:cancelled', (data) {
      if (data is Map<String, dynamic>) callback(data);
    });
  }

  void offCallCancelled() {
    _socket?.off('call:cancelled');
  }

  void offCallStatusChanged() {
    _socket?.off('call:status-changed');
  }

  void joinCallRoom(String callId) {
    _socket?.emit('call:join', callId);
  }

  void leaveCallRoom(String callId) {
    _socket?.emit('call:leave', callId);
  }
}
