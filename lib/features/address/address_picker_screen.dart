import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/location_service.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/toyverse_theme.dart';
import '../../core/widgets/floating_clouds.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/sparkle_badge.dart';
import '../../core/widgets/toy_button.dart';
import '../../models/address_model.dart';
import '../../providers/app_providers.dart';

class AddressPickerScreen extends ConsumerStatefulWidget {
  const AddressPickerScreen({super.key});

  @override
  ConsumerState<AddressPickerScreen> createState() => _AddressPickerScreenState();
}

class _AddressPickerScreenState extends ConsumerState<AddressPickerScreen> with TickerProviderStateMixin {
  double _currentLat = 17.3850;
  double _currentLng = 78.4867;

  String _resolvedAddress = 'Detecting your GPS location...';
  String _city = 'Hyderabad';
  String _state = 'Telangana';
  String _postalCode = '';
  bool _isLocating = false;

  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  String _selectedLabel = 'Home';
  bool _isDefault = true;
  bool _showConfirmationSheet = false;

  late final AnimationController _pinDropController;
  late final AnimationController _radarController;
  late final AnimationController _sheetController;

  @override
  void initState() {
    super.initState();
    _pinDropController = AnimationController(vsync: this, duration: const Duration(milliseconds: 820));
    _radarController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _sheetController = AnimationController(vsync: this, duration: const Duration(milliseconds: 720));
    WidgetsBinding.instance.addPostFrameCallback((_) => _pinDropController.forward());
    _detectGPSLocation();
  }

