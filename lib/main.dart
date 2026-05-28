import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFFF5F0F6),
      appBar: AppBar(
        title: const Text('Welcome Back!'),
        backgroundColor: Color(0XFF84DCC6),
        foregroundColor: Color(0XFF222222),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
              'Recommended Events',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: recCards.length,
              itemBuilder: (context, index) {
                return InteractiveCard(card: recCards[index], onTap: () => {});
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              'Matches',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),        
          MatchRow(
            cards: matchCards.sublist(0, 3),
            eventLabel: 'Choir Concert - Music Society',
            onTap: (index) => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserProfileScreen(
                name: matchCards[index].title,
                university: matchCards[index].subtitle,
                course: matchCards[index].course,
                bio: matchCards[index].bio,
                event: matchCards[index].event,
              )),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 12)),
            MatchRow(
            cards: matchCards.sublist(3, 6),
            eventLabel: 'Taster Session - Improv Society',
            onTap: (index) => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserProfileScreen(
                name: matchCards[index].title,
                university: matchCards[index].subtitle,
                course: matchCards[index].course,
                bio: matchCards[index].bio,
                event: matchCards[index].event,
              )),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 12)),
        ],
      ),
      ),
      bottomNavigationBar: const AppNavigationBar(),
    );
  }
}

class  AppCard {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const  AppCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class MatchCard extends AppCard {
  final String course;
  final String bio;
  final String event;

  const MatchCard({
    required super.title,
    required super.subtitle,
    required this.course,
    required this.bio,
    required this.event,
  }) : super(icon: Icons.person, color: const Color(0XFFEEC0C6));
}

const recCards = [
   AppCard(title: 'Cookie Making', subtitle: 'Baking Society', icon: Icons.cloud, color: Color(0XFFFED766)),
   AppCard(title: 'Fight Club', subtitle: 'Boxing Society', icon: Icons.cloud, color: Color(0XFFFED766)),
   AppCard(title: 'Listening Party', subtitle: 'Alternative Music Society', icon: Icons.cloud, color: Color(0XFFFED766)),
   AppCard(title: 'Off the Hook', subtitle: 'KnitSock', icon: Icons.cloud, color: Color(0XFFFED766)),
];

const matchCards = [
   MatchCard(title: 'Jeremy', subtitle: 'KCL', course: 'History', bio: 'Just a cool dude', event: 'Choir Concert'),
   MatchCard(title: 'Emily', subtitle: 'LSE', course: 'Economics', bio: 'Everyone\'s talking about her', event: 'Pub Crawl'),
   MatchCard(title: 'Carl', subtitle: 'Imperial', course: 'Physics', bio: 'Carl Carlson', event: 'Hip Hop Dance Class'),
   MatchCard(title: 'Anne', subtitle: 'UCL', course: 'Psychology', bio: 'Of Green Gables fame', event: 'Boxing Tournament'),
   MatchCard(title: 'Geoffrey', subtitle: 'Royal Holloway', course: 'Law', bio: 'Not Jeffrey, never Jeffrey', event: 'Bumper Cars Race'),
   MatchCard(title: 'Zenaidah', subtitle: 'Queen Mary', course: 'Medicine', bio: 'The renound Zenaidah Gonzalez-Fernandes', event: 'Hiking Trip'),
];

class InteractiveCard extends StatelessWidget {
  final  AppCard card;
  final VoidCallback? onTap;

  const InteractiveCard({super.key, required this.card, required this.onTap});
    
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 140,
      child:
    Material(
      color: card.color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap ?? () => {}, // handle tap
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(card.icon, color: Color(0XFF222222), size: 32),
              const Spacer(),
              Text(
                card.title,
                style: const TextStyle(
                  color: Color(0XFF222222),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                card.subtitle,
                style: TextStyle(
                  color: Color(0XFF222222).withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    )
    );
  }
}

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Messages'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      currentIndex: 0,
      onTap: (index) {}, // handle navigation
    );
  }
}

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key, required this.name, required this.university, required this.course, required this.bio, required this.event});
  final String name;
  final String university;
  final String course;
  final String bio;
  final String event;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Color(0XFF84DCC6),
        foregroundColor: Colors.white,
      ),
      body: Padding(
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Color(0XFF8789C0),
            child: Text(
              name[0],
              style: const TextStyle(fontSize: 32, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text('$course at $university', style: const TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ],
      ),
      const SizedBox(height: 16),
      Text(bio, style: const TextStyle(fontSize: 16)),
      const SizedBox(height: 24),
      const Text('Interested in:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(event, style: const TextStyle(fontSize: 16, color: Colors.deepPurple)),
      Row( // buttons
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          label: const Text('Previous', style: TextStyle(color: Colors.black)),
        ),
        const SizedBox(width: 16),
      TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(80, 50),
          ),
          onPressed: () { },
          child: Text('X'),
        ),
        const SizedBox(width: 16),
        TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(80, 50),
          ),
          onPressed: () { },
          child: Text('✓'),
        ),
        const SizedBox(width: 16),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.arrow_forward, color: Colors.black),
          label: const Text('Next', style: TextStyle(color: Colors.black)),
        ),
      ]
      )
    ],
  ),
),
    );
  }
}

class MatchRow extends StatelessWidget {
  final List<AppCard> cards;
  final String eventLabel;
  final void Function(int index) onTap;

  const MatchRow({super.key, required this.cards, required this.eventLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 4, 16),
            child: Text(
              eventLabel,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),  
    SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          return InteractiveCard(card: cards[index], onTap: () => onTap(index));
        },
      ),
    )
      ]
    );
  }
}