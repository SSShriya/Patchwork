import 'supabase_client.dart';

/// Submits a custom interest suggestion and increments its count.
/// Returns the updated count so the caller can react if needed.
Future<void> suggestInterest({
  required String interest,
  required String category,
}) async {
  await supabase.rpc(
    'suggest_interest',
    params: {
      'p_interest': interest.toLowerCase().trim(),
      'p_category': category.toLowerCase().trim(),
    },
  );
}

/// Fetches all promoted custom interests for a given category.
/// These are suggestions that have crossed the popularity threshold
/// and should appear as selectable chips alongside the default subcategories.
Future<List<String>> fetchPromotedInterests(String category) async {
  final response = await supabase
      .from('interest_suggestions')
      .select('interest')
      .eq('category', category.toLowerCase().trim())
      .eq('promoted', true)
      .order('interest', ascending: true);

  return (response as List).map((row) => row['interest'] as String).toList();
}

/// Fetches the suggestion count for a specific interest in a category.
/// Useful for showing "X others also added this" in the UI.
Future<int> getSuggestionCount({
  required String interest,
  required String category,
}) async {
  final response = await supabase
      .from('interest_suggestions')
      .select('count')
      .eq('interest', interest.toLowerCase().trim())
      .eq('category', category.toLowerCase().trim())
      .maybeSingle();

  return response?['count'] as int? ?? 0;
}

/// Fetches all unpromoted suggestions above a given threshold.
/// Useful for an admin screen to review and promote popular suggestions.
Future<List<Map<String, dynamic>>> fetchSuggestionsAboveThreshold({
  int threshold = 5,
}) async {
  final response = await supabase
      .from('interest_suggestions')
      .select('interest, category, count')
      .eq('promoted', false)
      .gte('count', threshold)
      .order('count', ascending: false);

  return (response as List).cast<Map<String, dynamic>>();
}
