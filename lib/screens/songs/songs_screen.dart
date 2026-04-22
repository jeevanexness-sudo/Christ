import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../core/colors.dart';
import '../../core/styles.dart';
import '../../services/song_service.dart';

// ════════════════════════════════════════════════════════════════════════════
// Songs Screen
// ════════════════════════════════════════════════════════════════════════════
class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});
  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  String _filter = 'all';
  static const _filters = [
    ('all', 'All'), ('telugu', 'తెలుగు'),
    ('english', 'English'), ('hymn', 'Hymns'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      floatingActionButton: _AddFAB(),
      body: SafeArea(child: Column(children: [
        _header(context),
        _filterRow(),
        Expanded(
          child: StreamBuilder<List<Song>>(
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                physics: const BouncingScrollPhysics(),
                itemCount: songs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _SongTile(
                  song: songs[i],
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SongPlayerScreen(song: songs[i]))),
                  onDelete: () => SongService.instance.delete(songs[i].id),
                ),
              );
            },
          ),
        ),
      ])),
    );
  }

  Widget _header(BuildContext ctx) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Songs', style: T.h1),
        Text('Telugu  ·  English  ·  Hymns', style: T.cap),
      ])),
      // Seed button
      GestureDetector(
        onTap: () => _seedSamples(ctx),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: C.green.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: C.green.withOpacity(0.3))),
          child: Text('Seed', style: T.over.copyWith(color: C.green)),
        ),
      ),
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

  Widget _empty() => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🎵', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 14),
        Text('No songs yet', style: T.h3),
        const SizedBox(height: 8),
        Text('Tap "Seed" to add samples\nor tap + to add a song',
            style: T.body2, textAlign: TextAlign.center),
      ]),
    ),
  );

  Future<void> _seedSamples(BuildContext ctx) async {
    final col = FirebaseFirestore.instance.collection('songs');
    for (final s in SongService.samples) {
      await col.add(s);
    }
    if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text('Sample songs added!', style: T.body2),
      backgroundColor: C.green, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Song Tile
// ════════════════════════════════════════════════════════════════════════════
class _SongTile extends StatelessWidget {
  final Song         song;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _SongTile({required this.song, required this.onTap, required this.onDelete});

  Color get _catColor {
    switch (song.category) {
      case 'telugu':  return C.gold;
      case 'english': return C.blue;
      case 'hymn':    return C.green;
      default:        return C.violet;
    }
  }

  String get _catLabel {
    switch (song.category) {
      case 'telugu':  return 'Telugu';
      case 'english': return 'English';
      case 'hymn':    return 'Hymn';
      default:        return song.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: C.card, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.border)),
        child: Row(children: [
          // Thumbnail
          Container(
            width: 58, height: 58,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: C.border2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: song.youtubeId.isNotEmpty
                ? Image.network(
                    'https://img.youtube.com/vi/${song.youtubeId}/mqdefault.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.music_note_rounded, color: C.muted, size: 24))
                : const Icon(Icons.music_note_rounded, color: C.muted, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(song.title, style: T.bold.copyWith(fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(song.artist, style: T.body2),
            const SizedBox(height: 6),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _catColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
                child: Text(_catLabel, style: T.over.copyWith(color: _catColor)),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.smart_display_rounded,
                  color: C.youtube, size: 14),
              const SizedBox(width: 4),
              Text('YouTube', style: T.over.copyWith(color: C.muted)),
            ]),
          ])),
          // Delete
          GestureDetector(
            onTap: () => _confirmDelete(context),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: C.red.withOpacity(0.08), shape: BoxShape.circle,
                border: Border.all(color: C.red.withOpacity(0.2))),
              child: const Icon(Icons.delete_outline_rounded, color: C.red, size: 16)),
          ),
        ]),
      ),
    );
  }

  void _confirmDelete(BuildContext ctx) {
    showDialog(context: ctx, builder: (c) => AlertDialog(
      backgroundColor: C.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Delete song?', style: T.h3),
      content: Text('This cannot be undone.', style: T.body2),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c),
            child: Text('Cancel', style: T.gold)),
        TextButton(onPressed: () { Navigator.pop(c); onDelete(); },
            child: Text('Delete', style: T.body2.copyWith(color: C.red))),
      ],
    ));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Song Player Screen — YouTube in-app
// ════════════════════════════════════════════════════════════════════════════
class SongPlayerScreen extends StatefulWidget {
  final Song song;
  const SongPlayerScreen({super.key, required this.song});
  @override
  State<SongPlayerScreen> createState() => _SongPlayerScreenState();
}

class _SongPlayerScreenState extends State<SongPlayerScreen> {
  YoutubePlayerController? _ctrl;
  bool _hasVideo = false;

  @override
  void initState() {
    super.initState();
    final id = widget.song.youtubeId;
    if (id.isNotEmpty) {
      _ctrl = YoutubePlayerController(
        initialVideoId: id,
        flags: const YoutubePlayerFlags(
          autoPlay:      true,
          mute:          false,
          loop:          false,
          enableCaption: true,
        ),
      );
      setState(() => _hasVideo = true);
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasVideo) {
      return Scaffold(
        backgroundColor: C.bg,
        appBar: AppBar(backgroundColor: C.bg, title: Text(widget.song.title, style: T.h3)),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.link_off_rounded, color: C.muted, size: 52),
          const SizedBox(height: 12),
          Text('No YouTube link', style: T.h3),
          const SizedBox(height: 6),
          Text('Edit this song to add a YouTube URL', style: T.body2),
        ])),
      );
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _ctrl!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.orange,
        progressColors: const ProgressBarColors(
          playedColor: Colors.orange,
          handleColor: Colors.orangeAccent,
        ),
        onReady: () {},
      ),
      builder: (ctx, player) => Scaffold(
        backgroundColor: C.bg,
        body: SafeArea(child: Column(children: [
          // Back + title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              GestureDetector(
                onTap: () { _ctrl?.pause(); Navigator.pop(context); },
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: C.card, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: C.border2)),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: C.white, size: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.song.title, style: T.h3,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(widget.song.artist, style: T.cap),
              ])),
            ]),
          ),
          // YouTube player
          player,
          // Info
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 8),
              Text(widget.song.title, style: T.h2),
              const SizedBox(height: 4),
              Text(widget.song.artist, style: T.body2),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: C.card, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: C.border)),
                child: Column(children: [
                  Row(children: [
                    const Icon(Icons.info_outline_rounded, color: C.muted, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'Playing via YouTube. For best experience, '
                      'use headphones while singing along!',
                      style: T.body2.copyWith(height: 1.5))),
                  ]),
                ]),
              ),
            ]),
          )),
        ])),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Add Song FAB
