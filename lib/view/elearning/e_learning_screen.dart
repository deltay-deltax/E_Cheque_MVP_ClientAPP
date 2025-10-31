import 'package:flutter/material.dart';
import 'package:echeque_mvp/core/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class ELearningScreen extends StatelessWidget {
  const ELearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final videos = <_Video>[
      _Video(
        title: 'How to open a bank account (Beginner Guide)',
        url: Uri.parse('https://youtu.be/VUCPnbFm1Tw'),
        thumb: 'https://img.youtube.com/vi/5hQZgQ3XkHk/hqdefault.jpg',
      ),
      _Video(
        title: 'Banking basics: Savings vs Current account',
        url: Uri.parse('https://www.youtube.com/watch?v=DX5vP1Jw4YE'),
        thumb: 'https://img.youtube.com/vi/DX5vP1Jw4YE/hqdefault.jpg',
      ),
      _Video(
        title: 'Netbanking and UPI: Getting started',
        url: Uri.parse('https://www.youtube.com/watch?v=_K1e0k2p6w8'),
        thumb: 'https://img.youtube.com/vi/_K1e0k2p6w8/hqdefault.jpg',
      ),
      _Video(
        title: 'How fixed deposits work',
        url: Uri.parse('https://www.youtube.com/watch?v=4gTjQxGQ6J4'),
        thumb: 'https://img.youtube.com/vi/4gTjQxGQ6J4/hqdefault.jpg',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'E-Learning',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      backgroundColor: AppColors.grey100,
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: videos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final v = videos[i];
          return InkWell(
            onTap: () async {
              await launchUrl(v.url, mode: LaunchMode.externalApplication);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                    child: Image.network(
                      v.thumb,
                      width: 140,
                      height: 88,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 140,
                        height: 88,
                        color: AppColors.grey200,
                        child: const Icon(
                          Icons.play_circle_fill,
                          size: 36,
                          color: AppColors.grey600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          v.url.host,
                          style: const TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.open_in_new,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Video {
  final String title;
  final Uri url;
  final String thumb;
  const _Video({required this.title, required this.url, required this.thumb});
}
