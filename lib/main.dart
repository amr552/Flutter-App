import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'webrtc_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'P2P Crystal Call',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0C29),
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF24243E),
          secondary: Color(0xFF642B73),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final WebRTCService _webrtcService = WebRTCService();
  final TextEditingController _roomController = TextEditingController();
  bool _inCall = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _webrtcService.initRenderers();
  }

  @override
  void dispose() {
    _controller.dispose();
    _roomController.dispose();
    _webrtcService.dispose();
    super.dispose();
  }

  void _onCreateRoom() async {
    await _webrtcService.openUserMedia();
    String roomId = await _webrtcService.createRoom();
    setState(() {
      _roomController.text = roomId;
      _inCall = true;
    });
  }

  void _onJoinRoom() async {
    if (_roomController.text.isNotEmpty) {
      await _webrtcService.openUserMedia();
      await _webrtcService.joinRoom(_roomController.text);
      setState(() {
        _inCall = true;
      });
    }
  }

  void _onHangUp() async {
    await _webrtcService.hangUp();
    setState(() {
      _inCall = false;
      _roomController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: Stack(
          children: [
            if (_inCall)
              Stack(
                children: [
                  RTCVideoView(_webrtcService.remoteRenderer),
                  Positioned(
                    right: 20,
                    top: 50,
                    width: 120,
                    height: 180,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: RTCVideoView(_webrtcService.localRenderer, mirror: true),
                    ),
                  ),
                ],
              )
            else
              Center(
                child: ScaleTransition(
                  scale: _animation,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF642B73).withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    Text(
                      'Crystal Call',
                      style: GoogleFonts.outfit(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _inCall ? 'Session: ${_roomController.text}' : 'Unique P2P WebRTC Experience',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                    if (!_inCall) ...[
                      const Spacer(),
                      _buildRoomControls(),
                    ],
                    const Spacer(),
                    if (!_inCall)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 80,
                            backgroundColor: Colors.white10,
                            child: Icon(Icons.person, size: 80, color: Colors.white70),
                          ),
                        ),
                      ),
                    const SizedBox(height: 40),
                    Center(
                      child: Text(
                        _inCall ? 'In Call' : 'Anya Taylor-Joy',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        'Encrypted P2P Call',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCallAction(Icons.mic_off, 'Mute', Colors.white12, () {}),
                        _buildCallAction(
                          _inCall ? Icons.call_end : Icons.phone,
                          _inCall ? 'End Call' : 'Start',
                          _inCall ? Colors.redAccent : Colors.greenAccent,
                          _inCall ? _onHangUp : _onCreateRoom,
                        ),
                        _buildCallAction(Icons.videocam, 'Video', Colors.white12, () {}),
                      ],
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          TextField(
            controller: _roomController,
            decoration: InputDecoration(
              hintText: 'Enter Room ID',
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _onJoinRoom,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF642B73),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Join Room'),
          ),
        ],
      ),
    );
  }

  Widget _buildCallAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: color != Colors.white12 ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ] : [],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }
}

