import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'signaling.dart';

class WebRTCService {
  Signaling signaling = Signaling();
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  String? roomId;

  WebRTCService() {
    initRenderers();
  }

  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  void onLocalStream(MediaStream stream) {
    localRenderer.srcObject = stream;
  }

  void onRemoteStream(MediaStream stream) {
    remoteRenderer.srcObject = stream;
  }

  Future<void> openUserMedia() async {
    var stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });

    onLocalStream(stream);
    signaling.localStream = stream;
  }

  Future<String> createRoom() async {
    roomId = await signaling.createRoom(remoteRenderer);
    return roomId!;
  }

  Future<void> joinRoom(String id) async {
    await signaling.joinRoom(id, remoteRenderer);
  }

  Future<void> hangUp() async {
    await signaling.hangUp(localRenderer);
  }

  void dispose() {
    localRenderer.dispose();
    remoteRenderer.dispose();
  }
}
