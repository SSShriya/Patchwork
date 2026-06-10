// import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

/// Uploads a profile picture and updates the user's avatar_url in the DB.
Future<void> uploadProfilePicture(XFile imageFile, String userId) async {
  final String filePath = '$userId/profile.jpg';

  try {
    final bytes = await imageFile.readAsBytes();

    Uint8List finalBytes;
    String contentType = 'image/jpeg';

    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      throw Exception('Unsupported image format');
    }

    // Convert everything to JPEG (you can switch to webp if preferred)
    finalBytes = Uint8List.fromList(img.encodeJpg(decoded, quality: 90));
    contentType = 'image/jpeg';

    await supabase.storage
        .from('avatars')
        .uploadBinary(
          filePath,
          finalBytes,
          fileOptions: FileOptions(upsert: true, contentType: contentType),
        );

    // final String publicUrl = supabase.storage
    //     .from('avatars')
    //     .getPublicUrl(filePath);

    final String publicUrl =
        '${supabase.storage.from('avatars').getPublicUrl(filePath)}'
        '?t=${DateTime.now().millisecondsSinceEpoch}';

    await supabase
        .from('users')
        .update({'avatar_url': publicUrl})
        .eq('id', userId);
  } on StorageException catch (e) {
    throw Exception('Failed to upload profile picture: ${e.message}');
  } catch (e) {
    throw Exception('Unexpected error during profile picture upload: $e');
  }
}

/// Updates user profile details and replaces their interests atomically.
Future<void> updateDetails(
  String userId,
  String name,
  String uni,
  String course,
  String bio,
  String year,
  String loc,
  List<String> interests,
) async {
  try {
    await supabase
        .from('users')
        .update({
          'name': name,
          'university': uni,
          'course': course,
          'bio': bio,
          'year_group': year,
          'location': loc,
        })
        .eq('id', userId);

    // Delete old interests first, then insert fresh ones
    await supabase.from('user_interests').delete().eq('user_id', userId);

    if (interests.isNotEmpty) {
      final List<Map<String, dynamic>> interestRows = interests
          .map((interest) => {'user_id': userId, 'interest': interest})
          .toList();

      await supabase.from('user_interests').insert(interestRows);
    }
  } on PostgrestException catch (e) {
    throw Exception('Failed to update profile: ${e.message}');
  } catch (e) {
    throw Exception('Unexpected error during profile update: $e');
  }
}
