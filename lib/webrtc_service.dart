import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'signaling.dart';

class WebRTCService {
  late ZeroSignaling zeroSignaling;
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  WebRTCService() {
    zeroSignaling = ZeroSignaling(remoteRenderer: remoteRenderer);
  }

  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    zeroSignaling.init();
  }

  Future<void> openUserMedia() async {
    var stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });

    localRenderer.srcObject = stream;
    zeroSignaling.localStream = stream;
  }

  void call(String destId) {
    zeroSignaling.call(destId);
  }

  Future<void> hangUp() async {
    zeroSignaling.hangUp();
    localRenderer.srcObject = null;
  }

  void dispose() {
    localRenderer.dispose();
    remoteRenderer.dispose();
  }
}
