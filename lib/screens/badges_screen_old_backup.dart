import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BadgesScreen extends StatelessWidget {
  final List<BadgeData> badges;
  const BadgesScreen({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Achievements', style: GoogleFonts.notoSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: badges.isEmpty
            ? Center(
                child: Text('No badges yet', style: GoogleFonts.notoSans(fontSize: 16, color: Colors.grey)),
              )
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: 0.95,
                ),
                itemCount: badges.length,
                itemBuilder: (context, i) {
                  final badge = badges[i];
                  return _BadgeCard(badge: badge);
                },
              ),
      ),
    );
  }
}

class BadgeData {
  final String title;
  final String description;
  final String imageAsset;
  final bool achieved;
  BadgeData({required this.title, required this.description, required this.imageAsset, this.achieved = false});
}

class _BadgeCard extends StatelessWidget {
  final BadgeData badge;
  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: badge.achieved ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          if (badge.achieved)
            BoxShadow(
              color: Colors.amber.withAlpha(46),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
        border: Border.all(
          color: badge.achieved ? Colors.amber : Colors.grey.shade300,
          width: badge.achieved ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            badge.imageAsset,
            height: 56,
            width: 56,
            fit: BoxFit.contain,
            color: badge.achieved ? null : Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            badge.title,
            style: GoogleFonts.notoSans(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: badge.achieved ? Colors.black : Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            badge.description,
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: badge.achieved ? Colors.black87 : Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
