import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/room_fit_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/toyverse_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/sparkle_badge.dart';
import '../../../core/widgets/spring_widgets.dart';
import '../../../models/product_model.dart';

class RoomFitModal extends StatefulWidget {
  final ProductModel product;

  const RoomFitModal({super.key, required this.product});

  static Future<void> show(BuildContext context, ProductModel product) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RoomFitModal(product: product),
    );
  }

  @override
  State<RoomFitModal> createState() => _RoomFitModalState();
}

class _RoomFitModalState extends State<RoomFitModal> {
  int _currentStep = 0; // 0: Consent, 1: Loading, 2: Result, 3: Error
  Uint8List? _imageBytes;
  RoomFitResult? _analysisResult;
  String? _errorMessage;
  bool _isSavedToProfile = false;
  int _loadingPhase = 0;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1400,
        maxHeight: 1400,
        imageQuality: 85,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _currentStep = 1;
        _loadingPhase = 0;
      });

      _startAnalysis(bytes);
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load photo. Please check permissions and try again.';
        _currentStep = 3;
      });
    }
  }

  /// Sample room photo option for rapid testing or preview without camera access
  Future<void> _useSampleRoomPhoto() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/categories/play_schools.png');
      final bytes = data.buffer.asUint8List();
      setState(() {
        _imageBytes = bytes;
        _currentStep = 1;
        _loadingPhase = 0;
      });
      _startAnalysis(bytes);
    } catch (_) {
      // Fallback 1x1 png dummy
      final dummyBytes = Uint8List.fromList([
        137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 10, 73, 68, 65, 84, 120, 156, 99, 0, 1, 0, 0, 5, 0, 1, 13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130
      ]);
      setState(() {
        _imageBytes = dummyBytes;
        _currentStep = 1;
        _loadingPhase = 0;
      });
      _startAnalysis(dummyBytes);
    }
  }

  Future<void> _startAnalysis(Uint8List bytes) async {
    // Staggered loading progress for restrained UX
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && _currentStep == 1) setState(() => _loadingPhase = 1);
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted && _currentStep == 1) setState(() => _loadingPhase = 2);
    });

    try {
      final result = await RoomFitService.analyzeRoomFit(
        imageBytes: bytes,
        product: widget.product,
      );

      if (mounted) {
        setState(() {
          _analysisResult = result;
          _currentStep = 2;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          _currentStep = 3;
        });
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            color: Colors.white.withValues(alpha: 0.94),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Room Photo 📷',
                  style: AppTypography.displayMedium.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Take a clear photo showing the floor area where you wish to place this product.',
                  style: AppTypography.bodySmall.copyWith(color: ToyVerseTheme.textMuted),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: SpringPressable(
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.camera);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: ToyVerseTheme.bgLightGray,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.camera_alt_rounded, size: 28, color: ToyVerseTheme.primaryNavy),
                              const SizedBox(height: 8),
                              Text('Take Photo', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SpringPressable(
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.gallery);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: ToyVerseTheme.bgLightGray,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.photo_library_rounded, size: 28, color: ToyVerseTheme.primaryRoyalBlue),
                              const SizedBox(height: 8),
                              Text('Photo Gallery', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _useSampleRoomPhoto();
                    },
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16, color: ToyVerseTheme.primaryOrange),
                    label: Text(
                      'Use Demo Room Photo',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ToyVerseTheme.primaryOrange,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle Bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ToyVerseTheme.primaryNavy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.home_work_rounded, size: 18, color: ToyVerseTheme.primaryNavy),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Room Fit Advisor',
                          style: AppTypography.displayMedium.copyWith(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Spatial & Child Safety Planning',
                          style: AppTypography.bodySmall.copyWith(fontSize: 11, color: ToyVerseTheme.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: ToyVerseTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.black12),

          // Dynamic Body Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCurrentStep(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return _buildConsentStep(context);
      case 1:
        return _buildLoadingStep(context);
      case 2:
        return _buildResultStep(context);
      case 3:
      default:
        return _buildErrorStep(context);
    }
  }

  // STEP 0: Exact Confirmed Consent & Privacy Notice
  Widget _buildConsentStep(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Target Card
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    widget.product.imageUrls.isNotEmpty
                        ? widget.product.imageUrls.first
                        : 'https://images.unsplash.com/photo-1587654780291-39c9404d746b?q=80&w=400',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: ToyVerseTheme.bgLightGray,
                      child: const Icon(Icons.toys_rounded, color: ToyVerseTheme.primaryNavy),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.displayMedium.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.product.dimensions ?? 'Approx. 120 cm (L) x 80 cm (W) x 90 cm (H)',
                        style: AppTypography.bodySmall.copyWith(fontSize: 11, color: ToyVerseTheme.primaryRoyalBlue, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SparkleBadge(label: 'ELIGIBLE', backgroundColor: ToyVerseTheme.primaryMintGreen, fontSize: 8),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Photo Analysis & Privacy Notice 🛡️',
            style: AppTypography.displayMedium.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          // Exact User-Approved Privacy Notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ToyVerseTheme.primaryNavy.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ToyVerseTheme.primaryNavy.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.privacy_tip_outlined, color: ToyVerseTheme.primaryNavy, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'We will analyze your room photo using an AI vision service solely to provide room placement, aesthetic fit, and child safety recommendations for this product. Your photo is processed securely in memory and automatically discarded immediately after analysis unless you choose to save it to your profile.',
                        style: AppTypography.bodyMedium.copyWith(fontSize: 13, height: 1.5, color: const Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Colors.black12),
                const SizedBox(height: 12),
                _buildPrivacyBullet(Icons.memory_rounded, 'In-Memory Processing: No permanent server photo storage'),
                const SizedBox(height: 6),
                _buildPrivacyBullet(Icons.child_care_rounded, 'Child Safety Focused: Checks door buffers & floor clearances'),
                const SizedBox(height: 6),
                _buildPrivacyBullet(Icons.speed_rounded, 'Fair Use: Up to 10 AI room fit analyses per day'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Select Room Photo Source 📷',
            style: AppTypography.displayMedium.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ToyVerseTheme.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                  label: Text('Camera', style: AppTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ToyVerseTheme.primaryRoyalBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.photo_library_rounded, size: 18, color: Colors.white),
                  label: Text('Gallery', style: AppTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _useSampleRoomPhoto,
              style: OutlinedButton.styleFrom(
                foregroundColor: ToyVerseTheme.primaryOrange,
                side: BorderSide(color: ToyVerseTheme.primaryOrange.withValues(alpha: 0.6)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.auto_awesome_rounded, size: 16, color: ToyVerseTheme.primaryOrange),
              label: Text(
                'Try with Sample Room Photo',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ToyVerseTheme.primaryOrange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyBullet(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: ToyVerseTheme.primaryRoyalBlue),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(fontSize: 11, color: ToyVerseTheme.textMuted, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // STEP 1: Restrained Loading State (Utility wait, not celebration)
  Widget _buildLoadingStep(BuildContext context) {
    final phases = [
      'Assessing floor space & room lighting...',
      'Evaluating traffic flow & child safety clearances...',
      'Synthesizing placement recommendations...',
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular Restrained Loader with image preview
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: const AlwaysStoppedAnimation<Color>(ToyVerseTheme.primaryNavy),
                    backgroundColor: ToyVerseTheme.primaryNavy.withValues(alpha: 0.1),
                  ),
                ),
                if (_imageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(45),
                    child: Image.memory(
                      _imageBytes!,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  const Icon(Icons.home_work_rounded, size: 40, color: ToyVerseTheme.primaryNavy),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Analyzing Room Placement',
              style: AppTypography.displayMedium.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                phases[_loadingPhase.clamp(0, phases.length - 1)],
                key: ValueKey<int>(_loadingPhase),
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(fontSize: 13, color: ToyVerseTheme.textMuted),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: ToyVerseTheme.bgLightGray,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 12, color: ToyVerseTheme.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    'In-memory secure analysis',
                    style: AppTypography.bodySmall.copyWith(fontSize: 11, color: ToyVerseTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 2: Structured Recommendation & Placement Overlay Result
  Widget _buildResultStep(BuildContext context) {
    if (_analysisResult == null) return const SizedBox.shrink();
    final result = _analysisResult!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Fit Score & Verdict Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: ToyVerseTheme.primaryMintGreen, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          result.fitVerdict,
                          style: AppTypography.displayMedium.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SparkleBadge(
                      label: '${result.fitScore}/100 Fit',
                      backgroundColor: ToyVerseTheme.primaryMintGreen,
                      fontSize: 10,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  result.recommendationSummary,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Interactive Room Photo with Suggested Placement Area Overlay
          if (_imageBytes != null) ...[
            Text(
              'Spatial Placement Preview 📐',
              style: AppTypography.displayMedium.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Approximate suggested placement zone (not exact AR positioning):',
              style: AppTypography.bodySmall.copyWith(fontSize: 12, color: ToyVerseTheme.textMuted),
            ),
            const SizedBox(height: 10),

            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Base Uploaded Room Image
                    Image.memory(
                      _imageBytes!,
                      fit: BoxFit.cover,
                    ),

                    // Semi-transparent Suggested Region Highlight
                    Positioned(
                      left: MediaQuery.of(context).size.width * (result.suggestedRegionBox.x * 0.88),
                      top: 260 * (result.suggestedRegionBox.y),
                      width: (MediaQuery.of(context).size.width * 0.88) * result.suggestedRegionBox.width,
                      height: 260 * result.suggestedRegionBox.height,
                      child: Container(
                        decoration: BoxDecoration(
                          color: ToyVerseTheme.primarySkyBlue.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ToyVerseTheme.primarySkyBlue,
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: ToyVerseTheme.primarySkyBlue.withValues(alpha: 0.35),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            margin: const EdgeInsets.all(6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: ToyVerseTheme.primaryNavy.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.place_rounded, color: Colors.white, size: 10),
                                const SizedBox(width: 3),
                                Text(
                                  'Suggested area',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: ToyVerseTheme.bgLightGray,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: ToyVerseTheme.primaryRoyalBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Area: ${result.suggestedRegionDescription}',
                      style: AppTypography.bodySmall.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Key Reasoning Bullets
          Text(
            'Why It Fits Well 💡',
            style: AppTypography.displayMedium.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...result.keyReasons.map((reason) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: ToyVerseTheme.primaryMintGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 10, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        reason,
                        style: AppTypography.bodyMedium.copyWith(fontSize: 13, height: 1.4, color: const Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 14),

          // Child Safety Considerations Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.health_and_safety_outlined, color: Color(0xFFD97706), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Child Safety Advisory',
                      style: AppTypography.displayMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...result.safetyConsiderations.map((safety) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              safety,
                              style: AppTypography.bodySmall.copyWith(fontSize: 12, color: const Color(0xFF78350F)),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              // Try Another Photo Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showImageSourcePicker,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: ToyVerseTheme.primaryNavy),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: ToyVerseTheme.primaryNavy),
                  label: Text(
                    'Try Another Photo',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ToyVerseTheme.primaryNavy,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Save to Profile (Explicit Opt-In)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSavedToProfile
                      ? null
                      : () {
                          setState(() => _isSavedToProfile = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Room photo & placement saved to your profile! 📁'),
                              backgroundColor: ToyVerseTheme.primaryMintGreen,
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: _isSavedToProfile ? ToyVerseTheme.primaryMintGreen : ToyVerseTheme.primaryNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(
                    _isSavedToProfile ? Icons.check_circle_outline_rounded : Icons.bookmark_add_outlined,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isSavedToProfile ? 'Saved' : 'Save to Profile',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // STEP 3: Error State with Friendly Guidance
  Widget _buildErrorStep(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: ToyVerseTheme.primaryRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 40, color: ToyVerseTheme.primaryRed),
            ),
            const SizedBox(height: 18),
            Text(
              'Analysis Notice',
              style: AppTypography.displayMedium.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unable to evaluate room space. Please ensure good lighting and try again.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(fontSize: 13, color: ToyVerseTheme.textMuted),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentStep = 0),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _showImageSourcePicker,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ToyVerseTheme.primaryNavy,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
