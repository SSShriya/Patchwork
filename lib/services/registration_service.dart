import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class RegistrationService {
  final String currentUserId = '5f7e9d61-3865-47b2-9155-202267ee947f';

  Future<bool> hasRegistered(String eventId) async {
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