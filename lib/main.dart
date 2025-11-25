// main.dart
// A single-file Flutter app for a birthday surprise.
// Replace all TODOs: asset paths, URLs, text, and targetDate for the countdown.

import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(BirthdaySurpriseApp());
}

class BirthdaySurpriseApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "For My Love",
      theme: ThemeData(
        primarySwatch: Colors.pink,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: MainFlow(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// MainFlow: PageView with pages:
/// 0 - Splash & Reveal
/// 1 - Countdown + Play music
/// 2 - Photos
/// 3 - Video / Voice
/// 4 - Letter
class MainFlow extends StatefulWidget {
  @override
  _MainFlowState createState() => _MainFlowState();
}

class _MainFlowState extends State<MainFlow> {
  final PageController _pageController = PageController();
  final ConfettiController _confettiController = ConfettiController(
    duration: Duration(seconds: 3),
  );

  // TODO: set your target birthday DateTime (year, month, day, hour, minute)
  final DateTime targetDate = DateTime(2025, 11, 26, 0, 0);

  // TODO: replace with your actual playlist URLs or local assets
  final List<AudioItem> playlist = [
    AudioItem('Your Song', 'https://www.example.com/audio/song1.mp3'),
    // Add more entries or use local assets like 'assets/audio/song.mp3'
  ];

  // TODO: replace with your photos (http(s) or asset paths)
  final List<Photo> photos = [
    Photo(
      'https://placehold.co/800x800?text=Photo+1',
      'Our first coffee ☕️ — June 2024',
    ),
    Photo(
      'https://placehold.co/800x800?text=Photo+2',
      'That rainy day movie night',
    ),
    // Add more
  ];

  // TODO: replace with a video URL or local asset 'assets/video/msg.mp4'
  final String videoUrl = 'https://www.example.com/video/your_message.mp4';

  // TODO: write your love letter here
  final String loveLetter = '''
Hey love,

Happy Birthday! Every day with you feels like a new favorite memory...
(Write your heartfelt message here — I can help draft it if you want.)
''';

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _goToPage(int i) => _pageController.animateToPage(
    i,
    duration: Duration(milliseconds: 500),
    curve: Curves.easeInOut,
  );

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      SplashRevealPage(
        name: 'Her Name', // TODO: set her name
        onOpen: () {
          _confettiController.play();
          // optionally navigate to next page after reveal
          Future.delayed(Duration(milliseconds: 600), () => _goToPage(1));
        },
        confettiController: _confettiController,
      ),
      CountdownMusicPage(
        target: targetDate,
        playlist: playlist,
        onOpenPhotos: () => _goToPage(2),
      ),
      PhotoSlideshowPage(photos: photos),
      VideoVoicePage(videoUrl: videoUrl),
      LetterPage(letterText: loveLetter),
    ];

    return Scaffold(
      body: PageView(controller: _pageController, children: pages),
      bottomNavigationBar: _BottomNav(onSelect: _goToPage),
    );
  }
}

/* ----------------------------
   Splash / Reveal Page
   ---------------------------- */
class SplashRevealPage extends StatelessWidget {
  final String name;
  final VoidCallback onOpen;
  final ConfettiController confettiController;

  const SplashRevealPage({
    required this.name,
    required this.onOpen,
    required this.confettiController,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [Color(0xFFFFF0F3), Color(0xFFFFE1E6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(gradient: gradient),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  SizedBox(height: 8),
                  Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      'Open me ❤️',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                  SizedBox(height: 18),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LottieBuilder.network(
                          // charming heart animation from LottieFiles — replace with an asset if you prefer
                          'https://assets2.lottiefiles.com/packages/lf20_yr6zz3wv.json',
                          height: 200,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Happy Birthday',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink[700],
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 18),
                        Text(
                          'Tap the heart to open your surprise',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
        // Confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: [Colors.pink, Colors.purple, Colors.amber, Colors.white],
            emissionFrequency: 0.02,
            numberOfParticles: 40,
            gravity: 0.2,
          ),
        ),
        // BIG Heart that triggers open
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: 48),
            child: GestureDetector(onTap: onOpen, child: HeartButton()),
          ),
        ),
      ],
    );
  }
}

