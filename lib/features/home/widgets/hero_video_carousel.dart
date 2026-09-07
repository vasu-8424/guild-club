import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/toyverse_theme.dart';
import '../../../core/widgets/sparkle_badge.dart';
import '../../../core/widgets/spring_widgets.dart';
import '../../../core/widgets/toy_button.dart';

class HeroVideoItem {
  final String title;
  final String subtitle;
  final String badge;
  final String videoUrl;
  final String posterUrl;
  final String route;
  final String buttonText;
  final Color accentColor;

  const HeroVideoItem({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.videoUrl,
    required this.posterUrl,
    required this.route,
    required this.buttonText,
    this.accentColor = ToyVerseTheme.primaryRed,
  });
}

class HeroVideoCarousel extends StatefulWidget {
  const HeroVideoCarousel({super.key});

  @override
  State<HeroVideoCarousel> createState() => _HeroVideoCarouselState();
}

class _HeroVideoCarouselState extends State<HeroVideoCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;
  bool _isMuted = true;
  Timer? _autoScrollTimer;

  static const List<HeroVideoItem> _slides = [
    HeroVideoItem(
      title: 'Guild Club Toy Library 🎁',
      subtitle: 'Unlimited rotating access to premium STEM, Montessori & educational toys delivered home.',
      badge: 'PREMIUM TOY SUBSCRIPTION ⚡',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      posterUrl: 'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?q=80&w=1200&auto=format&fit=crop',
      route: '/categories',
      buttonText: 'Explore Toy Library →',
      accentColor: ToyVerseTheme.primaryRed,
    ),
    HeroVideoItem(
      title: 'Child Development Centers 🧠',
      subtitle: 'Verified clinics for speech therapy, occupational therapy & developmental guidance.',
      badge: 'VERIFIED THERAPY CLINICS 🌟',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      posterUrl: 'https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?q=80&w=1200&auto=format&fit=crop',
      route: '/subcategories/c1000000-0000-0000-0000-000000000002',
      buttonText: 'Find Specialists →',
      accentColor: ToyVerseTheme.primaryRoyalBlue,
    ),
    HeroVideoItem(
      title: 'Premier Play Schools 🏫',
      subtitle: 'Discover accredited early learning pre-schools & kindergarten academies for your child.',
      badge: 'EARLY EDUCATION DIRECTORY 🎓',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
      posterUrl: 'https://images.unsplash.com/photo-1580582932707-520aed937b7b?q=80&w=1200&auto=format&fit=crop',
      route: '/category-listings/c1000000-0000-0000-0000-000000000001',
      buttonText: 'Browse Schools →',
      accentColor: ToyVerseTheme.primaryNavy,
    ),
    HeroVideoItem(
      title: 'Sensory Interior Spaces 🎨',
      subtitle: 'Custom architectural drafting & sensory playroom setups designed for joyful child development.',
      badge: 'MONTESSORI & PLAY DESIGN ✨',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyBlazes.mp4',
      posterUrl: 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?q=80&w=1200&auto=format&fit=crop',
      route: '/category-listings/c1000000-0000-0000-0000-000000000004',
      buttonText: 'Design Sanctuary →',
      accentColor: ToyVerseTheme.accentGold,
    ),
  ];

  final Map<int, VideoPlayerController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initAllVideos();
    _startAutoScroll();
  }

  void _initAllVideos() {
    for (int i = 0; i < _slides.length; i++) {
      _initVideoForIndex(i);
    }
  }

  void _initVideoForIndex(int index) {
    if (_controllers.containsKey(index)) return;

    final item = _slides[index];
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(item.videoUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controllers[index] = controller;

    controller.initialize().then((_) {
      if (mounted) {
        controller.setLooping(true);
        controller.setVolume(_isMuted ? 0.0 : 1.0);
        if (_currentPage == index) {
          controller.play();
        }
        setState(() {});
      }
    }).catchError((_) {
      // Graceful fallback to poster image if network unavailable
    });
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % _slides.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);

    // Pause non-active videos and play the active video
    _controllers.forEach((idx, ctrl) {
      if (ctrl.value.isInitialized) {
        if (idx == index) {
          ctrl.play();
        } else {
          ctrl.pause();
        }
      }
    });

    // Reset auto-scroll timer after user swipe
    _startAutoScroll();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controllers.forEach((_, ctrl) {
        if (ctrl.value.isInitialized) {
          ctrl.setVolume(_isMuted ? 0.0 : 1.0);
        }
      });
    });
  }

  void _togglePlayPause(int index) {
    final ctrl = _controllers[index];
    if (ctrl != null && ctrl.value.isInitialized) {
      setState(() {
        if (ctrl.value.isPlaying) {
          ctrl.pause();
        } else {
          ctrl.play();
        }
      });
      // Restart timer
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Horizontal Landscape Sliding Video Cards
        SizedBox(
          height: 235,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _slides.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final item = _slides[index];
              final controller = _controllers[index];
              final isVideoReady = controller != null && controller.value.isInitialized;
              final isPlaying = isVideoReady && controller.value.isPlaying;

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double scale = 1.0;
                  if (_pageController.position.haveDimensions) {
                    final page = _pageController.page ?? _currentPage.toDouble();
                    scale = (1.0 - (page - index).abs() * 0.05).clamp(0.93, 1.0);
                  }
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(ToyVerseTheme.radiusHeroCard),
                    boxShadow: [
                      BoxShadow(
                        color: item.accentColor.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: ToyVerseTheme.primaryNavy.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(ToyVerseTheme.radiusHeroCard),
                    child: Stack(
                      children: [
                        // Background Poster Image (Instant visual base)
                        Positioned.fill(
                          child: CachedNetworkImage(
                            imageUrl: item.posterUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: ToyVerseTheme.primaryNavy),
                            errorWidget: (context, url, error) => Container(color: ToyVerseTheme.primaryNavy),
                          ),
                        ),

                        // Active Video Stream Player
                        if (isVideoReady)
                          Positioned.fill(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              clipBehavior: Clip.hardEdge,
                              child: SizedBox(
                                width: controller.value.size.width > 0 ? controller.value.size.width : 16,
                                height: controller.value.size.height > 0 ? controller.value.size.height : 9,
                                child: VideoPlayer(controller),
                              ),
                            ),
                          ),

                        // Rich Cinematic Gradient Scrim
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  ToyVerseTheme.primaryNavy.withValues(alpha: 0.94),
                                  ToyVerseTheme.primaryNavy.withValues(alpha: 0.5),
                                  Colors.black.withValues(alpha: 0.15),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 0.78, 1.0],
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                              ),
                            ),
                          ),
                        ),

                        // Tap Gesture Handler to Play/Pause Video
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _togglePlayPause(index),
                          ),
                        ),

                        // Central Play/Pause Indicator (Shown when paused)
                        if (isVideoReady && !isPlaying)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.2),
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                size: 28,
                                color: Colors.white,
                              ),
                            ),
                          ),

                        // Audio Mute/Unmute Action Toggle (Top-Right)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: SpringPressable(
                            onTap: _toggleMute,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                              ),
                              child: Icon(
                                _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        // Content Overlay: Badge, Title, Subtitle, CTA Button
                        Positioned(
                          bottom: 14,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SparkleBadge(
                                label: item.badge,
                                backgroundColor: item.accentColor,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.displayMedium.copyWith(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.92),
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SpringPressable(
                                onTap: () => context.push(item.route),
                                child: ToyButton.gold(
                                  text: item.buttonText,
                                  onPressed: () => context.push(item.route),
                                  width: 175,
                                  height: 36,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 50.ms).slideY(begin: 0.08, end: 0),

        const SizedBox(height: 10),

        // 2. Smooth Animated Dot Indicator
        SmoothPageIndicator(
          controller: _pageController,
          count: _slides.length,
          effect: ExpandingDotsEffect(
            dotHeight: 5.5,
            dotWidth: 5.5,
            expansionFactor: 3.2,
            spacing: 5.5,
            activeDotColor: ToyVerseTheme.primaryRed,
            dotColor: ToyVerseTheme.textLight.withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }
}
