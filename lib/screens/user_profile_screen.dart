import 'package:drp/tools/scalloped_clipper.dart';
import 'package:flutter/material.dart';
import '../models/match_card.dart';
import '../widgets/user_profile_card.dart';


class UserProfileScreen extends StatelessWidget {
  final MatchCard card;
  final bool accepted;

  const UserProfileScreen({
    super.key,
    required this.card,
    this.accepted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F0F6),
      ),
      child: Stack(
        children: [
          // ── Solid base colour ──────────────────────────────────────
          const Positioned.fill(child: ColoredBox(color: Color(0xFFF5F0F6))),

          // ── Background texture ─────────────────────────────────────
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/textures/bg_texture.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      const Color(0xFFF5F0F6).withValues(alpha: 0.4),
                      BlendMode.multiply,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Main content ───────────────────────────────────────────
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight + 10),
              child: ClipPath(
                clipper: ScallopedClipper(),
                child: AppBar(
                  foregroundColor: const Color(0xFF222222),
                  elevation: 0,

                  flexibleSpace: Opacity(
                    opacity: 0.6,
                    child: Image(
                      image: AssetImage('assets/images/pink_gingham.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  centerTitle: true,
                ),
              ),
            ),
            body: UserProfileCard(card: card, accepted: accepted),
          ),
        ],
      ),
    );
  }
}