class HeartButton extends StatefulWidget {
  @override
  _HeartButtonState createState() => _HeartButtonState();
}

class _HeartButtonState extends State<HeartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  bool _popped = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _onTap() {
    if (!_popped) {
      _anim.forward();
    } else {
      _anim.reverse();
    }
    setState(() => _popped = !_popped);
    // bubble the tap up by calling the parent's onTap indirectly:
    // We assume parent wrapped with GestureDetector and handles tap.
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _onTap();
        // also trigger any parent handler by calling Navigator maybe, but parent GestureDetector already calls onTap
      },
      child: ScaleTransition(
        scale: Tween(
          begin: 1.0,
          end: 1.08,
        ).animate(CurvedAnimation(parent: _anim, curve: Curves.elasticOut)),
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pinkAccent, Colors.deepOrangeAccent],
            ),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 18)],
          ),
          child: Center(
            child: Icon(Icons.favorite, color: Colors.white, size: 64),
          ),
        ),
      ),
    );
  }
}

/* ----------------------------
   Countdown + Music Page
   ---------------------------- */

class CountdownMusicPage extends StatelessWidget {
  final DateTime target;
  final List<AudioItem> playlist;
  final VoidCallback onOpenPhotos;

  const CountdownMusicPage({
    required this.target,
    required this.playlist,
    required this.onOpenPhotos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF7F9), Color(0xFFFFEEF2)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 8),
          Text(
            'Countdown',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          SizedBox(height: 8),
          CountdownWidget(target: target),
          SizedBox(height: 20),
          SimpleAudioPlayer(playlist: playlist),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onOpenPhotos,
            icon: Icon(Icons.photo_library),
            label: Text('Open Photos'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class CountdownWidget extends StatefulWidget {
  final DateTime target;
  const CountdownWidget({required this.target});

  @override
  _CountdownWidgetState createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(Duration(seconds: 1), (_) => _updateRemaining());
  }

  void _updateRemaining() {
    final now = DateTime.now();
    setState(() {
      _remaining = widget.target.difference(now);
      if (_remaining.isNegative) _remaining = Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Column(
      children: [
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _timeCard('$days', 'Days'),
            SizedBox(width: 12),
            _timeCard(_two(hours), 'Hours'),
            SizedBox(width: 12),
            _timeCard(_two(minutes), 'Min'),
            SizedBox(width: 12),
            _timeCard(_two(seconds), 'Sec'),
          ],
        ),
      ],
    );
  }

  Widget _timeCard(String value, String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: Text(
            value,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }
}

/* ----------------------------
   Simple Audio Player (audioplayers)
   ---------------------------- */
class AudioItem {
  final String title;
  final String url;
  AudioItem(this.title, this.url);
}

class SimpleAudioPlayer extends StatefulWidget {
  final List<AudioItem> playlist;
  const SimpleAudioPlayer({required this.playlist});

  @override
  _SimpleAudioPlayerState createState() => _SimpleAudioPlayerState();
}

class _SimpleAudioPlayerState extends State<SimpleAudioPlayer> {
  final AudioPlayer _player = AudioPlayer();
  int _index = 0;
  PlayerState _state = PlayerState.stopped;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  void initState() {
    super.initState();
    _stateSub = _player.onPlayerStateChanged.listen((s) {
      setState(() => _state = s);
    });
    // preload first track (if URL is valid)
    if (widget.playlist.isNotEmpty) {
      _playCurrent();
    }
  }

  Future<void> _playCurrent() async {
    if (widget.playlist.isEmpty) return;
    final src = widget.playlist[_index].url;
    try {
      await _player.stop();
      await _player.play(UrlSource(src));
    } catch (e) {
      // ignore for now
    }
  }

  void _next() {
    if (widget.playlist.isEmpty) return;
    setState(() {
      _index = (_index + 1) % widget.playlist.length;
    });
    _playCurrent();
  }

  void _prev() {
    if (widget.playlist.isEmpty) return;
    setState(() {
      _index = (_index - 1 + widget.playlist.length) % widget.playlist.length;
    });
    _playCurrent();
  }

  void _toggle() {
    if (_state == PlayerState.playing)
      _player.pause();
    else if (_state == PlayerState.paused)
      _player.resume();
    else
      _playCurrent();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.playlist.isEmpty) {
      return Text(
        'No music added. Replace playlist with your song URL or asset.',
      );
    }

    final item = widget.playlist[_index];
    return Column(
      children: [
        Text(
          item.title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(icon: Icon(Icons.skip_previous), onPressed: _prev),
            IconButton(
              icon: Icon(
                _state == PlayerState.playing
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
              ),
              iconSize: 48,
              onPressed: _toggle,
            ),
            IconButton(icon: Icon(Icons.skip_next), onPressed: _next),
          ],
        ),
      ],
    );
  }
}

/* ----------------------------
   Photo Slideshow Page
   ---------------------------- */
class Photo {
  final String src;
  final String caption;
  Photo(this.src, this.caption);
}

class PhotoSlideshowPage extends StatelessWidget {
  final List<Photo> photos;
  const PhotoSlideshowPage({required this.photos});

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Center(
        child: Text(
          'No photos added. Replace the placeholder list with your photos.',
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: PageView.builder(
        itemCount: photos.length,
        itemBuilder: (context, i) {
          final p = photos[i];
          return Column(
            children: [
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 12),
                    ],
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: p.src.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: p.src,
                            fit: BoxFit.cover,
                            placeholder: (c, s) =>
                                Center(child: CircularProgressIndicator()),
                            errorWidget: (c, s, e) =>
                                Center(child: Icon(Icons.broken_image)),
                          )
                        : Image.asset(p.src, fit: BoxFit.cover),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Text(p.caption, style: TextStyle(fontSize: 16)),
              SizedBox(height: 28),
            ],
          );
        },
      ),
    );
  }
}

