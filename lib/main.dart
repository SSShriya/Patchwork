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
      appBar: AppBar(
        title: const Text('Welcome Back!'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
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
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: matchCards.length,
              itemBuilder: (context, index) {
                return InteractiveCard(card: matchCards[index], onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UserProfileScreen(name: matchCards[index].title, university: matchCards[index].subtitle, course: matchCards[index].course, bio: matchCards[index].bio, event: matchCards[index].event)),
                  );
                });
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 12)),
        ],
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
  }) : super(icon: Icons.person, color: Colors.pinkAccent);
}

const recCards = [
   AppCard(title: 'Cookie Making', subtitle: 'Baking Society', icon: Icons.cloud, color: Colors.indigo),
   AppCard(title: 'Fight Club', subtitle: 'Boxing Society', icon: Icons.cloud, color: Colors.indigo),
   AppCard(title: 'Listening Party', subtitle: 'Alternative Music Society', icon: Icons.cloud, color: Colors.indigo),
   AppCard(title: 'Off the Hook', subtitle: 'KnitSock', icon: Icons.cloud, color: Colors.indigo),
];

const matchCards = [
   MatchCard(title: 'Jeremy', subtitle: 'KCL', course: 'History', bio: 'Bio', event: 'Event'),
   MatchCard(title: 'Emily', subtitle: 'LSE', course: 'Economics', bio: 'Bio', event: 'Event'),
   MatchCard(title: 'Carl', subtitle: 'Imperial', course: 'Physics', bio: 'Bio', event: 'Event'),
   MatchCard(title: 'Anne', subtitle: 'UCL', course: 'Psychology', bio: 'Bio', event: 'Event'),
   MatchCard(title: 'Geoffrey', subtitle: 'Royal Holloway', course: 'Law', bio: 'Bio', event: 'Event'),
   MatchCard(title: 'Zenaidah', subtitle: 'Queen Mary', course: 'Medicine', bio: 'Bio', event: 'Event'),
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
              Icon(card.icon, color: Colors.white, size: 32),
              const Spacer(),
              Text(
                card.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                card.subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
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
        backgroundColor: Colors.deepPurple,
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
            backgroundColor: Colors.deepPurple,
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
    ],
  ),
),
    );
  }
}