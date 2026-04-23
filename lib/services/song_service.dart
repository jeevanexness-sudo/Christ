import 'package:cloud_firestore/cloud_firestore.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final String category; // 'telugu' | 'english' | 'hymn'
  final String mp3Url;   // Firebase Storage URL
  final String coverUrl; // optional cover image URL
  final int    durationSecs;
  final DateTime createdAt;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.category,
    required this.mp3Url,
    this.coverUrl      = '',
    this.durationSecs  = 0,
    required this.createdAt,
  });

  factory Song.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Song(
      id:           doc.id,
      title:        d['title']        ?? '',
      artist:       d['artist']       ?? '',
      category:     d['category']     ?? 'telugu',
      mp3Url:       d['mp3Url']       ?? '',
      coverUrl:     d['coverUrl']     ?? '',
      durationSecs: (d['durationSecs'] as num?)?.toInt() ?? 0,
      createdAt:    (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'title':        title,
    'artist':       artist,
    'category':     category,
    'mp3Url':       mp3Url,
    'coverUrl':     coverUrl,
    'durationSecs': durationSecs,
    'createdAt':    FieldValue.serverTimestamp(),
  };

  String get durationStr {
    final m = durationSecs ~/ 60;
    final s = durationSecs % 60;
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  Color get catColor {
    switch (category) {
      case 'telugu':  return const Color(0xFFF4A623);
      case 'english': return const Color(0xFF2B5CE6);
      case 'hymn':    return const Color(0xFF10B981);
      default:        return const Color(0xFF7C3AED);
    }
  }

  String get catLabel {
    switch (category) {
      case 'telugu':  return 'Telugu';
      case 'english': return 'English';
      case 'hymn':    return 'Hymn';
      default:        return category;
    }
  }
}

import 'package:flutter/material.dart';

class SongService {
  SongService._();
  static final instance = SongService._();
  final _col = FirebaseFirestore.instance.collection('songs');

  Stream<List<Song>> stream({String? category}) {
    Query q = _col.orderBy('createdAt', descending: true);
    if (category != null && category != 'all') {
      q = q.where('category', isEqualTo: category);
    }
    return q.snapshots().map((s) => s.docs.map(Song.fromDoc).toList());
  }

  Future<void> delete(String id) => _col.doc(id).delete();
}
