import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

Future<void> updateSocDetails({required String id, String? about, String? uni}) async {
  await supabase
    .from('users')
    .update({'bio': ?about, 'university': ?uni})
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
        .from('users')
        .update({'avatar_url': publicUrl})
        .eq('id', socId);
  } on StorageException catch (e) {
    throw Exception('Failed to upload profile picture: ${e.message}');
  } catch (e) {
    throw Exception('Unexpected error during profile picture upload: $e');
  }
}

Future<Map<String, dynamic>?> getSocDetails(String societyId) async {
  final Map<String, dynamic>? row = await supabase
      .from('users')
      .select('id, name, university, bio, location') // Explicitly select only what you need
      .eq('id', societyId)
      .eq('is_society', true)
      .maybeSingle();

  if (row == null) {
    return null; 
  }

  return {
    'id': row['id'],
    'name': row['name'],
    'uni': row['university'],
    'about': row['bio'],
    'location': row['location'],
    'image_url': row['avatar_url']
  };
}