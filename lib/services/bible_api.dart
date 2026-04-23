import 'dart:convert';
import 'package:http/http.dart' as http;

class BVerse {
  final int    verseNum;
  final String text;
  const BVerse(this.verseNum, this.text);
}

class BChapter {
  final String        book;
  final int           chapter;
  final String        version;
  final List<BVerse>  verses;
  const BChapter(this.book, this.chapter, this.version, this.verses);
}

class BBook {
  final int    id;
  final String en;
  final String te;
  final int    chapters;
  final bool   isNT;
  const BBook(this.id, this.en, this.te, this.chapters, this.isNT);
}

class BibleApi {
  BibleApi._();
  static final instance = BibleApi._();
  static const _timeout = Duration(seconds: 20);

  Future<BChapter> fetch({
    required String book,
    required int    chapter,
    required bool   telugu,
  }) async {
    if (telugu) return _fetchTelugu(book, chapter);
    return _fetchEnglish(book, chapter);
  }

  // ── English — bible-api.com ────────────────────────────────────────────
  Future<BChapter> _fetchEnglish(String book, int chapter) async {
    final url = 'https://bible-api.com/${Uri.encodeComponent('$book $chapter')}?translation=kjv';
    final r   = await http.get(Uri.parse(url),
        headers: {'User-Agent': 'ChristConnect/1.0 (Android)'})
        .timeout(_timeout);
    if (r.statusCode != 200) throw Exception('Network error (${r.statusCode})');
    final d = json.decode(r.body) as Map<String, dynamic>;
    if (d['error'] != null) throw Exception(d['error'].toString());
    final vs = (d['verses'] as List).map((v) {
      final vn = (v['verse'] as num).toInt();
      final vt = (v['text']  as String).trim();
      return BVerse(vn, vt);
    }).toList();
    if (vs.isEmpty) throw Exception('No verses found');
    return BChapter(book, chapter, 'KJV', vs);
  }

  // ── Telugu — getbible.net (no API key, no restrictions) ──────────────
  Future<BChapter> _fetchTelugu(String book, int chapter) async {
    final bookNum = _teluguId(book);
    if (bookNum == null) throw Exception('Book not found: $book');

    // getbible.net API — free, no auth needed
    final url = 'https://getbible.net/v2/tel/$bookNum/$chapter.json';
    try {
      final r = await http.get(Uri.parse(url),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile)',
            'Accept':     'application/json',
          }).timeout(_timeout);

