import 'dart:async';
import 'dart:math';
import 'dart:ui' show FontFeature;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// CONFIG: edit these
// ============================================================
const herName = 'Rishuuu💕';
const fromName = 'Daddy❤️';

// Unlock moment (device local time). 12:00 am on 26 Nov 2026.
final DateTime unlockTime = DateTime(2026, 11, 26, 0, 0);

// Set to true while testing: unlocks 10 seconds after the lock screen opens
// and ignores the saved "already unlocked" flag.
const bool debugQuickUnlock = false;

const voiceNoteAsset = 'assets/audio/birthday_greetings.mp3';

// Birthday song: starts when the lock opens, loops until the candles are out.
// If your file has a different name or extension, change it here AND in
// pubspec.yaml.
const birthdaySongAsset = 'assets/audio/birthday_song.mp3';

// 0.0 to 1.0. Keep it modest: the mic can hear the song, so a loud song can
// put the candles out by itself.
const double songVolume = 0.1;

// Blow detection: a mic reading at or above this loudness (dB) puts out one
// candle. Blowing into the mic is usually 85+ dB, normal talking is lower.
// Raise it if talking puts them out, lower it if blowing does nothing.
const double blowThresholdDb = 78;

// true = shows the live mic dB reading under the cake so you can tune the
// threshold. Set back to false for the real build.
const bool showMicDebug = false;

const wishes = <String>[
  'Happy 18th birthday! You are officially an adult, but you will always be my favourite kid at heart.',
  'Every day with you feels like a gift. Today I get to celebrate the best one.',
  'I hope this year brings you everything you have been dreaming of, and more.',
  'No matter how far apart we are, you are always right here with me.',
  'Make a wish, my love. I will do everything I can to make it come true.',
];

// ============================================================
// THEME
// ============================================================
const kBgTop = Color(0xFF120A2A);
const kBgMid = Color(0xFF2A1250);
const kBgBottom = Color(0xFF5A2468);
const kPink = Color(0xFFFF8FB1);
const kRose = Color(0xFFE56B9A);
const kGold = Color(0xFFFFD27D);
const kLilac = Color(0xFFB69CFF);

TextStyle script(double size, {Color color = Colors.white}) => TextStyle(
      fontFamily: 'Pacifico',
      fontSize: size,
      color: color,
      height: 1.25,
    );

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

Path heartPath(Offset c, double s) {
  final p = Path()..moveTo(c.dx, c.dy + s);
  p.cubicTo(c.dx - 1.4 * s, c.dy - 0.1 * s, c.dx - 0.6 * s, c.dy - 1.1 * s,
      c.dx, c.dy - 0.4 * s);
  p.cubicTo(c.dx + 0.6 * s, c.dy - 1.1 * s, c.dx + 1.4 * s, c.dy - 0.1 * s,
      c.dx, c.dy + s);
  p.close();
  return p;
}

// ============================================================
// BIRTHDAY SONG (one shared player: lock screen starts it, home stops it)
// ============================================================
class BirthdayMusic {
  static final AudioPlayer _p = AudioPlayer();
  static Future<void>? _loading;
  static bool _stopped = false;

  static Future<void> _load() => _loading ??= () async {
        await _p.setAsset(birthdaySongAsset);
        await _p.setLoopMode(LoopMode.one);
      }();

  /// Safe to call many times: does nothing if already playing or finished.
  static Future<void> start() async {
    if (_stopped) return;
    try {
      await _load();
      if (_stopped) return;
      await _p.setVolume(songVolume);
      if (!_p.playing) _p.play(); // not awaited: completes when playback ends
    } catch (_) {
      // missing file or audio error: the app just carries on silently
    }
  }

  static Future<void> pause() async {
    try {
      await _p.pause();
    } catch (_) {}
  }

  static Future<void> fadeOutAndStop() async {
    if (_stopped) return;
    _stopped = true;
    try {
      for (var i = 9; i >= 0; i--) {
        await _p.setVolume(songVolume * i / 10);
        await Future.delayed(const Duration(milliseconds: 150));
      }
      await _p.stop();
    } catch (_) {}
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  runApp(const BirthdayApp());
}

class BirthdayApp extends StatelessWidget {
  const BirthdayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Happy Birthday',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPink,
          brightness: Brightness.dark,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ============================================================
// BACK BUTTON: never drops her out of the app by accident.
// confirmExit false = back does nothing (splash).
// confirmExit true  = press back twice within 2 seconds to leave.
// ============================================================
class GuardedScaffold extends StatefulWidget {
  final Widget body;
  final bool confirmExit;
  const GuardedScaffold({
    super.key,
    required this.body,
    this.confirmExit = true,
  });

