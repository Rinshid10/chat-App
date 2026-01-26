import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class AgoraCallService extends ChangeNotifier {
  RtcEngine? _engine;
  bool _isInCall = false;
  bool _isJoined = false;
  int? _remoteUid;
  
  // Agora credentials
  static const String appId = '07b6cd797cca4d12a3e233c800e5cb82';
  static const String token = '007eJxTYPC6tcJwv1HNVleumIviNgu1PyT0ONyf6O24187Qi/nB+/sKDAbmSWbJKeaW5snJiSYphkaJxqlGxsbJFgYGqabJSRZG/pLlmQ2BjAzLlvczMjJAIIjPyVCSWlwSn5yYk8PAAACvmCCv';
  
  String? _currentChannelName;

  bool get isInCall => _isInCall;
  bool get isJoined => _isJoined;
  int? get remoteUid => _remoteUid;

  Future<void> initialize() async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Register event handlers
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) async {
            debugPrint('Agora: Join channel success. Elapsed: $elapsed');
            _isJoined = true;
            _isInCall = true;
            
            // Ensure audio is enabled after joining
            try {
              await _engine?.muteLocalAudioStream(false);
              await _engine?.muteAllRemoteAudioStreams(false);
              debugPrint('Agora: Audio streams enabled after joining channel');
            } catch (e) {
              debugPrint('Error enabling audio after join: $e');
            }
            
            notifyListeners();
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) async {
            debugPrint('Agora: Remote user joined. UID: $remoteUid, Elapsed: $elapsed');
            _remoteUid = remoteUid;
            
            // Enable remote audio when user joins
            try {
              await _engine?.muteRemoteAudioStream(
                uid: remoteUid,
                mute: false,
              );
              await _engine?.muteAllRemoteAudioStreams(false);
              debugPrint('Agora: Remote audio enabled for UID: $remoteUid');
            } catch (e) {
              debugPrint('Error enabling remote audio: $e');
            }
            
            notifyListeners();
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            debugPrint('Agora: Remote user left. UID: $remoteUid, Reason: $reason');
            _remoteUid = null;
            notifyListeners();
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('Agora error: $err - $msg');
            if (err == ErrorCodeType.errInvalidToken) {
              debugPrint('Token is invalid. Please check your Agora token configuration.');
            }
          },
          onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
            debugPrint('Agora: Token will expire soon');
          },
          onRequestToken: (RtcConnection connection) {
            debugPrint('Agora: Token required but not provided');
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            debugPrint('Agora: Left channel');
            _isJoined = false;
            _isInCall = false;
            _remoteUid = null;
            notifyListeners();
          },
        ),
      );

      // Enable audio
      await _engine!.enableAudio();
      
      // Set audio profile for voice communication
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
        scenario: AudioScenarioType.audioScenarioDefault,
      );
      
      // Enable local audio (microphone)
      await _engine!.muteLocalAudioStream(false);
      
      // Enable all remote audio streams by default
      await _engine!.muteAllRemoteAudioStreams(false);
      
      // Set audio route to speakerphone for better call quality
      await _engine!.setDefaultAudioRouteToSpeakerphone(true);
      
      // Enable audio volume indication to monitor audio levels
      await _engine!.enableAudioVolumeIndication(
        interval: 200,
        smooth: 3,
        reportVad: true,
      );
      
      debugPrint('Agora engine initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Agora engine: $e');
      rethrow;
    }
  }

  Future<void> joinChannel(String channelName) async {
    if (_engine == null) {
      await initialize();
    }

    _currentChannelName = channelName;
    try {
      // Try with token first, if it fails, try with empty string (for development)
      try {
        await _engine!.joinChannel(
          token: token,
          channelId: channelName,
          uid: 0, // Let Agora assign UID
          options: const ChannelMediaOptions(),
        );
        debugPrint('Agora: Joining channel: $channelName with token');
      } catch (tokenError) {
        debugPrint('Token error, trying with empty token: $tokenError');
        // Try with empty token (for development/testing if token auth is disabled)
        await _engine!.joinChannel(
          token: '',
          channelId: channelName,
          uid: 0,
          options: const ChannelMediaOptions(),
        );
        debugPrint('Agora: Joining channel: $channelName with empty token (dev mode)');
      }
    } catch (e) {
      debugPrint('Error joining Agora channel: $e');
      rethrow;
    }
  }

  Future<void> leaveChannel() async {
    if (_engine == null) return;

    try {
      await _engine!.leaveChannel();
      debugPrint('Agora: Leaving channel');
    } catch (e) {
      debugPrint('Error leaving Agora channel: $e');
    }
  }

  Future<void> disposeEngine() async {
    if (_engine == null) return;

    try {
      await leaveChannel();
      await _engine!.release();
      _engine = null;
      _isInCall = false;
      _isJoined = false;
      _remoteUid = null;
      _currentChannelName = null;
      notifyListeners();
      debugPrint('Agora engine disposed');
    } catch (e) {
      debugPrint('Error disposing Agora engine: $e');
    }
  }

  @override
  void dispose() {
    disposeEngine();
    super.dispose();
  }
}