/* ----------------------------
   Video / Voice Page
   ---------------------------- */
class VideoVoicePage extends StatefulWidget {
  final String videoUrl;
  const VideoVoicePage({required this.videoUrl});

  @override
  _VideoVoicePageState createState() => _VideoVoicePageState();
}

class _VideoVoicePageState extends State<VideoVoicePage> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    if (widget.videoUrl.startsWith('http')) {
      _controller = VideoPlayerController.network(widget.videoUrl);
    } else {
      _controller = VideoPlayerController.asset(widget.videoUrl);
    }
    await _controller!.initialize();
    setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _initialized && _controller != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        _controller!.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                      onPressed: () {
                        setState(() {
                          _controller!.value.isPlaying
                              ? _controller!.pause()
                              : _controller!.play();
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.replay),
                      onPressed: () {
                        _controller!.seekTo(Duration.zero);
                        _controller!.play();
                      },
                    ),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: Icon(Icons.open_in_new),
                      label: Text('Open in browser'),
                      onPressed: () async {
                        final uri = Uri.tryParse(widget.videoUrl);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                  ],
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Loading message...'),
              ],
            ),
    );
  }
}

/* ----------------------------
   Letter Page (scrollable with styling)
   ---------------------------- */
class LetterPage extends StatelessWidget {
  final String letterText;
  const LetterPage({required this.letterText});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFFBF8), Color(0xFFFFF0F3)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            children: [
              Text(
                'A Letter For You',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink[700],
                ),
              ),
              SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                    ),
                    child: Text(
                      letterText,
                      style: TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Text(
                '— With all my love ❤️',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ----------------------------
   Bottom Navigation
   ---------------------------- */
class _BottomNav extends StatelessWidget {
  final void Function(int) onSelect;
  const _BottomNav({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavButton(icon: Icons.home, label: 'Open', onTap: () => onSelect(0)),
          _NavButton(
            icon: Icons.timer,
            label: 'Countdown',
            onTap: () => onSelect(1),
          ),
          _NavButton(
            icon: Icons.photo,
            label: 'Photos',
            onTap: () => onSelect(2),
          ),
          _NavButton(
            icon: Icons.video_library,
            label: 'Video',
            onTap: () => onSelect(3),
          ),
          _NavButton(
            icon: Icons.mail,
            label: 'Letter',
            onTap: () => onSelect(4),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: Colors.pink),
            SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
