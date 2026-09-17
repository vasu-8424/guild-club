import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/supabase_service.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/toyverse_theme.dart';
import '../../core/widgets/floating_clouds.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/sparkle_badge.dart';
import '../../core/widgets/spring_widgets.dart';
import '../../providers/app_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Settings toggle states with SpringSwitch
  bool _pushNotifications = true;
  bool _personalizedRecommendations = true;
  bool _orderUpdates = true;
  bool _isUploadingAvatar = false;

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    setState(() => _isUploadingAvatar = true);
    final user = ref.read(userProvider);
    final previousAvatarUrl = user.avatarUrl;

    try {
      final bytes = await pickedFile.readAsBytes();
      final extension = pickedFile.path.split('.').last.toLowerCase();
      final validExtension = (extension == 'png' || extension == 'webp') ? extension : 'jpg';

      final newUrl = await SupabaseService.uploadAvatarImage(
        userId: user.id,
        imageBytes: bytes,
        fileExtension: validExtension,
      );

      if (newUrl != null) {
        ref.read(userProvider.notifier).updateAvatarUrl(newUrl);
        ref.invalidate(userDataProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated & synced! ✨'),
              backgroundColor: ToyVerseTheme.primaryPurple,
            ),
          );
        }
      } else {
        throw Exception('Storage upload failed');
      }
    } catch (e) {
      if (mounted) {
        ref.read(userProvider.notifier).updateAvatarUrl(previousAvatarUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not upload photo. Please verify connection.'),
            backgroundColor: ToyVerseTheme.accentCoral,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  void _showAvatarPickerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change Profile Photo 📸',
                style: AppTypography.displayMedium.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: ToyVerseTheme.primarySkyBlue,
                  child: Icon(Icons.photo_camera_rounded, color: Colors.white),
                ),
                title: Text('Take Photo via Camera', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadAvatar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: ToyVerseTheme.primaryPurple,
                  child: Icon(Icons.photo_library_rounded, color: Colors.white),
                ),
                title: Text('Choose from Photo Gallery', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadAvatar(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final user = ref.read(userProvider);
    final nameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Edit Profile Details ✏️', style: AppTypography.displayMedium.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ToyVerseTheme.primaryNavy),
            onPressed: () {
              final newName = nameController.text.trim();
              final newPhone = phoneController.text.trim();
              ref.read(userProvider.notifier).updateProfile(
                    fullName: newName.isNotEmpty ? newName : null,
                    phone: newPhone.isNotEmpty ? newPhone : null,
                  );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile details updated! ✨')),
              );
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showHelpSupportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Guild Club Customer Care 💬',
                    style: AppTypography.displayMedium.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Our parent concierge team is here 7 days a week to support you with orders, deliveries, and child developmental advisory.',
                style: AppTypography.bodySmall.copyWith(color: ToyVerseTheme.textMuted),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF25D366),
                  child: Icon(Icons.chat_rounded, color: Colors.white, size: 20),
                ),
                title: const Text('WhatsApp Concierge', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('+91 98765 43210 (Instant response)'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Connecting to Guild Club WhatsApp Concierge... 💬')),
                  );
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: ToyVerseTheme.primaryRoyalBlue,
                  child: Icon(Icons.email_outlined, color: Colors.white, size: 20),
                ),
                title: const Text('Email Support', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('support@guildclub.com'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening email draft to support@guildclub.com ✉️')),
                  );
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: ToyVerseTheme.primaryNavy,
                  child: Icon(Icons.call_outlined, color: Colors.white, size: 20),
                ),
                title: const Text('Toll-Free Helpline', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('1800-419-GUILD (9 AM - 8 PM)'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calling Guild Club Helpline... 📞')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Log Out of Guild Club?', style: AppTypography.displayMedium.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out from your parent account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ToyVerseTheme.primaryRed),
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/auth');
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final addresses = ref.watch(addressesProvider);

    return Scaffold(
      body: FloatingCloudsBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userDataProvider);
              await ref.read(userDataProvider.future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 95),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Profile Info Card
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SpringPressable(
                                  onTap: _isUploadingAvatar ? null : () => _showAvatarPickerModal(context),
                                  child: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 36,
                                        backgroundColor: ToyVerseTheme.primaryPurple.withValues(alpha: 0.12),
                                        backgroundImage: (user.avatarUrl.isNotEmpty) ? NetworkImage(user.avatarUrl) : null,
                                        child: (user.avatarUrl.isEmpty)
                                            ? Text(
                                                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'P',
                                                style: AppTypography.displayMedium.copyWith(
                                                  fontSize: 28,
                                                  color: ToyVerseTheme.primaryPurple,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : null,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: const BoxDecoration(
                                            color: ToyVerseTheme.primaryPurple,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_isUploadingAvatar)
                                  const SizedBox(
                                    width: 76,
                                    height: 76,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(ToyVerseTheme.primaryPurple),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          user.fullName.isNotEmpty ? user.fullName : 'Parent Account',
                                          style: AppTypography.displayMedium.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      SpringPressable(
                                        onTap: () => _showEditProfileDialog(context),
                                        child: const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Icon(Icons.edit_outlined, size: 16, color: ToyVerseTheme.primaryRoyalBlue),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (user.email.isNotEmpty)
                                    Text(
                                      user.email,
                                      style: AppTypography.bodyMedium.copyWith(fontSize: 13, color: ToyVerseTheme.textMuted),
                                    ),
                                  const SizedBox(height: 6),
                                  SpringPressable(
                                    onTap: () => context.push('/rewards'),
                                    child: SparkleBadge(
                                      label: '${user.rewardCoins} ToyCoins 🪙',
                                      backgroundColor: ToyVerseTheme.primaryOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'crafted for little explorers & happy parents ✨',
                            style: AppTypography.accentScript.copyWith(
                              fontSize: 16,
                              color: ToyVerseTheme.primaryPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Saved Delivery Address Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Saved Delivery Address 📍',
                          style: AppTypography.displayMedium.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SpringPressable(
                        onTap: () => context.push('/address-picker'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            addresses.isEmpty ? '+ Add Address' : 'Change / + Add',
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: ToyVerseTheme.primaryRoyalBlue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (addresses.isEmpty)
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.location_off_rounded, color: ToyVerseTheme.textMuted, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No saved delivery address. Tap + Add Address to set your location.',
                              style: AppTypography.bodyMedium.copyWith(fontSize: 13, color: ToyVerseTheme.textMuted),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SpringPressable(
                      onTap: () => context.push('/address-picker'),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: ToyVerseTheme.primaryRoyalBlue, size: 24),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 2,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        addresses.first.label,
                                        style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SparkleBadge(
                                        label: 'DEFAULT',
                                        backgroundColor: ToyVerseTheme.primaryNavy,
                                        fontSize: 8,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    addresses.first.fullAddress,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: ToyVerseTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: ToyVerseTheme.textMuted),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Children Personalization Profiles Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Children Profiles 👧👦',
                          style: AppTypography.displayMedium.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SpringPressable(
                        onTap: () => context.push('/kids-setup'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            '+ Add Child',
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: ToyVerseTheme.primaryRoyalBlue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (user.children.isEmpty)
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.child_care_rounded, color: ToyVerseTheme.textMuted, size: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No child profiles added yet. Tap + Add Child to customize recommendations by age and interests.',
                              style: AppTypography.bodyMedium.copyWith(fontSize: 13, color: ToyVerseTheme.textMuted),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    AnimationLimiter(
                      child: Column(
                        children: AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 375),
                          childAnimationBuilder: (widget) => SlideAnimation(
                            verticalOffset: 40.0,
                            child: FadeInAnimation(
                              child: widget,
                            ),
                          ),
                          children: user.children.map((child) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: SpringPressable(
                                onTap: () => context.push('/kids-setup'),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: child.gender == 'boy'
                                            ? ToyVerseTheme.primarySkyBlue
                                            : ToyVerseTheme.accentPink,
                                        child: Text(
                                          child.name.isNotEmpty ? child.name[0] : 'C',
                                          style: AppTypography.displayMedium.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              child.name,
                                              style: AppTypography.displayMedium.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Age ${child.age} Yrs • ${child.interests.join(", ")}',
                                              style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: ToyVerseTheme.textMuted),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SparkleBadge(
                                        label: child.learningLevel,
                                        backgroundColor: ToyVerseTheme.primaryPurple,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Preferences & Settings Section
                  Text(
                    'Preferences & Settings ⚙️',
                    style: AppTypography.displayMedium.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          icon: Icons.notifications_active_rounded,
                          title: 'Push Notifications 🔔',
                          value: _pushNotifications,
                          onChanged: (val) => setState(() => _pushNotifications = val),
                        ),
                        const Divider(height: 1, color: Colors.black12),
                        _buildSwitchTile(
                          icon: Icons.auto_awesome_rounded,
                          title: 'Personalized Recommendations 🎁',
                          value: _personalizedRecommendations,
                          onChanged: (val) => setState(() => _personalizedRecommendations = val),
                        ),
                        const Divider(height: 1, color: Colors.black12),
                        _buildSwitchTile(
                          icon: Icons.local_shipping_rounded,
                          title: 'Order Status Updates 📦',
                          value: _orderUpdates,
                          onChanged: (val) => setState(() => _orderUpdates = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Account Options & Quick Links
                  Text(
                    'Account Options 📋',
                    style: AppTypography.displayMedium.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  GlassCard(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        _buildSpringMenuItem(
                          context,
                          Icons.location_on_rounded,
                          'Address Book (GPS Location) 📍',
                          () => context.push('/address-picker'),
                        ),
                        _buildSpringMenuItem(
                          context,
                          Icons.favorite_rounded,
                          'My Wishlist ❤️',
                          () => context.push('/wishlist'),
                        ),
                        _buildSpringMenuItem(
                          context,
                          Icons.local_shipping_rounded,
                          'Order History 📦',
                          () => context.push('/orders'),
                        ),
                        _buildSpringMenuItem(
                          context,
                          Icons.stars_rounded,
                          'Spin Rewards & Vouchers 🎡',
                          () => context.push('/rewards'),
                        ),
                        _buildSpringMenuItem(
                          context,
                          Icons.privacy_tip_outlined,
                          'Privacy Policy 🔒',
                          () => context.push('/privacy-policy'),
                        ),
                        _buildSpringMenuItem(
                          context,
                          Icons.description_outlined,
                          'Terms of Service 📄',
                          () => context.push('/terms-of-service'),
                        ),
                        _buildSpringMenuItem(
                          context,
                          Icons.help_outline_rounded,
                          'Help & Customer Support 💬',
                          () => _showHelpSupportModal(context),
                        ),
                        _buildSpringMenuItem(
                          context,
                          Icons.logout_rounded,
                          'Log Out',
                          () => _showLogoutDialog(context),
                          isRed: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: ToyVerseTheme.primaryRoyalBlue, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600, color: ToyVerseTheme.textDark),
            ),
          ),
          SpringSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSpringMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isRed = false,
  }) {
    return SpringPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isRed ? ToyVerseTheme.accentCoral : ToyVerseTheme.primaryRoyalBlue,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isRed ? ToyVerseTheme.accentCoral : ToyVerseTheme.textDark,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isRed ? ToyVerseTheme.accentCoral : ToyVerseTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
