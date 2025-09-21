import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String> uploadProfilePhoto(String uid, File file) async {
    final ref = _storage.ref('user_uploads/$uid/profile.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
