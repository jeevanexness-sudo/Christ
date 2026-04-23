import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/colors.dart';
import 'core/styles.dart';
import 'screens/bible/bible_screen.dart';
import 'screens/songs/songs_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try { await Firebase.initializeApp(); } catch (_) {}
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light));
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Christ Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true, brightness: Brightness.dark,
        scaffoldBackgroundColor: C.bg,
        fontFamily: GoogleFonts.nunito().fontFamily,
        colorScheme: const ColorScheme.dark(
          primary: C.gold, onPrimary: Colors.black,
          secondary: C.blue, surface: C.surface),
        sliderTheme: SliderThemeData(
          activeTrackColor: C.gold,
          thumbColor: C.gold,
          inactiveTrackColor: C.border2,
          overlayColor: C.gold.withOpacity(0.15),
          trackHeight: 3,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: C.card2,
          contentTextStyle: GoogleFonts.nunito(color: C.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating),
      ),
      home: const _Splash(),
    );
  }
}

class _Splash extends StatefulWidget {
  const _Splash();
  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
  late final _scale = Tween(begin: 0.7, end: 1.0)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
  late final _fade = Tween(begin: 0.0, end: 1.0)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeNav(),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 350),
      ));
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: Center(child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(scale: _scale, child: Column(
          mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F2356), Color(0xFF1A3575)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: C.gold.withOpacity(0.4), width: 1.5),
              boxShadow: [BoxShadow(color: C.gold.withOpacity(0.2),
                  blurRadius: 40, offset: const Offset(0, 12))]),
            child: Stack(alignment: Alignment.center, children: [
              for (final r in [30.0, 48.0, 64.0])
                Container(width: r, height: r, decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: C.blue.withOpacity(0.2)))),
              const Icon(Icons.add_rounded, color: C.gold, size: 44),
            ]),
          ),
          const SizedBox(height: 22),
          Text('Christ',  style: T.h1.copyWith(fontSize: 32, height: 1.0)),
          Text('Connect', style: T.h1.copyWith(fontSize: 32, color: C.gold, height: 1.1)),
          const SizedBox(height: 8),
          Text('Bible  ·  Worship', style: T.cap),
          const SizedBox(height: 36),
          SizedBox(width: 120, child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              backgroundColor: C.border, minHeight: 2,
              valueColor: AlwaysStoppedAnimation<Color>(C.gold)))),
        ])),
      )),
    );
  }
}

class HomeNav extends StatefulWidget {
  const HomeNav({super.key});
  @override
  State<HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends State<HomeNav> {
  int _idx = 0;
  static const _screens = [BibleScreen(), SongsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: C.navBg,
          border: Border(top: BorderSide(color: C.border))),
        child: SafeArea(top: false, child: SizedBox(
          height: 62,
          child: Row(children: [
            _NavItem(icon: Icons.menu_book_outlined,
                activeIcon: Icons.menu_book_rounded,
                label: 'Bible', active: _idx == 0,
                onTap: () => setState(() => _idx = 0)),
            _NavItem(icon: Icons.music_note_outlined,
                activeIcon: Icons.music_note_rounded,
                label: 'Songs', active: _idx == 1,
                onTap: () => setState(() => _idx = 1)),
          ]),
        )),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String   label;
  final bool     active;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.activeIcon,
      required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? C.gold : C.muted;
    return Expanded(
      child: GestureDetector(
        onTap: onTap, behavior: HitTestBehavior.opaque,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 38, height: 26,
            decoration: BoxDecoration(
              color: active ? C.gold.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(8)),
            child: Icon(active ? activeIcon : icon, color: color, size: 20)),
          const SizedBox(height: 3),
          Text(label, style: T.over.copyWith(
              color: color, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
        ]),
      ),
    );
  }
}
