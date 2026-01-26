import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';

class CallNotificationService extends ChangeNotifier {
  final DatabaseReference _callsRef = FirebaseDatabase.instance.ref('calls');
  StreamSubscription? _incomingCallSubscription;
  
  String? _currentCallId;
  String? _callerUsername;
  String? _callStatus; // 'ringing', 'accepted', 'rejected', 'ended'
  
  String? get currentCallId => _currentCallId;
  String? get callerUsername => _callerUsername;
  String? get callStatus => _callStatus;
  bool get hasIncomingCall => _callerUsername != null && _callStatus == 'ringing';

  /// Send a call invitation to another user
  Future<String> sendCallInvitation({
    required String fromUsername,
    required String toUsername,
    required String channelName,
  }) async {
    try {
      final callId = DateTime.now().millisecondsSinceEpoch.toString();
      final callData = {
        'callId': callId,
        'from': fromUsername,
        'to': toUsername,
        'channelName': channelName,
        'status': 'ringing',
        'timestamp': ServerValue.timestamp,
      };

      // Write to the recipient's calls node
      await _callsRef.child(toUsername).child(callId).set(callData);
      
      // Also write to caller's calls node for tracking
      await _callsRef.child(fromUsername).child(callId).set({
        ...callData,
        'isOutgoing': true,
      });

      debugPrint('Call invitation sent: $callId from $fromUsername to $toUsername');
      return callId;
    } catch (e) {
      debugPrint('Error sending call invitation: $e');
      rethrow;
    }
  }

  /// Accept a call invitation
  Future<void> acceptCall(String callId, String username) async {
    try {
      await _callsRef.child(username).child(callId).update({
        'status': 'accepted',
        'acceptedAt': ServerValue.timestamp,
      });
      debugPrint('Call accepted: $callId');
    } catch (e) {
      debugPrint('Error accepting call: $e');
      rethrow;
    }
  }

  /// Reject a call invitation
  Future<void> rejectCall(String callId, String username) async {
    try {
      await _callsRef.child(username).child(callId).update({
        'status': 'rejected',
        'rejectedAt': ServerValue.timestamp,
      });
      _clearCurrentCall();
      debugPrint('Call rejected: $callId');
    } catch (e) {
      debugPrint('Error rejecting call: $e');
      rethrow;
    }
  }

  /// End a call
  Future<void> endCall(String callId, String username) async {
    try {
      await _callsRef.child(username).child(callId).update({
        'status': 'ended',
        'endedAt': ServerValue.timestamp,
      });
      _clearCurrentCall();
      debugPrint('Call ended: $callId');
    } catch (e) {
      debugPrint('Error ending call: $e');
      rethrow;
    }
  }

  /// Listen for incoming calls for a specific user
  void listenForIncomingCalls(String username) {
    _incomingCallSubscription?.cancel();
    
    _incomingCallSubscription = _callsRef
        .child(username)
        .orderByChild('status')
        .equalTo('ringing')
        .onChildAdded
        .listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(
          event.snapshot.value as Map,
        );
        
        // Only process if it's an incoming call (not outgoing)
        if (data['isOutgoing'] != true) {
          _currentCallId = event.snapshot.key;
          _callerUsername = data['from'] as String?;
          _callStatus = data['status'] as String?;
          debugPrint('Incoming call received: $_currentCallId from $_callerUsername');
          notifyListeners();
        }
      }
    }, onError: (error) {
      debugPrint('Error listening for incoming calls: $error');
    });
  }

  /// Get call details
  Future<Map<String, dynamic>?> getCallDetails(String callId, String username) async {
    try {
      final snapshot = await _callsRef.child(username).child(callId).get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting call details: $e');
      return null;
    }
  }

  void _clearCurrentCall() {
    _currentCallId = null;
    _callerUsername = null;
    _callStatus = null;
    notifyListeners();
  }

  /// Clear current call notification
  void clearIncomingCall() {
    _clearCurrentCall();
  }

  @override
  void dispose() {
    _incomingCallSubscription?.cancel();
    super.dispose();
  }
}
