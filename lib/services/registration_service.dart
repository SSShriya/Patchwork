import 'supabase_client.dart';

class RegistrationService {
  late final String currentUserId;

  Future<bool> hasRegistered(String eventId, String currentUserId) async {
    this.currentUserId = currentUserId;

    final result = await supabase
        .from('interested_events')
        .select()
        .eq('user_id', currentUserId)
        .eq('event_id', eventId)
        .maybeSingle();

    return result != null;
  }

  Future<void> registerForEvent(String eventId) async {
    await supabase.from('interested_events').insert({
      'user_id': currentUserId,
      'event_id': eventId,
    });
  }

  Future<void> unregisterForEvent(String eventId) async {
    await supabase
        .from('interested_events')
        .delete()
        .eq('user_id', currentUserId)
        .eq('event_id', eventId);
  }
}
