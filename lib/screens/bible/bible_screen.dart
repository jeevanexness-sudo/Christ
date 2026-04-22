import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
import '../../core/styles.dart';
import '../../services/bible_api.dart';

class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});
  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────
  bool   _telugu    = false;
  BBook  _book      = BibleApi.books[49]; // Philippians
  int    _chapter   = 4;
  bool   _showBooks = false;

  BChapter? _data;
  bool      _loading = false;
  String?   _error;

  final Set<int> _hl = {};
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; _hl.clear(); });
    try {
      final d = await BibleApi.instance.fetch(
          book: _book.en, chapter: _chapter, telugu: _telugu);
      if (!mounted) return;
      setState(() { _data = d; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  void _selectBook(BBook b) {
    setState(() { _book = b; _chapter = 1; _showBooks = false; });
    _load();
  }

  void _prev() {
    if (_chapter > 1) {
      setState(() => _chapter--);
    } else {
      final i = BibleApi.books.indexOf(_book);
      if (i > 0) { setState(() { _book = BibleApi.books[i-1]; _chapter = _book.chapters; }); }
    }
    _load();
  }

  void _next() {
    if (_chapter < _book.chapters) {
      setState(() => _chapter++);
    } else {
      final i = BibleApi.books.indexOf(_book);
      if (i < BibleApi.books.length-1) { setState(() { _book = BibleApi.books[i+1]; _chapter = 1; }); }
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(child: Column(children: [
        _topBar(),
        Expanded(child: _showBooks ? _bookBrowser() : _reader()),
      ])),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────
  Widget _topBar() => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
    decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: C.border))),
    child: Row(children: [
      // Book + Chapter selector
      Expanded(child: GestureDetector(
        onTap: () => setState(() => _showBooks = !_showBooks),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Bible', style: T.h1),
            Text(
              _telugu
                  ? '${_book.te} · ${_chapter}వ అ.'
                  : '${_book.en} · Ch. $_chapter',
              style: T.cap),
          ]),
          const SizedBox(width: 6),
          Icon(_showBooks ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
              color: C.gold, size: 20),
        ]),
      )),
      // Language toggle
      _LangToggle(
        telugu: _telugu,
        onToggle: () {
          setState(() => _telugu = !_telugu);
          _load();
        },
      ),
    ]),
  );

  // ── Reader ────────────────────────────────────────────────────────────
  Widget _reader() {
    if (_loading) return const Center(child: CircularProgressIndicator(
        color: C.gold, strokeWidth: 2.5));
    if (_error != null) return _ErrorView(error: _error!, onRetry: _load);
    if (_data == null) return const SizedBox.shrink();
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _chapterHeader()),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(delegate: SliverChildBuilderDelegate(
            (_, i) {
              final v = _data!.verses[i];
              final hl = _hl.contains(v.verse);
              return _VerseRow(
                verse: v, hl: hl, telugu: _telugu,
                onTap: () => setState(() =>
                    hl ? _hl.remove(v.verse) : _hl.add(v.verse)),
                onCopy: () {
                  Clipboard.setData(ClipboardData(
                      text: '${v.text}\n— ${_book.en} ${_chapter}:${v.verse}'));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Verse copied!', style: T.body2.copyWith(color: C.white)),
                    backgroundColor: C.green, duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ));
                },
              );
            },
            childCount: _data!.verses.length,
          )),
        ),
        SliverToBoxAdapter(child: _navButtons()),
      ],
    );
  }

  Widget _chapterHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2356), Color(0xFF0A1840)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.gold.withOpacity(0.2)),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_telugu ? _book.te : _book.en, style: T.h2),
          Text(
            _telugu ? '${_chapter}వ అధ్యాయం · ${_data!.verses.length} వచనాలు'
                : 'Chapter $_chapter · ${_data!.verses.length} verses',
            style: T.cap),
        ])),
        CCBadge(text: _data!.version, color: C.gold),
      ]),
    ),
  );

  Widget _navButtons() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
    child: Row(children: [
      Expanded(child: _OutBtn(label: '← Previous', onTap: _prev)),
      const SizedBox(width: 12),
      Expanded(child: _GoldBtn(label: 'Next →', onTap: _next)),
    ]),
  );

  // ── Book Browser ──────────────────────────────────────────────────────
  Widget _bookBrowser() {
    return Column(children: [
      // Tabs OT / NT
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Container(
          decoration: BoxDecoration(
              color: C.card, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: C.border)),
          child: TabBar(
            controller: _tab,
            indicator: BoxDecoration(
                color: C.gold, borderRadius: BorderRadius.circular(10)),
            labelColor: Colors.black,
            unselectedLabelColor: C.muted,
            labelStyle: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700),
            tabs: const [Tab(text: 'Old Testament'), Tab(text: 'New Testament')],
          ),
        ),
      ),
      Expanded(child: TabBarView(
        controller: _tab,
        children: [
          _BooksGrid(books: BibleApi.ot, selected: _book, telugu: _telugu, onTap: _selectBook),
          _BooksGrid(books: BibleApi.nt, selected: _book, telugu: _telugu, onTap: _selectBook),
        ],
      )),
    ]);
  }
}