  @override
  State<GuardedScaffold> createState() => _GuardedScaffoldState();
}

class _GuardedScaffoldState extends State<GuardedScaffold> {
  DateTime? _lastBack;

  void _onBack() {
    if (!widget.confirmExit) return;
    final now = DateTime.now();
    if (_lastBack != null &&
        now.difference(_lastBack!) < const Duration(seconds: 2)) {
      BirthdayMusic.pause();
      SystemNavigator.pop();
      return;
    }
    _lastBack = now;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text(
          'Press back again to exit',
          textAlign: TextAlign.center,
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color.fromARGB(255, 183, 138, 255),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(body: widget.body),
    );
  }
}

Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 900),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    );

// ============================================================
// SHARED: reveal animation + ambient animated background
// ============================================================
class Reveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double slide;
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.slide = 0.15,
  });

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _show = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _show ? 1 : 0,
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _show ? Offset.zero : Offset(0, widget.slide),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _Particle {
  final double x, y, size, phase;
  final int speed, twinkle;
  final bool heart;
  _Particle(this.x, this.y, this.size, this.phase, this.speed, this.twinkle,
      this.heart);
}

class AmbientBg extends StatefulWidget {
  final Widget child;
  final bool
      rising; // true: hearts and sparkles float up. false: twinkling stars.
  final int count;
  const AmbientBg({
    super.key,
    required this.child,
    this.rising = false,
    this.count = 60,
  });

  @override
  State<AmbientBg> createState() => _AmbientBgState();
}

