import 'package:cloud_firestore/cloud_firestore.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final String youtubeUrl;
  final String youtubeId;
  final String category; // 'telugu' | 'english' | 'hymn'

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.youtubeUrl,
    required this.youtubeId,
    required this.category,
  });

  factory Song.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final url = d['youtubeUrl'] as String? ?? '';
    return Song(
      id:         doc.id,
      title:      d['title']    ?? '',
      artist:     d['artist']   ?? '',
      youtubeUrl: url,
      youtubeId:  d['youtubeId'] ?? _extractId(url),
      category:   d['category'] ?? 'telugu',
    );
  }

  Map<String, dynamic> toMap() => {
    'title':      title,
    'artist':     artist,
    'youtubeUrl': youtubeUrl,
    'youtubeId':  youtubeId,
    'category':   category,
    'createdAt':  FieldValue.serverTimestamp(),
  };

  static String _extractId(String url) {
    if (url.isEmpty) return '';
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
    }
    return uri.queryParameters['v'] ?? '';
  }

  // Public helper for other classes
  static String extractYoutubeId(String url) => _extractId(url);
}

class SongService {
  SongService._();
  static final instance = SongService._();
  final _col = FirebaseFirestore.instance.collection('songs');

  // ── Stream all songs ───────────────────────────────────────────────
  Stream<List<Song>> stream({String? category}) {
    Query q = _col.orderBy('createdAt', descending: true);
    if (category != null && category != 'all') {
      q = q.where('category', isEqualTo: category);
    }
    return q.snapshots().map((s) => s.docs.map(Song.fromDoc).toList());
  }

  // ── Add song ───────────────────────────────────────────────────────
  Future<void> add(Song song) => _col.add(song.toMap());

  // ── Delete song ────────────────────────────────────────────────────
  Future<void> delete(String id) => _col.doc(id).delete();

  // ── Update song ────────────────────────────────────────────────────
  Future<void> update(String id, Map<String, dynamic> data) =>
      _col.doc(id).update(data);

  // ── Sample seed data ───────────────────────────────────────────────
  static final List<Map<String, dynamic>> samples = [
    {
      'title': 'Way Maker', 'artist': 'Sinach', 'category': 'english',
      'youtubeUrl': 'https://www.youtube.com/watch?v=iKTMBMmcaKU',
      'youtubeId': 'iKTMBMmcaKU',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'title': 'Oceans', 'artist': 'Hillsong United', 'category': 'english',
      'youtubeUrl': 'https://www.youtube.com/watch?v=dy9nwe9_xzw',
      'youtubeId': 'dy9nwe9_xzw',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'title': 'Amazing Grace', 'artist': 'Traditional', 'category': 'hymn',
      'youtubeUrl': 'https://www.youtube.com/watch?v=CDdvReNKKuk',
      'youtubeId': 'CDdvReNKKuk',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'title': 'యేసయ్య నా జీవితం', 'artist': 'Telugu Worship', 'category': 'telugu',
      'youtubeUrl': 'https://www.youtube.com/watch?v=KhZagHbRv7E',
      'youtubeId': 'KhZagHbRv7E',
      'createdAt': FieldValue.serverTimestamp(),
    },
  ];
}
