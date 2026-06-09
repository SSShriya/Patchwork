import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

Future<void> updateSocDetails({required String id, String? about, String? uni}) async {
  await supabase
    .from('societies')
    .update({'description': ?about, 'university': ?uni})
    .eq('id', id);
}

Future<void> uploadSocImage(File imageFile, String socId) async {
  final String filePath = '$socId/profile.jpg';

  try {
    await supabase.storage
        .from('avatars')
        .upload(
          filePath,
          imageFile,
          fileOptions: const FileOptions(upsert: true),
        );

    final String publicUrl = supabase.storage
        .from('avatars')
        .getPublicUrl(filePath);

    await supabase
        .from('societies')
        .update({'image_url': publicUrl})
        .eq('id', socId);
  } on StorageException catch (e) {
    throw Exception('Failed to upload profile picture: ${e.message}');
  } catch (e) {
    throw Exception('Unexpected error during profile picture upload: $e');
  }
}