import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/toyverse_theme.dart';
import '../../core/widgets/floating_clouds.dart';
import '../../core/widgets/toy_button.dart';

class OnboardingSlide {
  final String title;
  final String description;
  final String imageUrl;
  final Color accentColor;
  final IconData icon;

  OnboardingSlide({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.accentColor,
    required this.icon,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'Curated 3D Toy Wonders',
      description: 'Discover thousands of safety-tested, award-winning toys designed to spark creativity & joy in your child.',
      imageUrl: 'https://images.unsplash.com/photo-1587654780291-39c9404d746b?q=80&w=800&auto=format&fit=crop',
      accentColor: ToyVerseTheme.primaryOrange,
      icon: Icons.auto_awesome_rounded,
    ),
    OnboardingSlide(
      title: 'AI Smart Personalization',
      description: 'Get tailored recommendations matching your child’s age, interests, and developmental learning milestones.',
      imageUrl: 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?q=80&w=800&auto=format&fit=crop',
      accentColor: ToyVerseTheme.primaryPurple,
      icon: Icons.psychology_rounded,
    ),
    OnboardingSlide(
      title: 'Instant Cashfree & Superfast Delivery',
      description: 'Enjoy 1-click UPI payments with Cashfree, gift wrapping, and live GPS map order tracking right to your doorstep.',
      imageUrl: 'https://images.unsplash.com/photo-1594787318286-3d835c1d207f?q=80&w=800&auto=format&fit=crop',
      accentColor: ToyVerseTheme.primaryRoyalBlue,
      icon: Icons.rocket_launch_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FloatingCloudsBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Guild Club',
                      style: AppTypography.displayMedium.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: ToyVerseTheme.primaryRoyalBlue,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/auth'),
                      child: Text(
                        'Skip',
                        style: AppTypography.bodyLarge.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: ToyVerseTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const _VelocityAwarePageScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 280,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: slide.accentColor.withValues(alpha: 0.25),
                                  blurRadius: 30,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: Stack(
                                children: [
                                  Image.network(
                                    slide.imageUrl,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                      .animate()
                                      .scale(begin: const Offset(0.92, 0.92), end: const Offset(1.0, 1.0), curve: Curves.easeOutCubic)
                                      .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic)
                                      .fadeIn(duration: 420.ms, curve: Curves.easeOutCubic)
                                      .then(delay: 80.ms)
                                      .saturate(begin: 0.8, end: 1.0),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          slide.accentColor.withValues(alpha: 0.42),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  )
                                      .animate()
                                      .fadeIn(duration: 280.ms, delay: 80.ms, curve: Curves.easeOutCubic),
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.white,
                                      child: Icon(slide.icon, color: slide.accentColor),
                                    )
                                        .animate()
                                        .scale(begin: const Offset(0.78, 0.78), end: const Offset(1.0, 1.0), curve: Curves.easeOutBack)
                                        .slideY(begin: -0.08, end: 0, curve: Curves.easeOutCubic)
                                        .fadeIn(duration: 260.ms, delay: 160.ms, curve: Curves.easeOutCubic),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),

                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: AppTypography.displayMedium.copyWith(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: ToyVerseTheme.textDark,
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 300.ms, delay: 180.ms, curve: Curves.easeOutCubic)
                              .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
                          const SizedBox(height: 12),

                          Text(
                            slide.description,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyLarge.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: ToyVerseTheme.textMuted,
                              height: 1.4,
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 300.ms, delay: 260.ms, curve: Curves.easeOutCubic)
                              .slideY(begin: 0.16, end: 0, curve: Curves.easeOutCubic),
                        ],
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (dotIndex) {
                        final isActive = dotIndex == _currentIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 480),
                          curve: Curves.easeOutBack,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: isActive ? 26 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: isActive ? _slides[_currentIndex].accentColor : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    ToyButton(
                      text: _currentIndex == _slides.length - 1 ? 'Get Started 🚀' : 'Continue ->',
                      gradient: LinearGradient(
                        colors: [
                          _slides[_currentIndex].accentColor,
                          _slides[_currentIndex].accentColor.withRed(240),
                        ],
                      ),
                      onPressed: () {
                        if (_currentIndex < _slides.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          context.go('/auth');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VelocityAwarePageScrollPhysics extends ScrollPhysics {
  const _VelocityAwarePageScrollPhysics({super.parent});

  @override
  _VelocityAwarePageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _VelocityAwarePageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (value < position.minScrollExtent) {
      return (value - position.minScrollExtent) * 0.18;
    }
    if (value > position.maxScrollExtent) {
      return (value - position.maxScrollExtent) * 0.18;
    }
    return 0.0;
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    final atLeadingEdge = position.pixels <= position.minScrollExtent;
    final atTrailingEdge = position.pixels >= position.maxScrollExtent;

    if ((atLeadingEdge && velocity < 0) || (atTrailingEdge && velocity > 0)) {
      final dampingRatio = 0.82;
      final stiffness = 180.0;
      final mass = 1.0;
      final dampedVelocity = velocity * 0.16;

      return SpringSimulation(
        SpringDescription(
          mass: mass,
          stiffness: stiffness,
          damping: dampingRatio,
        ),
        position.pixels,
        position.pixels,
        dampedVelocity,
      );
    }

    return super.createBallisticSimulation(position, velocity);
  }
}
