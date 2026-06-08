import 'package:drp/widgets/chat_section.dart';
import 'package:flutter/material.dart';
import '../models/match_convo.dart';
import '../services/conversation_service.dart';

class DMOverviewScreen extends StatefulWidget {
  const DMOverviewScreen({super.key});

  @override
  State<DMOverviewScreen> createState() => _DMOverviewScreenState();
}

class _DMOverviewScreenState extends State<DMOverviewScreen> {
  final _conversationService = ConversationService();
  List<ChatConversation> _conversations = [];
  bool isLoading = true;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => isLoading = true);
    final convos = await _conversationService.getConversations();
    setState(() {
      _conversations = convos;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredConversations = _conversations.where((chat) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = chat.name.toLowerCase().contains(query);
        final interestMatch = chat.interests.any((interest) => interest.toLowerCase().contains(query));

        if (!nameMatch && !interestMatch) {
          return false;
        }
      }
      return true;
    }).toList();

    final filteredNewConvos = filteredConversations
        .where((chat) => chat.numMessages <= 0)
        .toList();
    final filteredOldConvos = filteredConversations
        .where((chat) => chat.numMessages > 0)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0F6),
      appBar: AppBar(
        backgroundColor: const Color(0XFF84DCC6),
        foregroundColor: const Color(0XFF222222),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black, size: 28),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by name or interest...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  FocusScope.of(context).unfocus();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  if (filteredConversations.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(
                        child: Text(
                          'No conversations found matching criteria.',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ),
                    )
                  else ...[
                    if (filteredNewConvos.isNotEmpty)
                      ChatSection(
                        title: 'New Chats',
                        conversations: filteredNewConvos,
                        onRefresh: _loadConversations,
                      ),
                    if (filteredOldConvos.isNotEmpty)
                      ChatSection(
                        title: 'Existing Chats',
                        conversations: filteredOldConvos,
                        onRefresh: _loadConversations,
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}