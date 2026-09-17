import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/toyverse_theme.dart';
import '../../core/widgets/floating_clouds.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/toy_button.dart';
import '../../models/user_model.dart';
import '../../providers/app_providers.dart';

class KidsPersonalizationScreen extends ConsumerStatefulWidget {
  const KidsPersonalizationScreen({super.key});

  @override
  ConsumerState<KidsPersonalizationScreen> createState() => _KidsPersonalizationScreenState();
}

class _KidsPersonalizationScreenState extends ConsumerState<KidsPersonalizationScreen> {
  final TextEditingController _nameController = TextEditingController();
  double _age = 6;
  final String _gender = 'boy';
  final List<String> _allInterests = ['STEM & Robots', 'Building Blocks', 'Puzzles', 'Soft Plush', 'Action Figures', 'Outdoor Sports', 'Drawing & Art'];
  final Set<String> _selectedInterests = {};
  final String _favoriteCharacter = 'Galactic Robot';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FloatingCloudsBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (context.canPop()) ...[
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.arrow_back_rounded, color: ToyVerseTheme.textDark),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        'Child Personalization 🎈',
                        style: AppTypography.displayMedium.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ToyVerseTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Help us tailor magical recommendations for your child!',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 14,
                    color: ToyVerseTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 24),

                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Child Name Input
                      Text('Child\'s Name', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Leo',
                          prefixIcon: const Icon(Icons.face_rounded, color: ToyVerseTheme.primaryOrange),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Age Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Age', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: ToyVerseTheme.primaryPurple,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${_age.toInt()} Years Old',
                              style: AppTypography.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _age,
                        min: 1,
                        max: 14,
                        divisions: 13,
                        activeColor: ToyVerseTheme.primaryPurple,
                        onChanged: (val) => setState(() => _age = val),
                      ),
                      const SizedBox(height: 16),

                      // Interests Chip Selection
                      Text('Favorite Toys & Interests', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _allInterests.map((interest) {
                          final isSelected = _selectedInterests.contains(interest);
                          return FilterChip(
                            selected: isSelected,
                            label: Text(interest),
                            selectedColor: ToyVerseTheme.primaryOrange.withValues(alpha: 0.2),
                            checkmarkColor: ToyVerseTheme.primaryOrange,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedInterests.add(interest);
                                } else {
                                  _selectedInterests.remove(interest);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      ToyButton(
                        text: 'Save & Unlock Magic ✨',
                        gradient: ToyVerseTheme.heroGradient,
                        onPressed: () async {
                          final child = ChildProfileModel(
                            id: 'child_${DateTime.now().millisecondsSinceEpoch}',
                            name: _nameController.text.trim().isEmpty ? 'Junior' : _nameController.text.trim(),
                            age: _age.toInt(),
                            gender: _gender,
                            interests: _selectedInterests.toList(),
                            favoriteCharacter: _favoriteCharacter,
                            learningLevel: 'Explorer',
                          );
                          await ref.read(userProvider.notifier).addChild(child);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Saved profile for ${child.name}! 🎈'),
                              backgroundColor: ToyVerseTheme.primaryMintGreen,
                            ),
                          );
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/');
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
      ),
    );
  }
}