class _AmbientBgState extends State<AmbientBg>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  )..repeat();
  late final List<_Particle> _ps;

  @override
  void initState() {
    super.initState();
    final r = Random(7);
    _ps = List.generate(widget.count, (_) {
      return _Particle(
        r.nextDouble(),
        r.nextDouble(),
        widget.rising ? 2 + r.nextDouble() * 6 : 0.8 + r.nextDouble() * 1.8,
        r.nextDouble(),
        1 + r.nextInt(3),
        2 + r.nextInt(5),
        widget.rising && r.nextDouble() < 0.45,
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kBgTop, kBgMid, kBgBottom],
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.5),
                radius: 0.9,
                colors: [kPink.withOpacity(0.16), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) => CustomPaint(
                  painter: _ParticlePainter(_ps, _c.value, widget.rising),
                ),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> ps;
  final double t;
  final bool rising;
  _ParticlePainter(this.ps, this.t, this.rising);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in ps) {
      final tw = 0.5 + 0.5 * sin(2 * pi * (t * p.twinkle + p.phase));
      double y = p.y;
      double dx = 0;
      if (rising) {
        y = (p.y - t * p.speed) % 1.0;
        dx = sin(2 * pi * (t * p.speed + p.phase)) * 14;
      }
      final pos = Offset(p.x * size.width + dx, y * size.height);
      if (rising) {
        // fade near top and bottom so particles don't pop
        final edge = min(y, 1 - y).clamp(0.0, 0.12).toDouble() / 0.12;
        final op = (0.12 + 0.3 * tw) * edge;
        paint.color = (p.heart ? kPink : Colors.white).withOpacity(op);
        if (p.heart) {
          canvas.drawPath(heartPath(pos, p.size), paint);
        } else {
          canvas.drawCircle(pos, p.size * 0.5, paint);
        }
      } else {
        paint.color = Colors.white.withOpacity(0.08 + 0.2 * tw);
        canvas.drawCircle(pos, p.size * 2.6, paint);
        paint.color = Colors.white.withOpacity(0.25 + 0.75 * tw);
        canvas.drawCircle(pos, p.size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}

BoxDecoration glass({double radius = 24}) => BoxDecoration(
      color: Colors.white.withOpacity(0.07),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(0.14)),
    );

// ============================================================
// 1. SPLASH
// ============================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();
  late final AnimationController _beat = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _heart = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
  );
  late final Animation<double> _beatScale = Tween(begin: 1.0, end: 1.12)
      .animate(CurvedAnimation(parent: _beat, curve: Curves.easeInOut));
  late final Animation<double> _t1 = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
  );
  late final Animation<double> _t2 = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
  );
  late final Animation<Offset> _s1 =
      Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(_t1);
  late final Animation<Offset> _s2 =
      Tween(begin: const Offset(0, 0.6), end: Offset.zero).animate(_t2);

  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final prefs = await SharedPreferences.getInstance();
    final unlocked = !debugQuickUnlock && (prefs.getBool('unlocked') ?? false);
    await Future.delayed(const Duration(milliseconds: 3200));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      fadeRoute(unlocked ? const HomeScreen() : const LockScreen()),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GuardedScaffold(
      confirmExit: false,
      body: AmbientBg(
        rising: false,
        count: 60,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            kPink.withOpacity(0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    ScaleTransition(
                      scale: _heart,
                      child: ScaleTransition(
                        scale: _beatScale,
                        child: const Icon(
                          Icons.favorite,
                          size: 100,
                          color: kPink,
                          shadows: [Shadow(color: kPink, blurRadius: 36)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              FadeTransition(
                opacity: _t1,
                child: SlideTransition(
                  position: _s1,
                  child: Text('Something special',
                      style: script(30, color: kGold)),
                ),
              ),
              const SizedBox(height: 10),
              FadeTransition(
                opacity: _t2,
                child: SlideTransition(
                  position: _s2,
                  child: const Text(
                    'IS WAITING FOR YOU',
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 5,
                      color: Colors.white70,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 2. LOCK SCREEN
// ============================================================
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with TickerProviderStateMixin {
  late final DateTime _target = debugQuickUnlock
      ? DateTime.now().add(const Duration(seconds: 10))
      : unlockTime;
  Timer? _timer;
  late Duration _remaining = _target.difference(DateTime.now());
  bool _unlocking = false;

  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (_remaining.inSeconds <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        final r = _target.difference(DateTime.now());
        if (r.inSeconds <= 0) {
          _timer?.cancel();
          _unlock();
        } else {
          setState(() => _remaining = r);
        }
      });
    }
  }

  Future<void> _unlock() async {
    if (_unlocking || !mounted) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _unlocking = true;
      _remaining = Duration.zero;
    });
    _burst.forward();
    BirthdayMusic.start();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('unlocked', true);
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(fadeRoute(const HomeScreen()));
  }

  void _shakeLock() {
    if (_unlocking) return;
    HapticFeedback.mediumImpact();
    _shake.forward(from: 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ripple.dispose();
    _shake.dispose();
    _burst.dispose();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final d = _remaining.inDays;
    final h = _remaining.inHours % 24;
    final m = _remaining.inMinutes % 60;
    final s = _remaining.inSeconds % 60;
    final accent = _unlocking ? kGold : kPink;
    final dateLabel =
        '${unlockTime.day} ${_months[unlockTime.month - 1]} ${unlockTime.year}  ·  12:00 AM';

    return GuardedScaffold(
      body: Stack(
        children: [
          AmbientBg(
            rising: false,
            count: 90,
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _shakeLock,
                      child: AnimatedBuilder(
                        animation: _shake,
                        builder: (_, child) {
                          final dx = sin(_shake.value * pi * 7) *
                              14 *
                              (1 - _shake.value);
                          return Transform.translate(
                            offset: Offset(dx, 0),
                            child: child,
                          );
                        },
                        child: SizedBox(
                          width: 300,
                          height: 300,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _ripple,
                                builder: (_, __) => CustomPaint(
                                  size: const Size(300, 300),
                                  painter:
                                      _RipplePainter(_ripple.value, accent),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 600),
                                width: 132,
                                height: 132,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.16),
                                      Colors.white.withOpacity(0.04),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: accent.withOpacity(0.55),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withOpacity(0.38),
                                      blurRadius: 44,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 800),
                                switchInCurve: Curves.elasticOut,
                                transitionBuilder: (child, anim) =>
                                    ScaleTransition(scale: anim, child: child),
                                child: Icon(
                                  _unlocking
                                      ? Icons.lock_open_rounded
                                      : Icons.lock_rounded,
                                  key: ValueKey(_unlocking),
                                  size: 64,
                                  color: _unlocking ? kGold : Colors.white,
                                  shadows: [
                                    Shadow(color: accent, blurRadius: 24),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Reveal(
                      delay: const Duration(milliseconds: 200),
                      child: Column(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child: Text(
                              _unlocking ? "It's time!" : 'Not just yet...',
                              key: ValueKey(_unlocking),
                              style: script(32, color: kGold),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _unlocking
                                ? 'OPENING YOUR SURPRISE'
                                : 'YOUR SURPRISE UNLOCKS AT MIDNIGHT',
                            style: const TextStyle(
                              fontSize: 12,
                              letterSpacing: 3,
                              color: Colors.white60,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    AnimatedOpacity(
                      opacity: _unlocking ? 0 : 1,
                      duration: const Duration(milliseconds: 500),
                      child: Reveal(
                        delay: const Duration(milliseconds: 500),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (d > 0) _TimeBox(value: _two(d), label: 'DAYS'),
                            _TimeBox(value: _two(h), label: 'HOURS'),
                            _TimeBox(value: _two(m), label: 'MINS'),
                            _TimeBox(value: _two(s), label: 'SECS'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    AnimatedOpacity(
                      opacity: _unlocking ? 0 : 1,
                      duration: const Duration(milliseconds: 500),
                      child: Reveal(
                        delay: const Duration(milliseconds: 800),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 9),
                          decoration: glass(radius: 30),
                          child: Text(
                            dateLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_unlocking)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _burst,
                  builder: (_, __) {
                    final v = _burst.value;
                    final op = (sin(v * pi) * 0.6).clamp(0.0, 1.0).toDouble();
                    return Container(color: kGold.withOpacity(op));
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double t;
  final Color color;
  _RipplePainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (var k = 0; k < 3; k++) {
      final p = (t + k / 3) % 1.0;
      final radius = 66 + p * 84;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = color.withOpacity((1 - p) * 0.4);
      canvas.drawCircle(c, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.t != t || old.color != color;
}

class _TimeBox extends StatelessWidget {
  final String value;
  final String label;
  const _TimeBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.6),
                  end: Offset.zero,
                ).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Text(
                value,
                key: ValueKey(value),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: kGold,
                  height: 1.2,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              letterSpacing: 2,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 3. HOME
// ============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _wishesKey = GlobalKey();
  final _left = ConfettiController(duration: const Duration(seconds: 4));
  final _right = ConfettiController(duration: const Duration(seconds: 4));
  bool _blown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    BirthdayMusic.start(); // no-op if the lock screen already started it
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      BirthdayMusic.pause();
    } else if (state == AppLifecycleState.resumed) {
      BirthdayMusic.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _left.dispose();
    _right.dispose();
    super.dispose();
  }

  void _onAllOut() {
    BirthdayMusic.fadeOutAndStop();
    _left.play();
    _right.play();
    HapticFeedback.heavyImpact();
    if (_blown) return;
    setState(() => _blown = true);
    Future.delayed(const Duration(milliseconds: 2600), () {
      final ctx = _wishesKey.currentContext;
      if (ctx != null && mounted) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.05,
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  Widget _confetti(ConfettiController c, double dir) => ConfettiWidget(
        confettiController: c,
        blastDirection: dir,
        blastDirectionality: BlastDirectionality.directional,
        emissionFrequency: 0.04,
        numberOfParticles: 18,
        maxBlastForce: 28,
        minBlastForce: 10,
        gravity: 0.18,
        shouldLoop: false,
        colors: const [kPink, kGold, Colors.white, kLilac, kRose],
      );

  @override
  Widget build(BuildContext context) {
    return GuardedScaffold(
      body: AmbientBg(
        rising: true,
        count: 36,
        child: Stack(
          children: [
            Positioned.fill(
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 28, bottom: 24),
                  child: Column(
                    children: [
                      const Reveal(child: _Header()),
                      const SizedBox(height: 36),
                      Reveal(
                        delay: const Duration(milliseconds: 500),
                        child: CakeSection(onAllOut: _onAllOut),
                      ),
                      if (_blown) ...[
                        const SizedBox(height: 70),
                        Reveal(
                          delay: const Duration(milliseconds: 1200),
                          child: Container(
                            key: _wishesKey,
                            child: const WishCards(),
                          ),
                        ),
                        const SizedBox(height: 56),
                        const Reveal(
                          delay: Duration(milliseconds: 1800),
                          child: VoiceNotePlayer(),
                        ),
                        const SizedBox(height: 56),
                        const Reveal(
                          delay: Duration(milliseconds: 2200),
                          child: _Footer(),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: _confetti(_left, pi / 3),
            ),
            Align(
              alignment: Alignment.topRight,
              child: _confetti(_right, 2 * pi / 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'HAPPY',
          style: TextStyle(
            fontSize: 15,
            letterSpacing: 10,
            color: Colors.white70,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 4),
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kGold, kPink],
          ).createShader(r),
          child: const Text(
            '18',
            style: TextStyle(
              fontSize: 104,
              fontWeight: FontWeight.w600,
              height: 1.0,
              color: Colors.white,
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -10),
          child: Text('Birthday', style: script(40, color: kGold)),
        ),
        const SizedBox(height: 2),
        Text(
          herName.toUpperCase(),
          style: const TextStyle(
            fontSize: 14,
            letterSpacing: 6,
            color: Colors.white70,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.favorite,
            color: kPink,
            size: 28,
            shadows: [Shadow(color: kPink, blurRadius: 20)]),
        const SizedBox(height: 12),
        Text('With all my love,', style: script(20, color: Colors.white70)),
        Text(fromName, style: script(28, color: kGold)),
      ],
    );
  }
}

// ------------------------------------------------------------
// Cake: fully painted, flickering flames, smoke when blown out.
// Tap a candle, swipe your finger across them, or press the button.
// ------------------------------------------------------------
class CakeSection extends StatefulWidget {
  final VoidCallback onAllOut;
  const CakeSection({super.key, required this.onAllOut});

  @override
  State<CakeSection> createState() => _CakeSectionState();
}

class _CakeSectionState extends State<CakeSection>
    with TickerProviderStateMixin {
  static const _count = 5;
  static const _w = 320.0;
  static const _h = 340.0;

  late final AnimationController _flick = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();
  late final List<AnimationController> _ext = List.generate(
    _count,
    (_) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
      reverseDuration: const Duration(milliseconds: 500),
    ),
  );
  final List<bool> _out = List.filled(_count, false);
  bool _done = false;

  // microphone
  NoiseMeter? _meter;
  StreamSubscription<NoiseReading>? _micSub;
  bool _micDenied = false;
  double _lastDb = 0;

  static Offset candlePos(int i) => Offset(160 + (i - 2) * 38.0, 92);

  @override
  void initState() {
    super.initState();
    _startMic();
  }

  @override
  void dispose() {
    _micSub?.cancel();
    _flick.dispose();
    for (final c in _ext) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _startMic() async {
    if (_micSub != null) return;
    try {
      final status = await Permission.microphone.request();
      if (!mounted) return;
      if (!status.isGranted) {
        setState(() => _micDenied = true);
        return;
      }
      _meter ??= NoiseMeter();
      _micSub = _meter!.noise.listen(
        _onNoise,
        onError: (Object _) {
          _stopMic();
          if (mounted) setState(() => _micDenied = true);
        },
      );
      if (mounted) setState(() => _micDenied = false);
    } catch (_) {
      if (mounted) setState(() => _micDenied = true);
    }
  }

  void _stopMic() {
    _micSub?.cancel();
    _micSub = null;
  }

  void _onNoise(NoiseReading r) {
    if (_done) return;
    if (showMicDebug) setState(() => _lastDb = r.maxDecibel);
    if (r.maxDecibel >= blowThresholdDb) {
      final i = _out.indexOf(false);
      if (i != -1) _blow(i);
    }
  }

  void _blow(int i) {
    if (_out[i]) return;
    _out[i] = true;
    _ext[i].forward();
    HapticFeedback.selectionClick();
    setState(() {});
    if (_out.every((o) => o) && !_done) {
      _done = true;
      _stopMic();
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) widget.onAllOut();
      });
    }
  }

  // Tap or swipe on the candles still works (fallback if the mic is denied)
  void _hit(Offset p) {
    for (var i = 0; i < _count; i++) {
      final c = candlePos(i);
      if ((p.dx - c.dx).abs() < 22 && p.dy > c.dy - 40 && p.dy < c.dy + 50) {
        _blow(i);
      }
    }
  }

  void _relight() {
    HapticFeedback.lightImpact();
    for (var i = 0; i < _count; i++) {
      _out[i] = false;
      _ext[i].reverse();
    }
    _done = false;
    setState(() {});
    _startMic();
  }

  @override
  Widget build(BuildContext context) {
    final allOut = _out.every((o) => o);
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Text(
            allOut
                ? 'Hope your wish comes true'
                : (_micDenied
                    ? 'Make a wish, then tap the candles'
                    : 'Make a wish, then blow them out'),
            key: ValueKey('$allOut$_micDenied'),
            style: allOut
                ? script(20, color: kGold)
                : const TextStyle(
                    fontSize: 13,
                    letterSpacing: 2,
                    color: Colors.white70,
                    fontWeight: FontWeight.w300,
                  ),
          ),
        ),
        GestureDetector(
          onTapDown: (d) => _hit(d.localPosition),
          onPanUpdate: (d) => _hit(d.localPosition),
          child: SizedBox(
            width: _w,
            height: _h,
            child: CustomPaint(painter: _CakePainter(_flick, _ext)),
          ),
        ),
        const SizedBox(height: 22),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: allOut
              ? TextButton.icon(
                  key: const ValueKey('relight'),
                  onPressed: _relight,
                  icon: const Icon(Icons.local_fire_department, size: 18),
                  label: const Text('Light them again'),
                  style: TextButton.styleFrom(foregroundColor: kGold),
                )
              : _micDenied
                  ? TextButton.icon(
                      key: const ValueKey('retry'),
                      onPressed: _startMic,
                      icon: const Icon(Icons.mic_off_rounded, size: 18),
                      label: const Text('Enable microphone'),
                      style: TextButton.styleFrom(foregroundColor: kPink),
                    )
                  : AnimatedBuilder(
                      key: const ValueKey('listening'),
                      animation: _flick,
                      builder: (_, __) {
                        final p = sin(2 * pi * _flick.value);
                        return Column(
                          children: [
                            Transform.scale(
                              scale: 1 + 0.14 * p,
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: kPink.withOpacity(0.14),
                                  border: Border.all(
                                    color: kPink.withOpacity(0.5 + 0.3 * p),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kPink.withOpacity(0.25 + 0.15 * p),
                                      blurRadius: 24,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.mic_rounded,
                                    color: kPink, size: 30),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'BLOW INTO YOUR MIC',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 3,
                                color: Colors.white54,
                              ),
                            ),
                            if (showMicDebug)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  '${_lastDb.toStringAsFixed(1)} dB (need ${blowThresholdDb.toStringAsFixed(0)})',
                                  style: const TextStyle(
                                      fontSize: 11, color: kGold),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _CakePainter extends CustomPainter {
  final Animation<double> flick;
  final List<AnimationController> ext;
  _CakePainter(this.flick, this.ext)
      : super(repaint: Listenable.merge([flick, ...ext]));

  static const _candleColors = [kPink, kGold, kLilac, kGold, kPink];
  static const _sprinkles = [
    kGold,
    Colors.white,
    kLilac,
    Color(0xFF8FE3CF),
    kPink,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // ground glow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(160, 330), width: 300, height: 34),
      Paint()
        ..color = kPink.withOpacity(0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    // plate
    final plate = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 316, 320, 16),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      plate,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF3EEFB), Color(0xFFB9A8D9)],
        ).createShader(plate.outerRect),
    );

    // tiers: bottom first so upper tiers overlap
    _tier(canvas, const Rect.fromLTWH(20, 244, 280, 74), kRose,
        const Color(0xFFB8457E), 1);
    _tier(canvas, const Rect.fromLTWH(45, 182, 230, 68),
        const Color(0xFFFFB7CE), kRose, 2);
    _tier(canvas, const Rect.fromLTWH(70, 130, 180, 58), kPink,
        const Color(0xFFF07AA3), 3);

    // "18" on middle tier
    final tp = TextPainter(
      text: TextSpan(
        text: '18',
        style: TextStyle(
          fontFamily: 'Pacifico',
          fontSize: 32,
          color: Colors.white.withOpacity(0.95),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(160 - tp.width / 2, 202));

    // hearts on bottom tier
    final hp = Paint()..color = Colors.white.withOpacity(0.9);
    for (final x in [70.0, 115.0, 205.0, 250.0]) {
      canvas.drawPath(heartPath(Offset(x, 290), 6), hp);
    }
    canvas.drawPath(
        heartPath(const Offset(160, 290), 9), Paint()..color = kGold);

    // candles + flames
    for (var i = 0; i < ext.length; i++) {
      final p = _CakeSectionState.candlePos(i);
      _candle(canvas, p, _candleColors[i]);
      _flame(canvas, p, i, ext[i].value);
    }
  }

  void _tier(Canvas c, Rect r, Color top, Color bottom, int seed) {
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(14));
    c.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(r),
    );

    final rnd = Random(seed * 13);

    // sprinkles
    for (var n = 0; n < 16; n++) {
      final x = r.left + 12 + rnd.nextDouble() * (r.width - 24);
      final y = r.top + 30 + rnd.nextDouble() * (r.height - 40);
      c.save();
      c.translate(x, y);
      c.rotate(rnd.nextDouble() * pi);
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4, -1.5, 8, 3),
          const Radius.circular(1.5),
        ),
        Paint()..color = _sprinkles[rnd.nextInt(_sprinkles.length)],
      );
      c.restore();
    }

    // frosting band + drips
    final white = Paint()..color = Colors.white;
    c.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(r.left, r.top, r.width, 14),
        topLeft: const Radius.circular(14),
        topRight: const Radius.circular(14),
      ),
      white,
    );
    var x = r.left + 8;
    while (x + 14 < r.right - 4) {
      final len = 8 + rnd.nextDouble() * 18;
      final w = 12 + rnd.nextDouble() * 4;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, r.top + 6, w, len + 8),
          Radius.circular(w / 2),
        ),
        white,
      );
      x += w + 7 + rnd.nextDouble() * 4;
    }
  }

  void _candle(Canvas c, Offset top, Color color) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(top.dx - 5, top.dy, 10, 42),
      const Radius.circular(3),
    );
    c.drawRRect(body, Paint()..color = color);
    // stripes
    final stripe = Paint()..color = Colors.white.withOpacity(0.55);
    for (var k = 0; k < 4; k++) {
      c.drawRect(Rect.fromLTWH(top.dx - 5, top.dy + 6 + k * 10, 10, 3), stripe);
    }
    // wick
    c.drawRect(
      Rect.fromLTWH(top.dx - 0.8, top.dy - 5, 1.6, 6),
      Paint()..color = const Color(0xFF3B2A2A),
    );
  }

  void _flame(Canvas c, Offset top, int i, double e) {
    final base = Offset(top.dx, top.dy - 4);
    final alive = (1 - e * 3).clamp(0.0, 1.0).toDouble();

    if (alive > 0) {
      final f = flick.value;
      final sway = sin(2 * pi * (f + i * 0.2)) * 1.8;
      final hgt = 28 * (0.9 + 0.14 * sin(2 * pi * (f * 2 + i * 0.37))) * alive;
      final w = 7.0 * alive;

      // glow
      c.drawCircle(
        Offset(base.dx, base.dy - hgt * 0.45),
        26 * alive,
        Paint()
          ..shader = RadialGradient(
            colors: [kGold.withOpacity(0.38), Colors.transparent],
          ).createShader(Rect.fromCircle(
            center: Offset(base.dx, base.dy - hgt * 0.45),
            radius: 26 * alive,
          )),
      );

      _flamePath(c, base, w, hgt, sway, const Color(0xFFFFA83D));
      _flamePath(
          c, base, w * 0.55, hgt * 0.6, sway * 0.6, const Color(0xFFFFF1B8));
    }

    // smoke wisp
    if (e > 0.12 && e < 1.0) {
      final s = (e - 0.12) / 0.88;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity((1 - s) * 0.5);
      final path = Path()..moveTo(base.dx, base.dy);
      for (var k = 1; k <= 14; k++) {
        final u = k / 14;
        path.lineTo(
          base.dx + sin(u * 6 + s * 7) * 5 * u,
          base.dy - 58 * s * u,
        );
      }
      c.drawPath(path, paint);
    }
  }

  void _flamePath(
      Canvas c, Offset base, double w, double h, double sway, Color color) {
    final path = Path()..moveTo(base.dx, base.dy);
    path.cubicTo(
      base.dx - w * 1.5,
      base.dy - h * 0.35,
      base.dx - w * 0.6,
      base.dy - h * 0.75,
      base.dx + sway,
      base.dy - h,
    );
    path.cubicTo(
      base.dx + w * 0.6,
      base.dy - h * 0.75,
      base.dx + w * 1.5,
      base.dy - h * 0.35,
      base.dx,
      base.dy,
    );
    path.close();
    c.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CakePainter old) => false;
}

// ------------------------------------------------------------
// Wish cards: 3D tilt + scale on neighbours, haptic on swipe
// ------------------------------------------------------------
class WishCards extends StatefulWidget {
  const WishCards({super.key});

  @override
  State<WishCards> createState() => _WishCardsState();
}

class _WishCardsState extends State<WishCards> {
  static const _palettes = [
    [Color(0xFF7B2D8E), Color(0xFFD1497F)],
    [Color(0xFF3F2B96), Color(0xFFA8C0FF)],
    [Color(0xFFB03A6F), Color(0xFFFF9A8B)],
    [Color(0xFF1F4E8C), Color(0xFFB06AB3)],
    [Color(0xFF8E2DE2), Color(0xFFFF6FA5)],
  ];

  final _page = PageController(viewportFraction: 0.8);
  double _current = 0;

  @override
  void initState() {
    super.initState();
    _page.addListener(() => setState(() => _current = _page.page ?? 0));
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('A few wishes for you', style: script(24, color: kGold)),
        const SizedBox(height: 6),
        const Text(
          'SWIPE',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 5,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 340,
          child: PageView.builder(
            controller: _page,
            itemCount: wishes.length,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (_) => HapticFeedback.selectionClick(),
            itemBuilder: (_, i) {
              final diff = (_current - i).clamp(-1.0, 1.0).toDouble();
              final pal = _palettes[i % _palettes.length];
              return Transform(
                alignment:
                    diff > 0 ? Alignment.centerRight : Alignment.centerLeft,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateY(-diff * 0.55)
                  ..scale(1 - diff.abs() * 0.1, 1 - diff.abs() * 0.1, 1.0),
                child: Opacity(
                  opacity: 1 - diff.abs() * 0.35,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: pal,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: pal[1].withOpacity(0.35),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -6,
                          left: -2,
                          child: Text(
                            '\u201C',
                            style: TextStyle(
                              fontSize: 80,
                              height: 1,
                              color: Colors.white.withOpacity(0.22),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: Text(
                            '${i + 1} / ${wishes.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              letterSpacing: 2,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 22),
                            child: Text(
                              wishes[i],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 17,
                                height: 1.65,
                                color: Colors.white,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                        const Align(
                          alignment: Alignment.bottomCenter,
                          child: Icon(Icons.favorite,
                              size: 20, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(wishes.length, (i) {
            final active = _current.round() == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: active ? kGold : Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// Voice note: waveform player (tap or drag the waveform to seek)
// ------------------------------------------------------------
class VoiceNotePlayer extends StatefulWidget {
  const VoiceNotePlayer({super.key});

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer>
    with TickerProviderStateMixin {
  final _player = AudioPlayer();
  final List<StreamSubscription> _subs = [];

  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );
  late final AnimationController _pp = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  bool _ready = false;
  bool _error = false;
  bool _playing = false;
  Duration _pos = Duration.zero;
  Duration _total = Duration.zero;

  @override
  void initState() {
    super.initState();
    _init();
    _subs.add(_player.playerStateStream.listen((s) {
      final playing =
          s.playing && s.processingState != ProcessingState.completed;
      if (playing != _playing) {
        _playing = playing;
        if (playing) {
          _wave.repeat();
          _pp.forward();
        } else {
          _wave.stop();
          _pp.reverse();
        }
        if (mounted) setState(() {});
      }
      if (s.processingState == ProcessingState.completed) {
        _player.pause();
        _player.seek(Duration.zero);
      }
    }));
    _subs.add(_player.positionStream.listen((p) {
      if (mounted) setState(() => _pos = p);
    }));
    _subs.add(_player.durationStream.listen((d) {
      if (mounted && d != null) setState(() => _total = d);
    }));
  }

  Future<void> _init() async {
    try {
      await _player.setAsset(voiceNoteAsset);
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _wave.dispose();
    _pp.dispose();
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  void _seekTo(double dx, double width) {
    if (_total == Duration.zero) return;
    final f = (dx / width).clamp(0.0, 1.0).toDouble();
    _player.seek(Duration(milliseconds: (_total.inMilliseconds * f).round()));
  }

  void _toggle() {
    if (!_ready) return;
    HapticFeedback.lightImpact();
    _playing ? _player.pause() : _player.play();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _total.inMilliseconds == 0
        ? 0.0
        : (_pos.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        decoration: glass(radius: 28),
        child: Column(
          children: [
            Text('One more thing...', style: script(22, color: kGold)),
            const SizedBox(height: 4),
            const Text(
              'A VOICE NOTE, JUST FOR YOU',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 3,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 28),
            if (_error)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Voice note not found',
                  style: TextStyle(color: Colors.white54),
                ),
              )
            else ...[
              LayoutBuilder(
                builder: (_, box) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => _seekTo(d.localPosition.dx, box.maxWidth),
                  onHorizontalDragUpdate: (d) =>
                      _seekTo(d.localPosition.dx, box.maxWidth),
                  child: SizedBox(
                    height: 70,
                    width: double.infinity,
                    child: AnimatedBuilder(
                      animation: _wave,
                      builder: (_, __) => CustomPaint(
                        painter: _WavePainter(progress, _wave.value, _playing),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmt(_pos),
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12)),
                  Text(_fmt(_total),
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: _toggle,
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _wave,
                        builder: (_, __) {
                          if (!_playing) return const SizedBox.shrink();
                          final p = (_wave.value * 2) % 1.0;
                          return Transform.scale(
                            scale: 1 + p * 0.55,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: kPink.withOpacity((1 - p) * 0.5),
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [kPink, kRose],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: kPink.withOpacity(0.5),
                              blurRadius: 26,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedIcon(
                            icon: AnimatedIcons.play_pause,
                            progress: _pp,
                            size: 40,
                            color: kBgTop,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final double phase;
  final bool playing;
  _WavePainter(this.progress, this.phase, this.playing);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 38;
    final gap = size.width / n;
    final bw = gap * 0.56;
    for (var i = 0; i < n; i++) {
      final base = 0.26 +
          0.74 * (sin(i * 0.9).abs() * 0.6 + cos(i * 0.37 + 1).abs() * 0.4);
      final amp =
          playing ? 0.72 + 0.28 * sin(2 * pi * (phase * 2) + i * 0.6) : 1.0;
      final h = size.height * base * amp;
      final x = i * gap + gap / 2;
      final played = (i + 0.5) / n <= progress;
      final paint = Paint()
        ..color = played
            ? Color.lerp(kPink, kGold, i / n)!
            : Colors.white.withOpacity(0.25);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(x, size.height / 2), width: bw, height: h),
          Radius.circular(bw / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.progress != progress || old.phase != phase || old.playing != playing;
}