// ════════════════════════════════════════════════════════════════════════════
class _AddFAB extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context, isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _AddSheet()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          gradient: C.blueGrad, borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: C.blue.withOpacity(0.35),
              blurRadius: 16, offset: const Offset(0, 4))]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.add_rounded, color: C.white, size: 20),
          const SizedBox(width: 6),
          Text('Add Song', style: T.btn2.copyWith(fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Add Song Sheet — paste YouTube URL, preview, save
// ════════════════════════════════════════════════════════════════════════════
class _AddSheet extends StatefulWidget {
  const _AddSheet();
  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final _titleCtrl = TextEditingController();
  final _artistCtrl = TextEditingController();
  final _ytCtrl = TextEditingController();
  String   _cat     = 'telugu';
  String?  _ytId;
  bool     _saving  = false;
  String?  _error;

  @override
  void dispose() {
    _titleCtrl.dispose(); _artistCtrl.dispose(); _ytCtrl.dispose();
    super.dispose();
  }

  void _parseYT() {
    final id = Song.extractYoutubeId(_ytCtrl.text.trim());
    setState(() => _ytId = id.isNotEmpty ? id : null);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter song title'); return;
    }
    if (_ytId == null) {
      setState(() => _error = 'Enter a valid YouTube URL'); return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await SongService.instance.add(Song(
        id: '', title: _titleCtrl.text.trim(),
        artist: _artistCtrl.text.trim().isEmpty
            ? 'Unknown' : _artistCtrl.text.trim(),
        youtubeUrl: _ytCtrl.text.trim(),
        youtubeId: _ytId!,
        category: _cat,
      ));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Song added!', style: T.body2),
          backgroundColor: C.green, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      setState(() { _error = 'Failed: $e'; _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bot),
      decoration: BoxDecoration(
        color: C.surface, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: C.border2)),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: C.muted,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Add Song', style: T.h3),
          const SizedBox(height: 18),

          // Category
          Text('CATEGORY', style: T.over),
          const SizedBox(height: 8),
          Row(children: [
            ('telugu','తెలుగు'),('english','English'),('hymn','Hymn'),
          ].map((c) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: c.$1 != 'hymn' ? 8 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _cat = c.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _cat == c.$1 ? C.gold.withOpacity(0.12) : C.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _cat == c.$1 ? C.gold : C.border,
                        width: _cat == c.$1 ? 1.5 : 1)),
                  child: Text(c.$2, textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700,
                      color: _cat == c.$1 ? C.gold : C.muted)),
                ),
              ),
            ),
          )).toList()),
          const SizedBox(height: 14),

          // YouTube URL — main field
          Text('YOUTUBE URL *', style: T.over),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: TextField(
              controller: _ytCtrl,
              style: GoogleFonts.nunito(color: C.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true, fillColor: C.card,
                hintText: 'https://youtube.com/watch?v=...',
                hintStyle: GoogleFonts.nunito(color: C.muted, fontSize: 12),
                prefixIcon: const Icon(Icons.smart_display_rounded,
                    color: C.youtube, size: 18),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: C.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: C.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: C.gold, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
              onChanged: (_) => _parseYT(),
            )),
          ]),

          // YouTube thumbnail preview
          if (_ytId != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                'https://img.youtube.com/vi/$_ytId/mqdefault.jpg',
                height: 90, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 60, color: C.card,
                  child: const Center(child: Icon(Icons.music_note_rounded,
                      color: C.muted)))),
            ),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.check_circle_rounded, color: C.green, size: 14),
              const SizedBox(width: 5),
              Text('YouTube URL valid ✓', style: T.over.copyWith(color: C.green)),
            ]),
          ],
          const SizedBox(height: 12),

          // Title
          Text('SONG TITLE *', style: T.over),
          const SizedBox(height: 6),
          _field(_titleCtrl, 'Song name...'),
          const SizedBox(height: 12),

          // Artist
          Text('ARTIST', style: T.over),
          const SizedBox(height: 6),
          _field(_artistCtrl, 'Artist name...'),

          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: T.cap.copyWith(color: C.red)),
          ],
          const SizedBox(height: 16),

          // Save button
          GestureDetector(
            onTap: _saving ? null : _save,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                  color: C.gold, borderRadius: BorderRadius.circular(14)),
              child: _saving
                  ? const Center(child: SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2.5)))
                  : Text('Save Song', textAlign: TextAlign.center, style: T.btn),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint) => TextField(
    controller: ctrl,
    style: GoogleFonts.nunito(color: C.white, fontSize: 14),
    decoration: InputDecoration(
      filled: true, fillColor: C.card,
      hintText: hint,
      hintStyle: GoogleFonts.nunito(color: C.muted, fontSize: 13),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: C.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: C.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: C.gold, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );
}
