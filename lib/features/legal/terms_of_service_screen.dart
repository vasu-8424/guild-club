import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/toyverse_theme.dart';
import '../../core/widgets/floating_clouds.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/sparkle_badge.dart';
import '../../core/widgets/spring_widgets.dart';

/// DRAFT TERMS OF SERVICE FOR GUILD CLUB (TOYVERSE)
///
/// NOTE FOR DEVELOPERS & LEGAL COMPLIANCE:
/// This document is a structured DRAFT generated specifically for Guild Club based on
/// the platform's features (product orders, Razorpay transactions, ToyCoins loyalty engine,
/// verified directory listings, and child profiles).
///
/// IMPORTANT LEGAL NOTICE:
/// This draft MUST be formally reviewed and approved by qualified legal counsel
/// prior to production launch in India or target operating jurisdictions.
class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _sectionKeys = List.generate(7, (_) => GlobalKey());

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
                                  'Terms of Service',
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

              // 2. Scrollable Terms Content
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
                                    color: ToyVerseTheme.primaryNavy.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.gavel_rounded, color: ToyVerseTheme.primaryNavy, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Welcome to Guild Club',
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
                              'These Terms of Service govern your access to and use of the Guild Club mobile application, physical learning store, and directory services. By accessing our platform, you agree to be bound by these terms.',
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
                                _buildTocChip(0, '1. Eligibility & Accounts'),
                                _buildTocChip(1, '2. Orders & Payments'),
                                _buildTocChip(2, '3. Delivery & Dispatch'),
                                _buildTocChip(3, '4. Directory Listings'),
                                _buildTocChip(4, '5. ToyCoins & Rewards'),
                                _buildTocChip(5, '6. Product Safety & Returns'),
                                _buildTocChip(6, '7. Governing Law'),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Section 1
                      _buildSectionCard(
                        key: _sectionKeys[0],
                        title: '1. Eligibility & Parent Account Registration',
                        icon: Icons.person_outline_rounded,
                        content: [
                          _buildBullet(
                            'Age Requirement:',
                            'You must be at least 18 years old or the age of legal majority in your jurisdiction to create an account and transact on Guild Club.',
                          ),
                          _buildBullet(
                            'Account Security:',
                            'You are responsible for maintaining the confidentiality of your login credentials and for all activities under your account.',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Section 2
                      _buildSectionCard(
                        key: _sectionKeys[1],
                        title: '2. Product Orders & Pricing via Razorpay',
                        icon: Icons.payment_outlined,
                        content: [
                          _buildBullet(
                            'Pricing Transparency:',
                            'All prices are listed in Indian Rupees (INR) and inclusive of applicable GST unless explicitly stated.',
                          ),
                          _buildBullet(
                            'Payment Processing:',
                            'We partner with Razorpay to facilitate UPI, credit/debit cards, and net banking payments. Transactions are authorized securely through Razorpay’s payment gateway.',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Section 3
                      _buildSectionCard(
                        key: _sectionKeys[2],
                        title: '3. Order Fulfillment & Realtime Dispatch',
                        icon: Icons.local_shipping_outlined,
                        content: [
                          _buildBullet(
                            'Fulfillment Hubs:',
                            'Orders are fulfilled from authorized Guild Club logistics hubs and dispatched via verified express courier partners.',
                          ),
                          _buildBullet(
                            'Estimated Timelines:',
                            'Estimated delivery arrival times displayed on the tracking screen are reasonable estimates based on hub distance and traffic conditions.',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Section 4
                      _buildSectionCard(
                        key: _sectionKeys[3],
                        title: '4. Verified Child Development & School Directory',
                        icon: Icons.domain_rounded,
                        accentColor: ToyVerseTheme.primaryRed,
                        content: [
                          _buildBullet(
                            'Directory Role:',
                            'Guild Club curates listings for Child Development Centers, Play Schools, Therapy Clinics, and Educational Interior Designers. While we verify licensing credentials, third-party services are provided independently by the respective centers.',
                          ),
                          _buildBullet(
                            'Direct Inquiries:',
                            'Contact information provided for centers (WhatsApp, phone) connects you directly to the verified provider.',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Section 5
                      _buildSectionCard(
                        key: _sectionKeys[4],
                        title: '5. Guild Coins & Rewards Program',
                        icon: Icons.stars_rounded,
                        content: [
                          _buildBullet(
                            'Loyalty Rewards:',
                            'ToyCoins and promotional vouchers have no independent cash value and cannot be redeemed for fiat currency outside the Guild Club app.',
                          ),
                          _buildBullet(
                            'Fair Use Policy:',
                            'Guild Club reserves the right to withhold coins earned through fraudulent activities or automated manipulation of daily activities.',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Section 6
                      _buildSectionCard(
                        key: _sectionKeys[5],
                        title: '6. Child Safety Standards & Returns',
                        icon: Icons.verified_user_outlined,
                        content: [
                          _buildBullet(
                            'Child-Safe Certification:',
                            'All physical toys conform to strict non-toxic, BPA-free, and child-safe durability standards.',
                          ),
                          _buildBullet(
                            '7-Day Return Guarantee:',
                            'If any toy arrives damaged or missing pieces, report it within 7 days for an immediate replacement or full refund credited to your wallet.',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Section 7
                      _buildSectionCard(
                        key: _sectionKeys[6],
                        title: '7. Governing Law & Dispute Resolution',
                        icon: Icons.balance_rounded,
                        accentColor: ToyVerseTheme.primaryNavy,
                        content: [
                          _buildBullet(
                            'Jurisdiction:',
                            'These Terms shall be governed by and construed in accordance with the laws of India. Courts in Hyderabad, Telangana shall have exclusive jurisdiction.',
                          ),
                          _buildBullet(
                            'Customer Grievances:',
                            'For any disputes or customer support inquiries, please reach out to support@guildclub.com.',
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
              color: ToyVerseTheme.primaryRoyalBlue,
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
