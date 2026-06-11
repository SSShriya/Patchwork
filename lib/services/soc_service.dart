import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

Future<void> updateSocDetails({
  required String id,
  String? about,
  String? uni,
}) async {
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
      .select('id, name, university, bio, location, avatar_url, can_message')
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
    'image_url': row['avatar_url'],
    'can_message': row['can_message'],
  };
}

Future<List<Map<String, dynamic>>> getCommittee(String societyId) async {
  try {
  return await supabase
      .from('committee_members')
      .select()
      .eq('society_id', societyId);
  } catch(e) {
    debugPrint('Error fetching committee data: $e');
    return [];
  }
}
