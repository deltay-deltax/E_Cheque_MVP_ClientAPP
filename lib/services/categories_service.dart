import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String userId;
  final String name;
  final String color; // hex
  final String icon; // material icon name/code as string
  final Timestamp createdAt;

  Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.color,
    required this.icon,
    required this.createdAt,
  });

  factory Category.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data() ?? {};
    return Category(
      id: d.id,
      userId: (data['userId'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      color: (data['color'] as String?) ?? '#2563EB',
      icon: (data['icon'] as String?) ?? 'category',
      createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }
}

class CategoriesService {
  CategoriesService._();
  static final instance = CategoriesService._();
  final _db = FirebaseFirestore.instance;

  Stream<List<Category>> streamUserCategories(String uid) {
    return _db
        .collection('categories')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => Category.fromDoc(d)).toList());
  }

  Future<void> ensureDefaultCategories(String uid) async {
    final snap = await _db
        .collection('categories')
        .where('userId', isEqualTo: uid)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) return;
    final batch = _db.batch();
    final now = Timestamp.now();
    final coll = _db.collection('categories');
    final defs = [
      {'name': 'Travelling', 'color': '#2563EB', 'icon': 'flight'},
      {'name': 'Fashion', 'color': '#6653ED', 'icon': 'checkroom'},
      {'name': 'Food & Drink', 'color': '#10B981', 'icon': 'restaurant'},
      {'name': 'House', 'color': '#F59E0B', 'icon': 'home'},
    ];
    for (final c in defs) {
      final ref = coll.doc();
      batch.set(ref, {
        'userId': uid,
        'name': c['name'],
        'color': c['color'],
        'icon': c['icon'],
        'createdAt': now,
      });
    }
    await batch.commit();
  }

  Future<void> addCategory({
    required String uid,
    required String name,
    String color = '#2563EB',
    String icon = 'category',
  }) async {
    await _db.collection('categories').add({
      'userId': uid,
      'name': name,
      'color': color,
      'icon': icon,
      'createdAt': Timestamp.now(),
    });
  }
}