// ── Language Toggle ───────────────────────────────────────────────────────
class _LangToggle extends StatelessWidget {
  final bool        telugu;
  final VoidCallback onToggle;
  const _LangToggle({required this.telugu, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: telugu ? C.gold.withOpacity(0.15) : C.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: telugu ? C.gold : C.border2),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('EN', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700,
              color: !telugu ? C.white : C.muted)),
          Container(margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 1, height: 12, color: C.border2),
          Text('తె', style: GoogleFonts.notoSansTelugu(fontSize: 11, fontWeight: FontWeight.w700,
              color: telugu ? C.gold : C.muted)),
        ]),
      ),
    );
  }
}

// ── Verse Row ─────────────────────────────────────────────────────────────
class _VerseRow extends StatelessWidget {
  final BVerse v;
  final bool   hl;
  final bool   telugu;
  final VoidCallback onTap;
  final VoidCallback onCopy;
  const _VerseRow({required this.v, required this.hl, required this.telugu,
    required this.onTap, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onCopy,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: hl ? C.gold.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: hl ? C.gold.withOpacity(0.3) : Colors.transparent),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 28, child: Text('${v.verse}',
              style: T.over.copyWith(color: C.gold, fontSize: 10))),
          const SizedBox(width: 8),
          Expanded(child: Text(v.text,
            style: telugu
                ? GoogleFonts.notoSansTelugu(
                    fontSize: 15, color: hl ? C.gold : C.text1, height: 1.8)
                : T.body.copyWith(fontSize: 15, color: hl ? C.gold : C.text1),
          )),
          if (hl) Padding(
            padding: const EdgeInsets.only(left: 6, top: 2),
            child: Icon(Icons.bookmark_rounded, color: C.gold, size: 13)),
        ]),
      ),
    );
  }
}

// ── Books Grid ────────────────────────────────────────────────────────────
class _BooksGrid extends StatelessWidget {
  final List<BBook>                books;
  final BBook                      selected;
  final bool                       telugu;
  final void Function(BBook)       onTap;
  const _BooksGrid({required this.books, required this.selected,
    required this.telugu, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 10,
        mainAxisSpacing: 10, childAspectRatio: 2.8),
      itemCount: books.length,
      itemBuilder: (_, i) {
        final b   = books[i];
        final sel = b.en == selected.en;
        return GestureDetector(
          onTap: () => onTap(b),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? C.gold.withOpacity(0.1) : C.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: sel ? C.gold.withOpacity(0.5) : C.border,
                  width: sel ? 1.5 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(telugu ? b.te : b.en,
                    style: T.bold.copyWith(
                        color: sel ? C.gold : C.white,
                        fontSize: telugu ? 11 : 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${b.chapters} ch',
                    style: T.over.copyWith(fontSize: 9)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String       error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, color: C.muted, size: 48),
        const SizedBox(height: 14),
        Text('Could not load chapter', style: T.h3),
        const SizedBox(height: 8),
        Text(error, style: T.body2, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        _GoldBtn(label: 'Try Again', onTap: onRetry, width: 140),
      ]),
    ));
  }
}

// ── Shared Buttons ────────────────────────────────────────────────────────
class _GoldBtn extends StatelessWidget {
  final String label; final VoidCallback? onTap; final double? width;
  const _GoldBtn({required this.label, this.onTap, this.width});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: C.gold, borderRadius: BorderRadius.circular(12)),
      child: Text(label, textAlign: TextAlign.center, style: T.btn),
    ),
  );
}

class _OutBtn extends StatelessWidget {
  final String label; final VoidCallback? onTap; final double? width;
  const _OutBtn({required this.label, this.onTap, this.width});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
          color: C.card2, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: C.border2)),
      child: Text(label, textAlign: TextAlign.center, style: T.btn2),
    ),
  );
}

class CCBadge extends StatelessWidget {
  final String text; final Color color;
  const CCBadge({super.key, required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
        color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: T.over.copyWith(color: color, fontSize: 10)),
  );
}
