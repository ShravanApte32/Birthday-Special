// lib/main.dart — Sparkling Birthday Surprise App
// Enhanced with animations and visual appeal:
// - Added shimmer effects, floating animations, and scale transitions
// - Improved visual feedback with bouncy animations
// - Added particle effects and glowing elements
// - Enhanced micro-interactions while maintaining all original logic

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(BirthdayApp());

class BirthdayApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final primary = Color(0xFFFF6B9A);
    final accent = Color(0xFFFFC1E3);

    return MaterialApp(
      title: 'A Birthday for Her',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: accent,
        ),
        scaffoldBackgroundColor: Color(0xFFFFFBFD),
        fontFamily: 'Montserrat',
        appBarTheme: AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 6,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: primary),
        ),
        cardTheme: CardThemeData(
          // ← Correct: CardThemeData
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  // CONFIG
  final DateTime unlockAt = DateTime(2025, 11, 26, 0, 0);
  final String spotifyUrl = 'https://open.spotify.com/';

  // STATE
  bool unlocked = false;
  Duration remaining = Duration.zero;
  Timer? _clock;

  final AudioPlayer _messageAudio =
      AudioPlayer(); // Separate audio player for message
  bool messagePlaying = false;

  // Animations
  late ConfettiController _confetti;
  late AnimationController _sparkleController;
  late Animation<double> _sparkleAnimation;
  final AudioPlayer _audio = AudioPlayer();
  bool musicPlaying = false;

  // Content
  final List<String> letters = [
    "You turn ordinary nights into something I wait for — your laugh, your words, your presence.",
    "Late-night talks with you are my favourite place to be.",
    "You are patient, loyal and softer than the moonlight — I love that about you.",
    "I promise to travel every small road by your side, even from afar.",
    "Every plan I make has one wish at the center: more time with you.",
    "You make an ordinary day feel like a celebration.",
    "When we meet, I'll hold you and never let go — that's my promise.",
  ];

  // Promise wall
  List<Map<String, dynamic>> promises = [
    {"text": "Communicate openly, even on tough days", "done": false},
    {
      "text": "Plan our first trip together and make it unforgettable",
      "done": false,
    },
    {
      "text": "Never sleep angry — always solve things with love",
      "done": false,
    },
    {"text": "Support each other’s dreams without hesitation", "done": false},
    {"text": "Make time for us, no matter how busy life gets", "done": false},
    {"text": "Celebrate small wins and milestones together", "done": false},
    {"text": "Be patient with distance and trust the journey", "done": false},
    {
      "text": "Create memories that we’ll laugh about years later",
      "done": false,
    },
    {"text": "Keep growing individually and together", "done": false},
  ];

  // Wish bubbles
  final TextEditingController wishController = TextEditingController();
  final List<_FloatingWish> floatingWishes = [];

  // Planner
  final TextEditingController planTitle = TextEditingController();
  final TextEditingController planDate = TextEditingController();
  List<Map<String, dynamic>> plans = [];

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: Duration(seconds: 3));
    _sparkleController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
    _sparkleAnimation = CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeInOut,
    );
    _startClock();
    _loadState();
  }

  // ------------------- CLOCK / UNLOCK -------------------
  void _startClock() {
    _updateRemaining();
    _clock?.cancel();
    _clock = Timer.periodic(Duration(seconds: 1), (_) => _updateRemaining());
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final rem = unlockAt.difference(now);
    if (!mounted) return;
    setState(() {
      if (rem.isNegative || rem == Duration.zero) {
        remaining = Duration.zero;
        if (!unlocked) _onUnlocked();
      } else {
        remaining = rem;
      }
    });
  }

  void _onUnlocked() {
    setState(() {
      unlocked = true;
    });
    _confetti.play();
    _saveUnlocked(true);
  }

  // ------------------- AUDIO -------------------

  Future<void> _stopMusic() async {
    try {
      await _audio.stop();
    } catch (e) {
      print('stop audio error: $e');
    }
    setState(() => musicPlaying = false);
  }

  // ------------------- PERSISTENCE -------------------
  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      unlocked = prefs.getBool('unlocked') ?? unlocked;
      final p = prefs.getString('promises');
      if (p != null) {
        try {
          final list = jsonDecode(p) as List;
          promises = list.map((e) => Map<String, dynamic>.from(e)).toList();
        } catch (e) {
          print('promises load error: $e');
        }
      }

      final plansJson = prefs.getString('plans');
      if (plansJson != null) {
        try {
          final list = jsonDecode(plansJson) as List;
          plans = list.map((e) => Map<String, dynamic>.from(e)).toList();
        } catch (e) {
          print('plans load error: $e');
        }
      }
    });
  }

  Future<void> _saveUnlocked(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('unlocked', v);
  }

  Future<void> _savePromises() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('promises', jsonEncode(promises));
  }

  // ------------------- UTIL -------------------
  String _formatDuration(Duration d) {
    if (d.inDays > 0)
      return '${d.inDays}d ${d.inHours % 24}h ${d.inMinutes % 60}m ${d.inSeconds % 60}s';
    return '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _clock?.cancel();
    _confetti.dispose();
    _sparkleController.dispose();
    _audio.dispose();
    _messageAudio.dispose(); // ADD THIS LINE
    wishController.dispose();
    planTitle.dispose();
    planDate.dispose();
    super.dispose();
  }

  // ------------------- BUILD -------------------
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.celebration, color: Colors.yellow),
              SizedBox(width: 8),
              Text('A Birthday Surprise'),
              SizedBox(width: 8),
              Icon(Icons.favorite, color: Colors.red),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background sparkles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _sparkleAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _SparklePainter(_sparkleAnimation.value),
                );
              },
            ),
          ),

          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                unlocked ? _buildUnlockedHeader() : _buildLockedHeader(),
                SizedBox(height: 24),
                _buildGiftCard(),
                SizedBox(height: 16),
                _buildSpecialMessageCard(),
                SizedBox(height: 16),
                _buildLettersCard(),
                SizedBox(height: 16),
                _buildActionButtons(),
                SizedBox(height: 16),
                Text(
                  'From Your Love, Hubby and Your\'s truly always — Daddy ❤️',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),

          // confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [
                Color(0xFFFF6B9A),
                Color(0xFFB76BA3),
                Color(0xFFFFD1EA),
                Colors.yellow,
                Colors.white,
              ],
              numberOfParticles: 30,
            ),
          ),

          // floating wishes
          ...floatingWishes.asMap().entries.map((e) {
            final idx = e.key;
            final wleft = 18.0 + (idx % 3) * (w * 0.28);
            return Positioned(
              left: wleft,
              bottom: 18 + idx * 28.0,
              child: _FloatingBubble(text: e.value.text),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildLockedHeader() {
    return Column(
      children: [
        SizedBox(height: 20),
        AnimatedContainer(
          duration: Duration(milliseconds: 500),
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [Colors.pink[100]!, Colors.pink[300]!],
              stops: [0.3, 1.0],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.lock, size: 80, color: Colors.white),
              Positioned(
                right: 20,
                top: 20,
                child: ScaleTransition(
                  scale: _sparkleAnimation,
                  child: Icon(Icons.star, size: 24, color: Colors.yellow),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        AnimatedOpacity(
          opacity: 1.0,
          duration: Duration(milliseconds: 500),
          child: Text(
            'A surprise for you',
            style: TextStyle(
              fontSize: 20,
              color: Colors.pink[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Unlocks at midnight',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        SizedBox(height: 16),
        BounceInCard(
          child: Card(
            elevation: 6,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    _formatDuration(remaining),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'until ${unlockAt.day} ${_monthName(unlockAt.month)} ${unlockAt.year}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnlockedHeader() {
    return Column(
      children: [
        SizedBox(height: 10),
        BounceInAnimation(
          child: Container(
            width: 200,
            height: 200,
            child: LottieBuilder.asset(
              'assets/lottie/birthday_balloons.json',
              fit: BoxFit.contain,
              repeat: true,
              errorBuilder: (_, __, ___) => Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Colors.pink[100]!, Colors.pink[300]!],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cake, size: 60, color: Colors.white),
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        FadeInAnimation(
          delay: 300,
          child: Text(
            'Happy Birthday! ❤️',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.pink[700],
            ),
          ),
        ),
        SizedBox(height: 8),
        FadeInAnimation(
          delay: 500,
          child: Text(
            'Every moment with you is a gift',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialMessageCard() {
    return BounceInAnimation(
      delay: 300,
      child: Card(
        elevation: 6,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Special Message',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                    ),
                  ),
                  Icon(Icons.record_voice_over, color: Colors.purple[600]),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'A personal message from my heart to yours',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: unlocked ? _openMessagePlayer : null,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: unlocked
                        ? LinearGradient(
                            colors: [Colors.purple[50]!, Colors.purple[100]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [Colors.grey[100]!, Colors.grey[200]!],
                          ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: unlocked ? Colors.purple[200]! : Colors.grey[300]!,
                      width: 2,
                    ),
                    boxShadow: unlocked
                        ? [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: unlocked
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ScaleTransition(
                                    scale: _sparkleAnimation,
                                    child: Icon(
                                      Icons.voice_chat,
                                      size: 40,
                                      color: Colors.purple[400],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap to hear my message',
                                    style: TextStyle(
                                      color: Colors.purple[600],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Unlocks on your birthday',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                      ),
                      if (unlocked && messagePlaying)
                        Positioned(
                          right: 10,
                          top: 10,
                          child: ScaleTransition(
                            scale: _sparkleAnimation,
                            child: Icon(
                              Icons.volume_up,
                              size: 16,
                              color: Colors.purple[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add this method to open the message player
  void _openMessagePlayer() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => _MessagePlayerDialog(
        onPlay: _playSpecialMessage,
        onReplay: _replaySpecialMessage,
        onStop: _stopSpecialMessage,
      ),
    );
  }

  void _stopSpecialMessage() async {
    try {
      await _messageAudio.stop();
      setState(() => messagePlaying = false);
    } catch (e) {
      print('stop message error: $e');
    }
  }

  void _playSpecialMessage() async {
    try {
      await _stopMusic(); // Stop song if playing
      _stopSpecialMessage(); // Stop if already playing
      await _messageAudio.play(AssetSource('audio/birthday_greetings.mp3'));
      setState(() => messagePlaying = true);
    } catch (e) {
      print('message play error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _replaySpecialMessage() async {
    try {
      await _messageAudio.stop();
      await _messageAudio.play(AssetSource('audio/birthday_greetings.mp3'));
      setState(() => messagePlaying = true);
    } catch (e) {
      print('replay message error: $e');
    }
  }

  Widget _buildGiftCard() {
    return BounceInAnimation(
      delay: 200,
      child: Card(
        elevation: 6,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Special Gift',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink[700],
                    ),
                  ),
                  ScaleTransition(
                    scale: _sparkleAnimation,
                    child: Icon(
                      unlocked ? Icons.verified : Icons.lock,
                      color: unlocked ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: unlocked ? _openSongPlayer : null,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: unlocked
                        ? LinearGradient(
                            colors: [Colors.pink[50]!, Colors.pink[100]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [Colors.grey[100]!, Colors.grey[200]!],
                          ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: unlocked ? Colors.pink[200]! : Colors.grey[300]!,
                      width: 2,
                    ),
                    boxShadow: unlocked
                        ? [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: unlocked
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ScaleTransition(
                                    scale: _sparkleAnimation,
                                    child: Icon(
                                      Icons.album,
                                      size: 50,
                                      color: Colors.pink[400],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'A Song Just For You',
                                    style: TextStyle(
                                      color: Colors.pink[600],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Tap to listen to my heart',
                                    style: TextStyle(
                                      color: Colors.pink[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Unlocks on your birthday',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                      ),
                      if (unlocked)
                        Positioned(
                          right: 10,
                          top: 10,
                          child: ScaleTransition(
                            scale: _sparkleAnimation,
                            child: Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.yellow,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSongPlayer() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => _SongPlayerDialog(
        onPlay: _playSpecialSong,
        onReplay: _replaySpecialSong,
        onStop: _stopSpecialSong,
      ),
    );
  }

  void _stopSpecialSong() async {
    try {
      await _audio.stop();
    } catch (e) {
      print('stop song error: $e');
    }
  }

  void _playSpecialSong() async {
    try {
      await _stopMusic();
      await _audio.play(AssetSource('audio/birthday_song.mp3'));
    } catch (e) {
      print('song play error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing song'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _replaySpecialSong() async {
    try {
      await _audio.stop();
      await _audio.play(AssetSource('audio/birthday_song.mp3'));
    } catch (e) {
      print('replay error: $e');
    }
  }

  Widget _buildLettersCard() {
    return BounceInAnimation(
      delay: 400,
      child: Card(
        elevation: 6,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.email, color: Colors.pink[700]),
                  SizedBox(width: 8),
                  Text(
                    'Letters for You',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink[700],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'Tap each card to read my thoughts',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              SizedBox(height: 16),
              // Fixed the mapping - using simple for loop instead of map().toList()
              for (int i = 0; i < letters.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: _LetterWidget(text: letters[i], index: i),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return BounceInAnimation(
      delay: 600,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: _AnimatedButton(
                onPressed: _randomReason,
                icon: Icons.favorite_border,
                label: 'Why I love you',
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: _AnimatedButton(
                onPressed: _openPromiseEditor,
                icon: Icons.assignment,
                label: 'Our promises',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _randomReason() {
    final r = [
      'Your laugh is my favorite sound.',
      'You see the good in everything and everyone.',
      'Your kindness touches everyone around you.',
      'You make me want to be a better person.',
      'Your strength inspires me every day.',
      'You understand me like no one else.',
      'Your smile brightens even the darkest days.',
    ];
    final pick = r[DateTime.now().millisecondsSinceEpoch % r.length];
    showDialog(
      context: context,
      builder: (c) => ScaleTransition(
        scale: CurvedAnimation(
          parent: ModalRoute.of(c)!.animation!,
          curve: Curves.elasticOut,
        ),
        child: AlertDialog(
          backgroundColor: Colors.pink[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.favorite, color: Colors.pink),
              SizedBox(width: 8),
              Text('Why I Love You'),
            ],
          ),
          content: Text(pick),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: Text('❤️')),
          ],
        ),
      ),
    );
  }

  void _openPromiseEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => _PromiseEditor(
        promises: promises,
        onChanged: (newList) {
          setState(() => promises = newList);
          _savePromises();
        },
      ),
    );
  }

  String _monthName(int m) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[m - 1];
  }
}

// ------------------- ANIMATED SUB WIDGETS -------------------
class _LetterWidget extends StatefulWidget {
  final String text;
  final int index;
  const _LetterWidget({Key? key, required this.text, required this.index})
    : super(key: key);
  @override
  State<_LetterWidget> createState() => _LetterWidgetState();
}

class _LetterWidgetState extends State<_LetterWidget> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: open ? Colors.pink[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: open ? Colors.pink[200]! : Colors.grey[200]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => open = !open),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: open ? Colors.pink[100] : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                open ? Icons.favorite : Icons.email,
                color: open ? Colors.pink[600] : Colors.grey[600],
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: AnimatedCrossFade(
                firstChild: Text(
                  'Tap to open',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                secondChild: Text(
                  widget.text, // This should display the letter text
                  style: TextStyle(height: 1.4, color: Colors.grey[800]),
                ),
                crossFadeState: open
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: Duration(milliseconds: 200),
              ),
            ),
            Icon(
              open ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey[500],
            ),
          ],
        ),
      ),
    );
  }
}

class _PromiseEditor extends StatefulWidget {
  final List<Map<String, dynamic>> promises;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;
  const _PromiseEditor({
    Key? key,
    required this.promises,
    required this.onChanged,
  }) : super(key: key);
  @override
  State<_PromiseEditor> createState() => _PromiseEditorState();
}

class _PromiseEditorState extends State<_PromiseEditor> {
  late List<Map<String, dynamic>> list;
  final TextEditingController ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    list = List.from(widget.promises);
  }

  @override
  Widget build(BuildContext context) {
    // limit the height so the bottom sheet doesn't take full screen and allows scrolling
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return SizedBox(
      height: maxHeight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Our Promises',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink[700],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 16),

            // ---------- SCROLLABLE AREA ----------
            Expanded(
              child: list.isEmpty
                  ? SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: ScaleTransition(
                        scale: CurvedAnimation(
                          parent: ModalRoute.of(context)!.animation!,
                          curve: Curves.elasticOut,
                        ),
                        child: Container(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.assignment,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'No promises yet',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              Text(
                                'Add our first promise to each other',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(bottom: 8),
                      itemCount: list.length,
                      itemBuilder: (context, idx) {
                        final item = list[idx];
                        return SlideInAnimation(
                          delay: idx * 100,
                          child: Container(
                            margin: EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: CheckboxListTile(
                              value: item['done'] ?? false,
                              onChanged: (v) {
                                setState(() => list[idx]['done'] = v);
                                widget.onChanged(list);
                              },
                              title: Text(
                                item['text'] ?? '',
                                style: TextStyle(
                                  decoration: (item['done'] ?? false)
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: (item['done'] ?? false)
                                      ? Colors.grey[500]
                                      : Colors.black87,
                                ),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: Colors.pink[400],
                              checkColor: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // ---------- END SCROLLABLE AREA ----------
            // SizedBox(height: 12),
            // Row(
            //   children: [
            //     Expanded(
            //       child: TextField(
            //         controller: ctrl,
            //         decoration: InputDecoration(
            //           hintText: 'Add a new promise...',
            //           border: OutlineInputBorder(
            //             borderRadius: BorderRadius.circular(8),
            //           ),
            //           contentPadding: EdgeInsets.symmetric(
            //             horizontal: 16,
            //             vertical: 12,
            //           ),
            //         ),
            //       ),
            //     ),
            //     SizedBox(width: 12),
            //     ScaleTransition(
            //       scale: CurvedAnimation(
            //         parent: ModalRoute.of(context)!.animation!,
            //         curve: Curves.elasticOut,
            //       ),
            //       child: Container(
            //         decoration: BoxDecoration(
            //           gradient: LinearGradient(
            //             colors: [Colors.pink[400]!, Colors.pink[600]!],
            //           ),
            //           borderRadius: BorderRadius.circular(8),
            //           boxShadow: [
            //             BoxShadow(
            //               color: Colors.pink.withOpacity(0.3),
            //               blurRadius: 8,
            //             ),
            //           ],
            //         ),
            //         child: IconButton(
            //           onPressed: () {
            //             final t = ctrl.text.trim();
            //             if (t.isEmpty) return;
            //             setState(() {
            //               list.add({'text': t, 'done': false});
            //               ctrl.clear();
            //             });
            //             widget.onChanged(list);
            //           },
            //           icon: Icon(Icons.add, color: Colors.white),
            //         ),
            //       ),
            //     ),
            //   ],
            // ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 8),
          ],
        ),
      ),
    );
  }
}

// ------------------- ANIMATION WIDGETS -------------------
class BounceInAnimation extends StatefulWidget {
  final Widget child;
  final int delay;
  const BounceInAnimation({Key? key, required this.child, this.delay = 0})
    : super(key: key);
  @override
  State<BounceInAnimation> createState() => _BounceInAnimationState();
}

class _BounceInAnimationState extends State<BounceInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _animation, child: widget.child);
  }
}

class FadeInAnimation extends StatefulWidget {
  final Widget child;
  final int delay;
  const FadeInAnimation({Key? key, required this.child, this.delay = 0})
    : super(key: key);
  @override
  State<FadeInAnimation> createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}

class SlideInAnimation extends StatefulWidget {
  final Widget child;
  final int delay;
  const SlideInAnimation({Key? key, required this.child, this.delay = 0})
    : super(key: key);
  @override
  State<SlideInAnimation> createState() => _SlideInAnimationState();
}

class _SlideInAnimationState extends State<SlideInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _animation, child: widget.child);
  }
}

class BounceInCard extends StatefulWidget {
  final Widget child;
  const BounceInCard({Key? key, required this.child}) : super(key: key);
  @override
  State<BounceInCard> createState() => _BounceInCardState();
}

class _BounceInCardState extends State<BounceInCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value * 4),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  const _AnimatedButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    required this.label,
  }) : super(key: key);
  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(
        begin: 1.0,
        end: 0.95,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: ElevatedButton.icon(
        onPressed: _onTap,
        icon: Icon(widget.icon),
        label: Text(widget.label),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12),
          minimumSize: Size(0, 0), // Allows button to be smaller
        ),
      ),
    );
  }
}

class _FloatingBubble extends StatefulWidget {
  final String text;
  const _FloatingBubble({Key? key, required this.text}) : super(key: key);
  @override
  State<_FloatingBubble> createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<_FloatingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _controller.value * 10),
          child: Opacity(opacity: 1.0 - _controller.value * 0.3, child: child),
        );
      },
      child: Chip(
        label: Text(widget.text),
        backgroundColor: Colors.pink[50],
        side: BorderSide(color: Colors.pink[100]!),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final double animationValue;
  _SparklePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.pink.withOpacity(0.1 * animationValue)
      ..style = PaintingStyle.fill;

    final sparkleCount = 20;
    for (int i = 0; i < sparkleCount; i++) {
      final x = (i * 37) % size.width;
      final y = (i * 53) % size.height;
      final radius = 1 + animationValue * 2;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _FloatingWish {
  final String text;
  final String id;
  _FloatingWish({required this.text, required this.id});
}

class _SongPlayerDialog extends StatefulWidget {
  final VoidCallback onPlay;
  final VoidCallback onReplay;
  final VoidCallback onStop;

  const _SongPlayerDialog({
    Key? key,
    required this.onPlay,
    required this.onReplay,
    required this.onStop,
  }) : super(key: key);

  @override
  State<_SongPlayerDialog> createState() => _SongPlayerDialogState();
}

class _SongPlayerDialogState extends State<_SongPlayerDialog>
    with SingleTickerProviderStateMixin {
  bool isPlaying = false;
  bool hasPlayed = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    )..repeat();
    _startPlaying();
  }

  void _startPlaying() {
    widget.onPlay();
    setState(() {
      isPlaying = true;
      hasPlayed = true;
    });
  }

  void _replaySong() {
    widget.onReplay();
    setState(() {
      isPlaying = true;
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    widget.onStop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: ModalRoute.of(context)!.animation!,
        curve: Curves.elasticOut,
      ),
      child: AlertDialog(
        backgroundColor: Colors.pink[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            RotationTransition(
              turns: _rotationController,
              child: Icon(Icons.album, color: Colors.pink[700]),
            ),
            SizedBox(width: 10),
            Text(
              'My Song For You',
              style: TextStyle(
                color: Colors.pink[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.pink[100]!, Colors.pink[300]!],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.pink[300]!, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: RotationTransition(
                turns: _rotationController,
                child: Icon(Icons.music_note, size: 50, color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'I made this song just for you...\nEvery note is filled with my love',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.pink[800],
                fontSize: 14,
                height: 1.4,
              ),
            ),
            SizedBox(height: 16),
            if (isPlaying)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.volume_up, color: Colors.pink[600], size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Now playing...',
                      style: TextStyle(
                        color: Colors.pink[600],
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  widget.onStop();
                  Navigator.pop(context);
                },
                child: Text('Close'),
              ),
              if (hasPlayed)
                ElevatedButton.icon(
                  onPressed: _replaySong,
                  icon: Icon(Icons.replay),
                  label: Text('Play Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink[600],
                    foregroundColor: Colors.white,
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _startPlaying,
                  icon: Icon(Icons.play_arrow),
                  label: Text('Play Song'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink[600],
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// Add the Message Player Dialog class at the bottom of your file
class _MessagePlayerDialog extends StatefulWidget {
  final VoidCallback onPlay;
  final VoidCallback onReplay;
  final VoidCallback onStop;

  const _MessagePlayerDialog({
    Key? key,
    required this.onPlay,
    required this.onReplay,
    required this.onStop,
  }) : super(key: key);

  @override
  State<_MessagePlayerDialog> createState() => _MessagePlayerDialogState();
}

class _MessagePlayerDialogState extends State<_MessagePlayerDialog>
    with SingleTickerProviderStateMixin {
  bool isPlaying = false;
  bool hasPlayed = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _startPlaying();
  }

  void _startPlaying() {
    widget.onPlay();
    setState(() {
      isPlaying = true;
      hasPlayed = true;
    });
  }

  void _replayMessage() {
    widget.onReplay();
    setState(() {
      isPlaying = true;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    widget.onStop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: ModalRoute.of(context)!.animation!,
        curve: Curves.elasticOut,
      ),
      child: AlertDialog(
        backgroundColor: Colors.purple[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Icon(
                  Icons.record_voice_over,
                  color: Colors.purple[700],
                  size: 24 + (_pulseController.value * 4),
                );
              },
            ),
            SizedBox(width: 10),
            Text(
              'My Special Message',
              style: TextStyle(
                color: Colors.purple[700],
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.purple[100]!, Colors.purple[300]!],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.purple[300]!, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Icon(
                    Icons.voice_chat,
                    size: 50 + (_pulseController.value * 10),
                    color: Colors.white,
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Text(
              'My special message for you...\nEvery word comes straight from my heart',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.purple[800],
                fontSize: 14,
                height: 1.4,
              ),
            ),
            SizedBox(height: 16),
            if (isPlaying)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.volume_up, color: Colors.purple[600], size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Playing your special message...',
                      style: TextStyle(
                        color: Colors.purple[600],
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  widget.onStop();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.purple[600],
                ),
                child: Text('Close'),
              ),
              if (hasPlayed)
                ElevatedButton.icon(
                  onPressed: _replayMessage,
                  icon: Icon(Icons.replay),
                  label: Text('Play Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                    foregroundColor: Colors.white,
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _startPlaying,
                  icon: Icon(Icons.play_arrow),
                  label: Text('Play Message'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
