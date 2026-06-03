import 'package:drp/widgets/app_navigation_bar.dart';
import 'package:drp/widgets/chat_section.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  List<ChatConversation> _newConvos = [];
  List<ChatConversation> _oldConvos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final convos = await _conversationService.getConversations();
    setState(() {
      _conversations = convos;
      _newConvos = _conversations
          .where((chat) => chat.numMessages <= 0)
          .toList();
      _oldConvos = _conversations
          .where((chat) => chat.numMessages > 0)
          .toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () {
              _loadConversations();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
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

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text(
                'Chats',
                style: GoogleFonts.lora(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ChatSection(
              title: 'New Chats',
              conversations: _newConvos,
              onRefresh: _loadConversations,
            ),
            ChatSection(
              title: 'Existing Chats',
              conversations: _oldConvos,
              onRefresh: _loadConversations,
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppNavigationBar(currentIndex: 2),
    );
  }
}
