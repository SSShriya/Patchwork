  import 'dart:io';

import 'package:drp/services/conversation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> uploadProfilePicture(File imageFile, String userId) async {
    final String filePath = '$userId/profile.jpg';

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
        .eq('id', userId);
  }

  Future<void> updateDetails(String userId, String name, String uni, String course, String bio, String year, String loc, List<String> interests) async {
    await supabase.from('users').upsert({
        'id': userId,
        'name': name,
        'university': uni,
        'course': course,
        'bio': bio,
        'year_group': year,
        'location': loc,
        'created_at': DateTime.now().toIso8601String(),
      });

    if (interests.isNotEmpty) {
        final List<Map<String, dynamic>> interestRows = interests.map((interest) {
          return {
            'user_id': userId,
            'interest': interest,
          };
        }).toList();

        await supabase.from('user_interests').insert(interestRows);
      }
  }