  @override
  void dispose() {
    _pinDropController.dispose();
    _radarController.dispose();
    _sheetController.dispose();
    _houseController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _detectGPSLocation() async {
    setState(() => _isLocating = true);
    final hasPermission = await LocationService.checkAndRequestPermission(context);
    if (hasPermission) {
      final pos = await LocationService.getCurrentPosition();
      if (pos != null) {
        _currentLat = pos.latitude;
        _currentLng = pos.longitude;
        await _reverseGeocode(pos.latitude, pos.longitude);
      } else {
        await _reverseGeocode(_currentLat, _currentLng);
      }
    } else {
      await _reverseGeocode(_currentLat, _currentLng);
    }
    if (mounted) {
      setState(() => _isLocating = false);
    }
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    if (!mounted) return;
    try {
      final geoapifyRes = await LocationService.reverseGeocodeGeoapify(lat, lng);
      if (!mounted) return;
      if (geoapifyRes != null && geoapifyRes['formatted']?.isNotEmpty == true) {
        setState(() {
          _city = geoapifyRes['city'] ?? '';
          _state = geoapifyRes['state'] ?? '';
          _postalCode = geoapifyRes['postalCode'] ?? '';
          _resolvedAddress = geoapifyRes['formatted']!;
        });
        _pinDropController.forward(from: 0);
        return;
      }

      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final streetParts = [p.name, p.subLocality, p.thoroughfare].where((s) => s != null && s.isNotEmpty).join(', ');
        final city = p.locality ?? p.subAdministrativeArea ?? '';
        final state = p.administrativeArea ?? '';
        final postalCode = p.postalCode ?? '';
        setState(() {
          _city = city;
          _state = state;
          _postalCode = postalCode;
          final locationSegments = [
            if (streetParts.isNotEmpty) streetParts,
            if (city.isNotEmpty) city,
            if (state.isNotEmpty) (postalCode.isNotEmpty ? '$state - $postalCode' : state)
            else if (postalCode.isNotEmpty) postalCode,
          ];
          _resolvedAddress = locationSegments.isNotEmpty
              ? locationSegments.join(', ')
              : (p.street ?? 'Location (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})');
        });
      } else {
        setState(() {
          _resolvedAddress = 'Location (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
        });
      }
      _pinDropController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resolvedAddress = 'Location (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
      });
      _pinDropController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: FloatingCloudsBackground(
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(Icons.arrow_back_rounded, color: ToyVerseTheme.textDark),
                          ),
                        ),
                        Text(
                          'GPS Location Detection',
                          style: AppTypography.displayMedium.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: ToyVerseTheme.textDark,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMapPreview(),
                          const SizedBox(height: 16),
                          GlassCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Detected Address',
                                      style: AppTypography.displayMedium.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: ToyVerseTheme.textDark,
                                      ),
                                    ),
                                    SparkleBadge(
                                      label: 'GPS ${_currentLat.toStringAsFixed(3)}, ${_currentLng.toStringAsFixed(3)}',
                                      backgroundColor: ToyVerseTheme.primaryPurple,
                                      fontSize: 9,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on_rounded, color: ToyVerseTheme.accentCoral, size: 22),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _resolvedAddress,
                                          style: AppTypography.bodyMedium.copyWith(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: ToyVerseTheme.textDark,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'House / Flat / Building Details',
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: ToyVerseTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _houseController,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Flat / House No., Apartment or Building Name',
                                    prefixIcon: const Icon(Icons.home_work_rounded, color: ToyVerseTheme.primaryRoyalBlue, size: 20),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Nearby Landmark (Optional)',
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: ToyVerseTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _landmarkController,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Nearby Landmark, Street or Area reference (Optional)',
                                    prefixIcon: const Icon(Icons.alt_route_rounded, color: ToyVerseTheme.primaryRoyalBlue, size: 20),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Save Address As',
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: ToyVerseTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: ['Home', 'Work', 'Other'].map((label) {
                                    final isSelected = _selectedLabel == label;
                                    return AnimatedScale(
                                      scale: isSelected ? 1.0 : 0.97,
                                      duration: const Duration(milliseconds: 170),
                                      curve: Curves.easeOutBack,
                                      child: GestureDetector(
                                        onTapDown: (_) => setState(() {}),
                                        onTap: () => setState(() => _selectedLabel = label),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 220),
                                          curve: Curves.elasticOut,
                                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isSelected ? ToyVerseTheme.primaryNavy : Colors.white,
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: isSelected ? ToyVerseTheme.primaryNavy : Colors.grey.shade300),
                                            boxShadow: isSelected
                                                ? [BoxShadow(color: ToyVerseTheme.primaryNavy.withValues(alpha: 0.18), blurRadius: 10, offset: const Offset(0, 6))]
                                                : null,
                                          ),
                                          child: Text(
                                            label,
                                            style: AppTypography.bodyLarge.copyWith(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected ? Colors.white : ToyVerseTheme.textDark,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Set as default delivery address',
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: ToyVerseTheme.textDark,
                                      ),
                                    ),
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => setState(() => _isDefault = !_isDefault),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 280),
                                        curve: Curves.easeOutBack,
                                        width: 52,
                                        height: 30,
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(999),
                                          color: _isDefault ? ToyVerseTheme.primaryRoyalBlue : Colors.grey.shade300,
                                        ),
                                        child: AnimatedAlign(
                                          duration: const Duration(milliseconds: 260),
                                          curve: Curves.elasticOut,
                                          alignment: _isDefault ? Alignment.centerRight : Alignment.centerLeft,
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 220),
                                            curve: Curves.easeOutCubic,
                                            width: 20,
                                            height: 20,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(color: Colors.white),
                    child: ToyButton(
                      text: 'Save Address & Deliver Here',
                      gradient: ToyVerseTheme.orangeYellowGradient,
                      onPressed: () {
                        setState(() => _showConfirmationSheet = true);
                        _sheetController.forward(from: 0);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_showConfirmationSheet)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() => _showConfirmationSheet = false);
                _sheetController.reverse();
              },
              child: AnimatedBuilder(
                animation: _sheetController,
                builder: (context, child) {
                  final progress = Curves.easeOutCubic.transform(_sheetController.value.clamp(0.0, 1.0));
                  final fade = progress;

                  return IgnorePointer(
                    ignoring: !_showConfirmationSheet,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.18 * fade),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Transform.translate(
                          offset: Offset(0, 20 + (1 - progress) * 240),
                          child: Opacity(
                            opacity: fade,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(28), bottom: Radius.circular(24)),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10 * fade, sigmaY: 10 * fade),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.72),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 18,
                                          offset: const Offset(0, -8),
                                        ),
                                      ],
                                    ),
                                    child: AnimatedScale(
                                      scale: 0.97 + (progress * 0.03),
                                      duration: const Duration(milliseconds: 260),
                                      curve: Curves.elasticOut,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Center(
                                            child: Container(
                                              width: 42,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade300,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Text(
                                            'Confirm delivery address',
                                            style: AppTypography.displayMedium.copyWith(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                              color: ToyVerseTheme.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: Colors.grey.shade200),
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: ToyVerseTheme.primaryRoyalBlue.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Icon(Icons.location_on_rounded, color: ToyVerseTheme.primaryRoyalBlue),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    _resolvedAddress,
                                                    style: AppTypography.bodyMedium.copyWith(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w700,
                                                      color: ToyVerseTheme.textDark,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 18),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  style: OutlinedButton.styleFrom(
                                                    backgroundColor: Colors.white,
                                                    side: BorderSide(color: Colors.grey.shade300),
                                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                                  ),
                                                  onPressed: () {
                                                    setState(() => _showConfirmationSheet = false);
                                                    _sheetController.reverse();
                                                  },
                                                  child: Text(
                                                    'Edit',
                                                    style: AppTypography.bodyLarge.copyWith(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w700,
                                                      color: ToyVerseTheme.textDark,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: ToyVerseTheme.primaryNavy,
                                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                                    elevation: 0,
                                                  ),
                                                  onPressed: _saveAddressAndPop,
                                                  child: Text(
                                                    'Confirm',
                                                    style: AppTypography.bodyLarge.copyWith(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w700,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMapPreview() {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 220,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ToyVerseTheme.bgLightBlue,
                  Colors.white,
                  ToyVerseTheme.bgLightGray,
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 26,
                  top: 30,
                  child: _MapDot(size: 12, color: ToyVerseTheme.primarySkyBlue.withValues(alpha: 0.7)),
                ),
                Positioned(
                  right: 44,
                  top: 54,
                  child: _MapDot(size: 14, color: ToyVerseTheme.primaryPurple.withValues(alpha: 0.7)),
                ),
                Positioned(
                  left: 64,
                  bottom: 26,
                  child: _MapDot(size: 16, color: ToyVerseTheme.primaryMintGreen.withValues(alpha: 0.72)),
                ),
                Positioned(
                  right: 78,
                  bottom: 58,
                  child: _MapDot(size: 10, color: ToyVerseTheme.primaryOrange.withValues(alpha: 0.7)),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RoadPainter(),
                  ),
                ),
                if (_isLocating)
                  AnimatedBuilder(
                    animation: _radarController,
                    builder: (context, child) {
                      final progress = (_radarController.value * 3.0).clamp(0.0, 1.0);
                      return Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Transform.scale(
                            scale: 0.7 + (progress * 1.1),
                            child: IgnorePointer(
                              child: Container(
                                width: 74,
                                height: 74,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: ToyVerseTheme.primaryRoyalBlue.withValues(alpha: 0.35), width: 2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: AnimatedBuilder(
                    animation: _pinDropController,
                    builder: (context, _) {
                      final eased = Curves.easeInCubic.transform(_pinDropController.value.clamp(0.0, 1.0));
                      final bounce = _pinDropController.value > 0.82
                          ? (1 - ((_pinDropController.value - 0.82) / 0.18).clamp(0.0, 1.0)) * 12
                          : 0.0;
                      final yOffset = 80 - (eased * 80) + bounce;
                      final scale = 0.72 + (eased * 0.28);

                      return Center(
                        child: Transform.translate(
                          offset: Offset(0, yOffset),
                          child: Transform.scale(
                            scale: scale,
                            child: const _PinMarker(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveAddressAndPop() async {
    final user = ref.read(userProvider);
    final houseDetail = _houseController.text.trim();
    final landmarkDetail = _landmarkController.text.trim();

    final addressSegments = <String>[];
    if (houseDetail.isNotEmpty) {
      addressSegments.add(houseDetail);
    }
    if (_resolvedAddress.isNotEmpty && !_resolvedAddress.toLowerCase().contains('detecting')) {
      addressSegments.add(_resolvedAddress);
    }
    if (landmarkDetail.isNotEmpty) {
      addressSegments.add('Landmark: $landmarkDetail');
    }

    final fullAddrStr = addressSegments.isNotEmpty
        ? addressSegments.join(', ')
        : (_resolvedAddress.isNotEmpty ? _resolvedAddress : 'Hyderabad, Telangana');

    final newAddr = AddressModel(
      id: const Uuid().v4(),
      userId: user.id.isNotEmpty ? user.id : 'user_guildclub_1',
      label: _selectedLabel,
      fullAddress: fullAddrStr,
      latitude: _currentLat,
      longitude: _currentLng,
      city: _city.isNotEmpty ? _city : 'Hyderabad',
      state: _state.isNotEmpty ? _state : 'Telangana',
      postalCode: _postalCode,
      isDefault: _isDefault,
      createdAt: DateTime.now(),
    );

    if (_showConfirmationSheet) {
      setState(() => _showConfirmationSheet = false);
      _sheetController.reverse();
    }

    await ref.read(addressesProvider.notifier).addOrUpdateAddress(newAddr);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved $_selectedLabel Address! 📍'),
          backgroundColor: ToyVerseTheme.primaryMintGreen,
        ),
      );
      Navigator.pop(context, newAddr);
    }
  }
}

class _MapDot extends StatelessWidget {
  final double size;
  final Color color;

  const _MapDot({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 10, spreadRadius: 2)],
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.12, size.height * 0.16);
    path.lineTo(size.width * 0.38, size.height * 0.42);
    path.lineTo(size.width * 0.24, size.height * 0.76);
    path.lineTo(size.width * 0.68, size.height * 0.92);
    path.lineTo(size.width * 0.88, size.height * 0.46);

    canvas.drawPath(path, paint);

    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PinMarker extends StatelessWidget {
  const _PinMarker();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 46,
      child: CustomPaint(
        painter: _PinPainter(),
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final bodyPaint = Paint()
      ..color = ToyVerseTheme.primaryRoyalBlue
      ..style = PaintingStyle.fill;

    final shadow = Paint()
      ..color = ToyVerseTheme.primaryRoyalBlue.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawCircle(Offset(center.dx, center.dy + 5), 14, shadow);

    final path = Path()
      ..moveTo(center.dx, size.height)
      ..lineTo(size.width, center.dy + 4)
      ..quadraticBezierTo(center.dx + 11, center.dy - 8, center.dx, 0)
      ..quadraticBezierTo(center.dx - 11, center.dy - 8, 0, center.dy + 4)
      ..close();
    canvas.drawPath(path, bodyPaint);

    final dot = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawCircle(center, 7, dot);

    final inner = Paint()..color = ToyVerseTheme.primaryNavy..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.5, inner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
