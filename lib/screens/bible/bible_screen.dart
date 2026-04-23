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
  bool      _telugu   = false;
  BBook     _book     = BibleApi.books[49]; // Philippians
  int       _chapter  = 4;
  bool      _showBooks = false;

  BChapter? _data;
  bool      _loading  = false;
  String?   _error;
  final Set<int> _hl  = {};

  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; _hl.clear(); });
    try {
      final d = await BibleApi.instance.fetch(
          book: _book.en, chapter: _chapter, telugu: _telugu);
      if (!mounted) return;
      setState(() { _data = d; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error   = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _pick(BBook b) {
    setState(() { _book = b; _chapter = 1; _showBooks = false; });
    _load();
  }

  void _prev() {
    if (_chapter > 1) { setState(() => _chapter--); }
    else {
      final i = BibleApi.books.indexOf(_book);
      if (i > 0) setState(() { _book = BibleApi.books[i-1]; _chapter = _book.chapters; });
    }
    _load();
  }

  void _next() {
    if (_chapter < _book.chapters) { setState(() => _chapter++); }
    else {
      final i = BibleApi.books.indexOf(_book);
      if (i < BibleApi.books.length-1) setState(() { _book = BibleApi.books[i+1]; _chapter = 1; });
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(child: Column(children: [
        _topBar(),
        Expanded(child: _showBooks ? _browser() : _reader()),
      ])),
    );
  }

  Widget _topBar() => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
    decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: C.border))),
    child: Row(children: [
      Expanded(child: GestureDetector(
        onTap: () => setState(() => _showBooks = !_showBooks),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Bible', style: T.h1),
            Text(
              _telugu
                  ? '${_book.te} · ${_chapter}వ అధ్యాయం'
                  : '${_book.en} · Chapter $_chapter',
              style: T.cap),
          ])),
          Icon(_showBooks ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: C.gold, size: 22),
        ]),
      )),
      const SizedBox(width: 12),
      _LangToggle(telugu: _telugu, onTap: () {
        setState(() => _telugu = !_telugu); _load();
      }),
    ]),
  );

  Widget _reader() {
    if (_loading) return const Center(child: CircularProgressIndicator(
        color: C.gold, strokeWidth: 2.5));
    if (_error != null) return _ErrView(msg: _error!, onRetry: _load);
    if (_data == null) return const SizedBox.shrink();
    return CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
      SliverToBoxAdapter(child: _chapHead()),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(delegate: SliverChildBuilderDelegate(
          (_, i) {
            final v  = _data!.verses[i];
            final hl = _hl.contains(v.verseNum);
            return _VRow(
              vNum:    v.verseNum,
              text:    v.text,
              hl:      hl,
              telugu:  _telugu,
              onTap: () => setState(() =>
                  hl ? _hl.remove(v.verseNum) : _hl.add(v.verseNum)),
              onLong: () {
                Clipboard.setData(ClipboardData(
                    text: '${v.text}\n— ${_book.en} ${_chapter}:${v.verseNum}'));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Verse copied!', style: T.body2),
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
      SliverToBoxAdapter(child: _navBtns()),
    ]);
  }

  Widget _chapHead() => Padding(
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
            _telugu
                ? '${_chapter}వ అధ్యాయం · ${_data!.verses.length} వచనాలు'
                : 'Chapter $_chapter · ${_data!.verses.length} verses',
            style: T.cap),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: C.gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: C.gold.withOpacity(0.3))),
          child: Text(_data!.version,
              style: T.over.copyWith(color: C.gold, fontSize: 11)),
        ),
      ]),
    ),
  );

  Widget _navBtns() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
    child: Row(children: [
      Expanded(child: _OutBtn(label: '← Previous', onTap: _prev)),
      const SizedBox(width: 12),
      Expanded(child: _GoldBtn(label: 'Next →', onTap: _next)),
    ]),
  );

  Widget _browser() => Column(children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(color: C.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: C.border)),
        child: TabBar(
          controller: _tab,
          indicator: BoxDecoration(color: C.gold, borderRadius: BorderRadius.circular(10)),
          labelColor: Colors.black, unselectedLabelColor: C.muted,
          labelStyle: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700),
          tabs: const [Tab(text: 'Old Testament (39)'), Tab(text: 'New Testament (27)')],
        ),
      ),
    ),
    Expanded(child: TabBarView(controller: _tab, children: [
      _Grid(books: BibleApi.ot, selected: _book, telugu: _telugu, onTap: _pick),
      _Grid(books: BibleApi.nt, selected: _book, telugu: _telugu, onTap: _pick),
    ])),
  ]);
}

// ── Language Toggle ───────────────────────────────────────────────────────
class _LangToggle extends StatelessWidget {
  final bool telugu; final VoidCallback onTap;
  const _LangToggle({required this.telugu, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: telugu ? C.gold.withOpacity(0.15) : C.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: telugu ? C.gold : C.border2)),
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
class _VRow extends StatelessWidget {
  final int    vNum;
  final String text;
  final bool   hl;
  final bool   telugu;
  final VoidCallback onTap;
  final VoidCallback onLong;
  const _VRow({required this.vNum, required this.text, required this.hl,
      required this.telugu, required this.onTap, required this.onLong});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, onLongPress: onLong,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: hl ? C.gold.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: hl ? C.gold.withOpacity(0.3) : Colors.transparent)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 28, child: Text('$vNum',
              style: T.over.copyWith(color: C.gold, fontSize: 11))),
          const SizedBox(width: 8),
          Expanded(child: Text(text,
            style: telugu
                ? GoogleFonts.notoSansTelugu(
                    fontSize: 15, color: hl ? C.gold : C.text1, height: 1.8)
                : T.body.copyWith(fontSize: 15, color: hl ? C.gold : C.text1))),
          if (hl) const Padding(
            padding: EdgeInsets.only(left: 6, top: 2),
            child: Icon(Icons.bookmark_rounded, color: C.gold, size: 13)),
        ]),
      ),
    );
  }
}

// ── Books Grid ────────────────────────────────────────────────────────────
class _Grid extends StatelessWidget {
  final List<BBook>            books;
  final BBook                  selected;
  final bool                   telugu;
  final void Function(BBook)   onTap;
  const _Grid({required this.books, required this.selected,
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
                  width: sel ? 1.5 : 1)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment:  MainAxisAlignment.center,
              children: [
                Text(telugu ? b.te : b.en,
                    style: T.bold.copyWith(
                        color: sel ? C.gold : C.white,
                        fontSize: telugu ? 11 : 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${b.chapters} ch', style: T.over.copyWith(fontSize: 9)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────
class _ErrView extends StatelessWidget {
  final String msg; final VoidCallback onRetry;
  const _ErrView({required this.msg, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.wifi_off_rounded, color: C.muted, size: 48),
      const SizedBox(height: 14),
      Text('Could not load', style: T.h3),
      const SizedBox(height: 8),
      Text(msg, style: T.body2, textAlign: TextAlign.center),
      const SizedBox(height: 20),
      _GoldBtn(label: 'Try Again', onTap: onRetry, width: 130),
    ]),
  ));
}

// ── Buttons ───────────────────────────────────────────────────────────────
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
      decoration: BoxDecoration(color: C.card2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: C.border2)),
      child: Text(label, textAlign: TextAlign.center, style: T.btn2),
    ),
  );
}
