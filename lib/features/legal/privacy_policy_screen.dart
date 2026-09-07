import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/toyverse_theme.dart';
import '../../core/widgets/floating_clouds.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/sparkle_badge.dart';
import '../../core/widgets/spring_widgets.dart';

/// DRAFT PRIVACY POLICY FOR GUILD CLUB (TOYVERSE)
///
/// NOTE FOR DEVELOPERS & LEGAL COMPLIANCE:
/// This document is a structured DRAFT generated specifically for Guild Club based on
/// the actual data pipelines utilized by this application (Supabase, Razorpay, Google Sign-In,
/// GPS geocoding, and children's personalization profiles).
///
/// IMPORTANT LEGAL NOTICE:
/// Collecting and processing children's data has strict regulatory requirements under
/// applicable laws, including India's Digital Personal Data Protection Act, 2023 (DPDP Act),
/// GDPR-K, and COPPA where applicable. This draft MUST be formally reviewed and approved
/// by qualified legal counsel prior to production public deployment.
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  final ScrollController _scrollController = ScrollController();

  final List<GlobalKey> _sectionKeys = List.generate(8, (_) => GlobalKey());

  void _scrollToSection(int index) {
    final keyContext = _sectionKeys[index].currentContext;
    if (keyContext != null) {
      Scrollable.ensureVisible(
        keyContext,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ToyVerseTheme.bgWarmWhite,
      body: FloatingCloudsBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 1. Frosted Glass Top Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ToyVerseTheme.radiusNavigation),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(ToyVerseTheme.radiusNavigation),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: ToyVerseTheme.primaryNavy.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          SpringPressable(
                            onTap: () => context.pop(),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: ToyVerseTheme.bgLightGray,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Icon(Icons.arrow_back_ios_new_rounded, color: ToyVerseTheme.textDark, size: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Privacy Policy',
                                  style: AppTypography.displayMedium.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: ToyVerseTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Last Updated: August 2026',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: ToyVerseTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SparkleBadge(
                            label: 'LEGAL DRAFT',
                            backgroundColor: ToyVerseTheme.primaryNavy,
                            fontSize: 8.5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Scrollable Policy Content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overview Banner
                      GlassCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: ToyVerseTheme.primaryRoyalBlue.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.shield_rounded, color: ToyVerseTheme.primaryRoyalBlue, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Our Commitment to Child & Family Privacy',
                                    style: AppTypography.displayMedium.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: ToyVerseTheme.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Guild Club is dedicated to creating safe, enriching learning and play experiences. We believe privacy is a fundamental right, especially when children are involved. This Privacy Policy details how we collect, handle, and protect your information.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: ToyVerseTheme.textDark,
                                height: 1.5,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Quick Jump Table of Contents
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Table of Contents',
                              style: AppTypography.displayMedium.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: ToyVerseTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildTocChip(0, '1. Data We Collect'),
                                _buildTocChip(1, '2. Children’s Privacy'),
                                _buildTocChip(2, '3. How We Use Data'),
                                _buildTocChip(3, '4. Third-Party Services'),
                                _buildTocChip(4, '5. Location & GPS'),
                                _buildTocChip(5, '6. Security & Retention'),
                                _buildTocChip(6, '7. Your Rights'),
                                _buildTocChip(7, '8. Contact & Grievance'),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Section 1: Information We Collect
                      _buildSectionCard(
                        key: _sectionKeys[0],
                        sectionNumber: '1',
                        title: 'Information We Collect',
                        icon: Icons.inventory_2_outlined,
                        content: [
                          _buildBullet(
                            'Parent / Guardian Account Data:',
                            'When you register, we collect your name, email address, phone number, and authentication credentials (including OAuth tokens via Google Sign-In).',
                          ),
                          _buildBullet(
                            'Child Profile Information (Optional):',
                            'Parents may provide their child’s nickname/first name, age bracket, and educational interests to personalize toy curation and developmental recommendations.',
                          ),
                          _buildBullet(
                            'Delivery & Location Details:',
                            'Saved delivery addresses, city, state, postal code, and precise latitude/longitude coordinates (with your explicit device permission) for delivery routing.',
                          ),
                          _buildBullet(
                            'Order & Transaction Records:',
                            'Items purchased, rental history, payment confirmation identifiers (via Razorpay), invoice details, and order lifecycle timestamps.',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Section 2: Children's Data Protection
                      _buildSectionCard(
                        key: _sectionKeys[1],
                        sectionNumber: '2',
                        title: 'Children’s Data Protection & Parental Control',
                        icon: Icons.child_care_rounded,
                        accentColor: ToyVerseTheme.primaryRed,
                        content: [
                          _buildBullet(
                            'Strict Parental Consent:',
                            'Guild Club accounts may only be created and managed by adults (parents or legal guardians). We do not knowingly collect personal information directly from children under 18 without verified parental consent.',
                          ),
                          _buildBullet(
                            'DPDP Act (India) Compliance:',
                            'In alignment with the Digital Personal Data Protection Act, 2023, children’s profiles are strictly utilized for educational personalization and recommendation heuristics. We do not engage in targeted behavioral advertising to children.',
                          ),
                          _buildBullet(
                            'Immediate Right of Erasure:',
                            'Parents retain total control to modify, update, or permanently delete their child’s profile at any time directly through the Profile screen.',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Section 3: How We Use Your Information
                      _buildSectionCard(
                        key: _sectionKeys[2],
                        sectionNumber: '3',
                        title: 'How We Use Your Information',
                        icon: Icons.settings_suggest_outlined,
                        content: [
                          _buildBullet(
                            'Order Fulfillment & Delivery:',
                            'To pack, dispatch, and coordinate the delivery of educational toys, kits, and supplies to your designated address.',
                          ),
                          _buildBullet(
                            'Realtime Order Tracking:',
                            'To provide live milestone updates and delivery status via Supabase Realtime subscriptions.',
                          ),
                          _buildBullet(
                            'Guild Coins & Rewards Ledger:',
                            'To compute, track, and credit reward points earned through purchases and daily engagement.',
                          ),
                          _buildBullet(
                            'Customer Concierge Support:',
                            'To assist you with inquiries, replacement requests, developmental advisory, and account management.',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Section 4: Third-Party Service Providers
                      _buildSectionCard(
                        key: _sectionKeys[3],
                        sectionNumber: '4',
                        title: 'Third-Party Services & Integrations',
                        icon: Icons.hub_outlined,
                        content: [
                          _buildBullet(
                            'Supabase (Backend Infrastructure):',
                            'Our database, authentication, real-time subscription engine, and encrypted asset storage are hosted securely on Supabase with Row Level Security (RLS).',
                          ),
                          _buildBullet(
                            'Razorpay (Payment Gateway):',
                            'Payments are securely processed by Razorpay. Guild Club never stores raw credit card numbers or UPI PINs on our servers. Razorpay complies with PCI-DSS Level 1 standards.',
                          ),
                          _buildBullet(
                            'Google Sign-In (OAuth):',
                            'Used solely for secure, seamless parent authentication. We only receive your verified email and public profile name.',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Section 5: Location & GPS Data Collection
                      _buildSectionCard(
                        key: _sectionKeys[4],
                        sectionNumber: '5',
                        title: 'Location & GPS Data Collection',
                        icon: Icons.my_location_rounded,
                        content: [
                          _buildBullet(
                            'Delivery Precision:',
                            'We only access device GPS coordinates with your express permission to resolve your delivery address pin and ensure accurate dispatch.',
                          ),
                          _buildBullet(
                            'No Background Location Tracking:',
                            'We do not track your location continuously in the background when the app is closed.',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Section 6: Security & Data Retention
                      _buildSectionCard(
                        key: _sectionKeys[5],
                        sectionNumber: '6',
                        title: 'Security Safeguards & Data Retention',
                        icon: Icons.lock_outline_rounded,
                        content: [
                          _buildBullet(
                            'Encryption in Transit & At Rest:',
                            'All API communications use TLS 1.3 encryption. Database tables enforce strict Postgres Row Level Security (RLS) policies scoped exclusively to authenticated user IDs.',
                          ),
                          _buildBullet(
                            'Retention Period:',
                            'We retain transaction and address records as required for accounting, tax compliance, and warranty support. Account data is retained until you request deletion.',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Section 7: User Rights & Account Deletion
                      _buildSectionCard(
                        key: _sectionKeys[6],
                        sectionNumber: '7',
                        title: 'Your Rights & Account Deletion',
                        icon: Icons.manage_accounts_outlined,
                        content: [
                          _buildBullet(
                            'Access & Correction:',
                            'You may view and modify your profile details, children’s profiles, and address book at any time.',
                          ),
                          _buildBullet(
                            'Complete Account Deletion:',
                            'You have the right to permanently delete your account and all associated personal data. Upon deletion, your profile, children profiles, saved addresses, and active session tokens are wiped from our active databases.',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Section 8: Contact Information & Grievance Officer
                      _buildSectionCard(
                        key: _sectionKeys[7],
                        sectionNumber: '8',
                        title: 'Contact Information & Grievance Redressal',
                        icon: Icons.contact_mail_outlined,
                        accentColor: ToyVerseTheme.primaryNavy,
                        content: [
                          _buildBullet(
                            'Privacy Inquiries:',
                            'Email: privacy@guildclub.com\nSupport: support@guildclub.com',
                          ),
                          _buildBullet(
                            'Grievance Redressal Officer (India):',
                            'Designated Grievance Officer\nGuild Club Parent Experience Hub\nIndiranagar, Bengaluru, Karnataka 560038, India\nPhone: +91 98765 43210',
                          ),
                          _buildBullet(
                            'Legal Note:',
                            'This Privacy Policy is subject to periodic updates to reflect evolving statutory guidelines and service features.',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTocChip(int index, String label) {
    return SpringPressable(
      onTap: () => _scrollToSection(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: ToyVerseTheme.bgLightGray,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: ToyVerseTheme.primaryNavy,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required Key key,
    required String sectionNumber,
    required String title,
    required IconData icon,
    required List<Widget> content,
    Color accentColor = ToyVerseTheme.primaryRoyalBlue,
  }) {
    return GlassCard(
      key: key,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(icon, color: accentColor, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.displayMedium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ToyVerseTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...content,
        ],
      ),
    );
  }

  Widget _buildBullet(String header, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: ToyVerseTheme.primaryRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.bodyMedium.copyWith(
                  color: ToyVerseTheme.textDark,
                  fontSize: 12.5,
                  height: 1.45,
                ),
                children: [
                  TextSpan(
                    text: '$header ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
