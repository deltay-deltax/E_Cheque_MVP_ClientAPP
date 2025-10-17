import 'package:flutter/material.dart';

class SendMoneyContactCard extends StatelessWidget {
  final String initials;
  final String name;
  final String phone;
  final Color avatarColor;
  final bool favorite;

  const SendMoneyContactCard({
    required this.initials,
    required this.name,
    required this.phone,
    required this.avatarColor,
    required this.favorite,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(19.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: avatarColor,
              radius: 26,
              child: Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                Text(
                  phone,
                  style: const TextStyle(
                    color: Color(0xFF818181),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            if (favorite)
              CircleAvatar(
                backgroundColor: Color(0xFFFFD4AF),
                radius: 15,
                child: Icon(Icons.favorite, color: Color(0xFFFF9900), size: 19),
              ),
          ],
        ),
      ),
    );
  }
}