      if (r.statusCode == 200) {
        final body = r.body.trim();
        if (body.isNotEmpty && body.startsWith('{')) {
          final d  = json.decode(body) as Map<String, dynamic>;
          final vs = _parseGetBible(d);
          if (vs.isNotEmpty) return BChapter(book, chapter, 'తెలుగు', vs);
        }
      }
    } catch (_) {}

    // Fallback — bolls.life
    try {
      final url2 = 'https://bolls.life/get-chapter/tel/$bookNum/$chapter/';
      final r2   = await http.get(Uri.parse(url2),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile)',
            'Accept':     'application/json',
            'Origin':     'https://bolls.life',
          }).timeout(_timeout);

      if (r2.statusCode == 200) {
        final body = r2.body.trim();
        if (body.startsWith('[')) {
          final list = json.decode(body) as List;
          if (list.isNotEmpty) {
            final vs = list.asMap().entries.map((e) {
              final v  = e.value as Map<String, dynamic>;
              final vn = (v['verse'] as num?)?.toInt() ?? (e.key + 1);
              var   vt = (v['text']  as String? ?? '').trim();
              vt = _cleanHtml(vt);
              return BVerse(vn, vt);
            }).where((v) => v.text.isNotEmpty).toList();
            if (vs.isNotEmpty) return BChapter(book, chapter, 'తెలుగు', vs);
          }
        }
      }
    } catch (_) {}

    throw Exception(
      'తెలుగు Bible లోడ్ కాలేదు.\n'
      'Internet connection check చేయండి\nలేదా కొద్దిసేపు తర్వాత try చేయండి.');
  }

  List<BVerse> _parseGetBible(Map<String, dynamic> d) {
    try {
      final verses = d['verses'] as Map<String, dynamic>?;
      if (verses == null) return [];
      return verses.entries.map((e) {
        final vn = int.tryParse(e.key) ?? 0;
        final vd = e.value as Map<String, dynamic>;
        final vt = (vd['verse'] as String? ?? '').trim();
        return BVerse(vn, vt);
      }).where((v) => v.text.isNotEmpty)
          .toList()
        ..sort((a, b) => a.verseNum.compareTo(b.verseNum));
    } catch (_) {
      return [];
    }
  }

  String _cleanHtml(String text) {
    return text
        .replaceAll('&quot;', '"').replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<').replaceAll('&gt;', '>')
        .replaceAll('&#39;', "'").replaceAll(RegExp(r'<[^>]+>'), '')
        .trim();
  }

  int? _teluguId(String book) => _ids[book];

  static const _ids = {
    'Genesis':1,'Exodus':2,'Leviticus':3,'Numbers':4,'Deuteronomy':5,
    'Joshua':6,'Judges':7,'Ruth':8,'1 Samuel':9,'2 Samuel':10,
    '1 Kings':11,'2 Kings':12,'1 Chronicles':13,'2 Chronicles':14,
    'Ezra':15,'Nehemiah':16,'Esther':17,'Job':18,'Psalms':19,
    'Proverbs':20,'Ecclesiastes':21,'Song of Solomon':22,'Isaiah':23,
    'Jeremiah':24,'Lamentations':25,'Ezekiel':26,'Daniel':27,
    'Hosea':28,'Joel':29,'Amos':30,'Obadiah':31,'Jonah':32,
    'Micah':33,'Nahum':34,'Habakkuk':35,'Zephaniah':36,'Haggai':37,
    'Zechariah':38,'Malachi':39,'Matthew':40,'Mark':41,'Luke':42,
    'John':43,'Acts':44,'Romans':45,'1 Corinthians':46,'2 Corinthians':47,
    'Galatians':48,'Ephesians':49,'Philippians':50,'Colossians':51,
    '1 Thessalonians':52,'2 Thessalonians':53,'1 Timothy':54,
    '2 Timothy':55,'Titus':56,'Philemon':57,'Hebrews':58,'James':59,
    '1 Peter':60,'2 Peter':61,'1 John':62,'2 John':63,'3 John':64,
    'Jude':65,'Revelation':66,
  };

  static const List<BBook> books = [
    BBook(1,'Genesis','ఆదికాండము',50,false),
    BBook(2,'Exodus','నిర్గమకాండము',40,false),
    BBook(3,'Leviticus','లేవీయకాండము',27,false),
    BBook(4,'Numbers','సంఖ్యాకాండము',36,false),
    BBook(5,'Deuteronomy','ద్వితీయోపదేశకాండము',34,false),
    BBook(6,'Joshua','యెహోషువ',24,false),
    BBook(7,'Judges','న్యాయాధిపతులు',21,false),
    BBook(8,'Ruth','రూతు',4,false),
    BBook(9,'1 Samuel','1 సమూయేలు',31,false),
    BBook(10,'2 Samuel','2 సమూయేలు',24,false),
    BBook(11,'1 Kings','1 రాజులు',22,false),
    BBook(12,'2 Kings','2 రాజులు',25,false),
    BBook(13,'1 Chronicles','1 దినవృత్తాంతములు',29,false),
    BBook(14,'2 Chronicles','2 దినవృత్తాంతములు',36,false),
    BBook(15,'Ezra','ఎజ్రా',10,false),
    BBook(16,'Nehemiah','నెహెమ్యా',13,false),
    BBook(17,'Esther','ఎస్తేరు',10,false),
    BBook(18,'Job','యోబు',42,false),
    BBook(19,'Psalms','కీర్తనలు',150,false),
    BBook(20,'Proverbs','సామెతలు',31,false),
    BBook(21,'Ecclesiastes','ప్రసంగి',12,false),
    BBook(22,'Song of Solomon','పరమగీతము',8,false),
    BBook(23,'Isaiah','యెషయా',66,false),
    BBook(24,'Jeremiah','యిర్మీయా',52,false),
    BBook(25,'Lamentations','విలాపవాక్యములు',5,false),
    BBook(26,'Ezekiel','యెహెఙ్కేలు',48,false),
    BBook(27,'Daniel','దానియేలు',12,false),
    BBook(28,'Hosea','హోషేయ',14,false),
    BBook(29,'Joel','యోవేలు',3,false),
    BBook(30,'Amos','ఆమోసు',9,false),
    BBook(31,'Obadiah','ఓబద్యా',1,false),
    BBook(32,'Jonah','యోనా',4,false),
    BBook(33,'Micah','మీకా',7,false),
    BBook(34,'Nahum','నహూము',3,false),
    BBook(35,'Habakkuk','హబక్కూకు',3,false),
    BBook(36,'Zephaniah','జెఫన్యా',3,false),
    BBook(37,'Haggai','హగ్గయి',2,false),
    BBook(38,'Zechariah','జెకర్యా',14,false),
    BBook(39,'Malachi','మలాకీ',4,false),
    BBook(40,'Matthew','మత్తయి',28,true),
    BBook(41,'Mark','మార్కు',16,true),
    BBook(42,'Luke','లూకా',24,true),
    BBook(43,'John','యోహాను',21,true),
    BBook(44,'Acts','అపొస్తలుల కార్యములు',28,true),
    BBook(45,'Romans','రోమీయులకు',16,true),
    BBook(46,'1 Corinthians','1 కొరింథీయులకు',16,true),
    BBook(47,'2 Corinthians','2 కొరింథీయులకు',13,true),
    BBook(48,'Galatians','గలతీయులకు',6,true),
    BBook(49,'Ephesians','ఎఫెసీయులకు',6,true),
    BBook(50,'Philippians','ఫిలిప్పీయులకు',4,true),
    BBook(51,'Colossians','కొలొస్సయులకు',4,true),
    BBook(52,'1 Thessalonians','1 థెస్సలొనీకయులకు',5,true),
    BBook(53,'2 Thessalonians','2 థెస్సలొనీకయులకు',3,true),
    BBook(54,'1 Timothy','1 తిమోతికి',6,true),
    BBook(55,'2 Timothy','2 తిమోతికి',4,true),
    BBook(56,'Titus','తీతుకు',3,true),
    BBook(57,'Philemon','ఫిలేమోనుకు',1,true),
    BBook(58,'Hebrews','హెబ్రీయులకు',13,true),
    BBook(59,'James','యాకోబు',5,true),
    BBook(60,'1 Peter','1 పేతురు',5,true),
    BBook(61,'2 Peter','2 పేతురు',3,true),
    BBook(62,'1 John','1 యోహాను',5,true),
    BBook(63,'2 John','2 యోహాను',1,true),
    BBook(64,'3 John','3 యోహాను',1,true),
    BBook(65,'Jude','యూదా',1,true),
    BBook(66,'Revelation','ప్రకటన గ్రంథము',22,true),
  ];

  static List<BBook> get ot => books.where((b) => !b.isNT).toList();
  static List<BBook> get nt => books.where((b) => b.isNT).toList();
}
