import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peerdart/peerdart.dart';

class ZeroSignaling {
  Peer peer = Peer();
  String? peerId;
  MediaStream? localStream;
  RTCVideoRenderer remoteRenderer;
  
  Function(String id)? onPeerIdGenerated;
  Function(String state)? onConnectionStateChange;

  ZeroSignaling({required this.remoteRenderer});

  void init() {
    peer.on("open").listen((id) {
      peerId = id;
      onPeerIdGenerated?.call(id);
      onConnectionStateChange?.call("Ready to Call");
    });

    peer.on<MediaConnection>("call").listen((call) {
      // Auto-answer for simplicity or handle via UI
      call.answer(localStream!);
      _handleCall(call);
    });

    peer.on("error").listen((err) {
      onConnectionStateChange?.call("Error: $err");
    });
  }

  void _handleCall(MediaConnection call) {
    onConnectionStateChange?.call("In Call");
    
    call.on<MediaStream>("stream").listen((stream) {
      remoteRenderer.srcObject = stream;
    });

    call.on("close").listen(() {
      onConnectionStateChange?.call("Call Ended");
      remoteRenderer.srcObject = null;
    });
  }

  void call(String destId) {
    if (localStream == null) return;
    
    final call = peer.call(destId, localStream!);
    _handleCall(call);
  }

  void hangUp() {
    peer.dispose();
    remoteRenderer.srcObject = null;
    // Re-initialize for next call
    peer = Peer();
    init();
  }
}
