import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadFile({required String path, required String folder}) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('file_not_found');
      }
      final original = path.split(Platform.pathSeparator).last;
      final unique = '${DateTime.now().millisecondsSinceEpoch}_$original';
      final ref = _storage.ref('$folder/$unique');
      final task = await ref.putFile(file);
      final url = await task.ref.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      throw Exception('storage_error:${e.code}');
    }
  }
}

