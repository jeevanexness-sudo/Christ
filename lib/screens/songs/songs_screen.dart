import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
import '../../core/styles.dart';
import '../../services/song_service.dart';


// Convert Google Drive share link to direct download URL
String _convertDriveLink(String url) {
  if (url.isEmpty) return url;
  final match = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(url);
  if (match != null) {
    return 'https://drive.google.com/uc?export=download&id=${match.group(1)}';
  }
  return url;
}

// ════════════════════════════════════════════════════════════════════════════
// Songs Screen — MP3 Player
// ════════════════════════════════════════════════════════════════════════════
class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});
  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  String  _filter    = 'all';
  Song?   _playing;
  bool    _isPlaying = false;
  Duration _pos      = Duration.zero;
  Duration _dur      = Duration.zero;
  final AudioPlayer _player = AudioPlayer();

  static const _filters = [
    ('all','All'), ('telugu','తెలుగు'),
    ('english','English'), ('hymn','Hymns'),
  ];

  @override
  void initState() {
    super.initState();
    _player.onPositionChanged.listen((d) {
      if (mounted) setState(() => _pos = d);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _dur = d);
    });
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _isPlaying = s == PlayerState.playing);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _pos = Duration.zero; _isPlaying = false; });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _play(Song song) async {
    if (_playing?.id == song.id) {
      if (_isPlaying) await _player.pause();
      else            await _player.resume();
      return;
    }
    setState(() { _playing = song; _pos = Duration.zero; });
    await _player.stop();
    await _player.play(UrlSource(_convertDriveLink(song.mp3Url)));
  }

  Future<void> _seek(double v) async {
    final pos = Duration(milliseconds: (_dur.inMilliseconds * v).toInt());
    await _player.seek(pos);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2,'0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2,'0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(child: Column(children: [
        _header(),
        _filterRow(),
        Expanded(child: _songList()),
        if (_playing != null) _miniPlayer(),
      ])),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Songs', style: T.h1),
        Text('Telugu  ·  English  ·  Hymns', style: T.cap),
      ])),
    ]),
  );

  Widget _filterRow() => SizedBox(
    height: 36,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filters.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final active = _filter == _filters[i].$1;
        return GestureDetector(
          onTap: () => setState(() => _filter = _filters[i].$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              color: active ? C.gold : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: active ? C.gold : C.border2)),
            child: Text(_filters[i].$2,
              style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700,
                color: active ? Colors.black : C.muted)),
          ),
        );
      },
    ),
  );

  Widget _songList() => StreamBuilder<List<Song>>(
    stream: SongService.instance.stream(
        category: _filter == 'all' ? null : _filter),
    builder: (ctx, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(
            color: C.gold, strokeWidth: 2.5));
      }
      final songs = snap.data ?? [];
      if (songs.isEmpty) return _empty();
      return ListView.separated(
        padding: EdgeInsets.fromLTRB(16, 8, 16, _playing != null ? 100 : 24),
        physics: const BouncingScrollPhysics(),
        itemCount: songs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _SongTile(
          song:      songs[i],
          isActive:  _playing?.id == songs[i].id,
          isPlaying: _playing?.id == songs[i].id && _isPlaying,
          onTap:     () => _play(songs[i]),
          onDelete:  () => SongService.instance.delete(songs[i].id),
        ),
      );
    },
  );

  Widget _empty() => Center(child: Padding(
    padding: const EdgeInsets.all(40),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('🎵', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 14),
      Text('No songs yet', style: T.h3),
      const SizedBox(height: 8),
      Text(
        'Open Admin Panel in browser\nto upload MP3 songs',
        style: T.body2, textAlign: TextAlign.center),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: C.card, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: C.border)),
        child: Column(children: [
          Text('Admin Panel URL:', style: T.over),
          const SizedBox(height: 4),
          Text('Open admin.html in browser', style: T.gold),
        ]),
      ),
    ]),
  ));

  // ── Mini Player ────────────────────────────────────────────────────────
  Widget _miniPlayer() {
    final song     = _playing!;
    final progress = _dur.inMilliseconds > 0
        ? _pos.inMilliseconds / _dur.inMilliseconds
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color:  C.card2,
        border: const Border(top: BorderSide(color: C.border))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Progress bar
        SliderTheme(
          data: SliderThemeData(
            trackHeight:  2,
            thumbShape:   const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: C.gold,
            inactiveTrackColor: C.border2,
            thumbColor: C.gold,
            overlayColor: C.gold.withOpacity(0.2),
          ),
          child: Slider(
            value:    progress.clamp(0.0, 1.0),
            onChanged: _seek,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(children: [
            // Cover / category icon
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: song.catColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.music_note_rounded,
                  color: song.catColor, size: 22),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(song.title, style: T.bold.copyWith(fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${_fmt(_pos)} / ${_fmt(_dur)}',
                  style: T.cap),
            ])),
            // Prev
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.skip_previous_rounded, color: C.muted, size: 22)),
            // Play/Pause
            GestureDetector(
              onTap: () => _play(song),
              child: Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(color: C.gold, shape: BoxShape.circle),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.black, size: 24)),
            ),
            // Next
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.skip_next_rounded, color: C.muted, size: 22)),
          ]),
        ),
      ]),
    );
  }
}

// ── Song Tile ─────────────────────────────────────────────────────────────
class _SongTile extends StatelessWidget {
  final Song         song;
  final bool         isActive;
  final bool         isPlaying;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _SongTile({required this.song, required this.isActive,
      required this.isPlaying, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive ? C.gold.withOpacity(0.08) : C.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? C.gold.withOpacity(0.35) : C.border,
            width: isActive ? 1.5 : 1)),
        child: Row(children: [
          // Play icon
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: song.catColor.withOpacity(isActive ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(12)),
            child: Icon(
              isPlaying ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
              color: isActive ? song.catColor : C.muted, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(song.title,
                style: T.bold.copyWith(
                    color: isActive ? C.gold : C.white, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(song.artist, style: T.body2),
            const SizedBox(height: 6),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: song.catColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(song.catLabel,
                    style: T.over.copyWith(color: song.catColor))),
              if (song.durationSecs > 0) ...[
                const SizedBox(width: 8),
                Text(song.durationStr, style: T.cap),
              ],
            ]),
          ])),
          // Delete
          GestureDetector(
            onTap: () => _confirmDel(context),
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color:  C.red.withOpacity(0.08), shape: BoxShape.circle,
                border: Border.all(color: C.red.withOpacity(0.2))),
              child: const Icon(Icons.delete_outline_rounded,
                  color: C.red, size: 15)),
          ),
        ]),
      ),
    );
  }

  void _confirmDel(BuildContext ctx) {
    showDialog(context: ctx, builder: (c) => AlertDialog(
      backgroundColor: C.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Delete?', style: T.h3),
      content: Text('Delete "${song.title}"?', style: T.body2),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c),
            child: Text('Cancel', style: T.gold)),
        TextButton(onPressed: () { Navigator.pop(c); onDelete(); },
            child: Text('Delete', style: T.body2.copyWith(color: C.red))),
      ],
    ));
  }
}
