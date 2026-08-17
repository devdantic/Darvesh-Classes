import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_page.dart';
import 'authentication_page.dart';
import 'home_page.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';

/// ============================================================================
/// DARVESH CLASSES - ULTRA PREMIUM ANIMATED SPLASH SCREEN
/// Designed with Senior Engineering Principles:
/// - Staggered Physics Animation Choreography
/// - Lightweight 60/120fps Custom Canvas Constellation Particle System
/// - Multi-Layered Frosted Glassmorphic Medallion with Specular Light Sweep
/// - Dynamic Luminous Status Beam & Intelligent Async Session Resolver
/// ============================================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Controllers
  // ---------------------------------------------------------------------------
  late final AnimationController _revealController;
  late final AnimationController _ambientLoopController;
  late final AnimationController _shimmerController;

  // Staggered Reveal Animations
  late final Animation<double> _bgAuraScale;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoElevation;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _footerFade;
  late final Animation<double> _progressValue;

  // Timers & State
  Timer? _maxTimeoutTimer;
  bool _isNavigating = false;
  String _statusMessage = 'Initializing Learning Environment...';

  @override
  void initState() {
    super.initState();

    // 1. Reveal Sequence Controller (Runs once on mount)
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // 2. Ambient Continuous Controller (Drives particles & breathing auras)
    _ambientLoopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // 3. Shimmer Sweep Controller (Gleam over the emblem)
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // -------------------------------------------------------------------------
    // Animation Curves & Timeline Staggering
    // -------------------------------------------------------------------------

    // Background Aura Bloom (0.0 -> 0.4)
    _bgAuraScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    // Logo Emblem Spring Entrance (0.15 -> 0.60)
    _logoScale = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.15, 0.60, curve: Curves.elasticOut),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.10, 0.40, curve: Curves.easeIn),
      ),
    );

    _logoElevation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.20, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // Title Entrance (0.45 -> 0.75)
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOutBack),
      ),
    );

    // Tagline Pill Entrance (0.60 -> 0.85)
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.60, 0.85, curve: Curves.easeOut),
      ),
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.60, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    // Footer & Progress Bar (0.70 -> 1.0)
    _footerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.70, 0.95, curve: Curves.easeOut),
      ),
    );

    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.25, 0.98, curve: Curves.easeInOutCubic),
      ),
    );

    // Dynamic Status Messages linked to progress
    _revealController.addListener(() {
      final val = _revealController.value;
      if (!mounted) return;
      if (val < 0.4) {
        if (_statusMessage != 'Initializing Learning Environment...') {
          setState(() => _statusMessage = 'Initializing Learning Environment...');
        }
      } else if (val < 0.75) {
        if (_statusMessage != 'Connecting to Academic Cloud...') {
          setState(() => _statusMessage = 'Connecting to Academic Cloud...');
        }
      } else {
        if (_statusMessage != 'Welcome to Darvesh Classes') {
          setState(() => _statusMessage = 'Welcome to Darvesh Classes');
        }
      }
    });

    // Start reveal sequence
    _revealController.forward();

    // Trigger specular shimmer shortly after logo pops in
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        _shimmerController.forward();
      }
    });

    // Handle seamless session routing
    _startSessionResolution();
  }

  /// Resolve user state gracefully while allowing the animation to play smoothly
  Future<void> _startSessionResolution() async {
    // Minimum visual display duration for luxurious feel (3.0 seconds)
    final minDisplayFuture = Future.delayed(const Duration(milliseconds: 3100));

    // Parallel session determination
    Widget targetPage = const AuthenticationPage();

    try {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        final profile = await ProfileService.instance.getCurrentProfile().timeout(
          const Duration(seconds: 3),
          onTimeout: () => null,
        );

        if (profile != null) {
          final email = (profile['email'] as String? ?? user.email ?? '').trim().toLowerCase();
          final role = (profile['role'] as String? ?? '').trim().toLowerCase();
          final name = (profile['name'] as String? ?? '').trim().toLowerCase();

          final bool isAdmin = email == 'sanjaygovindani757@gmail.com' ||
              role == 'admin' ||
              name.contains('sanjay');

          targetPage = isAdmin ? const AdminPage() : const HomePage();
        } else {
          // If profile fetch fails but user exists, default to HomePage
          targetPage = const HomePage();
        }
      }
    } catch (e) {
      debugPrint('Splash session resolution error: $e');
      targetPage = const AuthenticationPage();
    }

    // Wait for minimum visual duration so user experiences the full beauty
    await minDisplayFuture;

    if (!mounted || _isNavigating) return;
    _navigateTo(targetPage);
  }

  void _navigateTo(Widget page) {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          final scale = Tween<double>(begin: 0.96, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );
          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  void _handleManualSkip() {
    if (_isNavigating) return;
    _maxTimeoutTimer?.cancel();
    _startSessionResolution();
  }

  @override
  void dispose() {
    _maxTimeoutTimer?.cancel();
    _revealController.dispose();
    _ambientLoopController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF070B19),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // -----------------------------------------------------------------
          // 1. Deep Midnight Cosmic Background Gradient
          // -----------------------------------------------------------------
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.2),
                radius: 1.3,
                colors: [
                  Color(0xFF1E2756), // Luminous Royal Indigo Core
                  Color(0xFF10173A), // Deep Midnight Sapphire
                  Color(0xFF070B19), // Absolute Void Obsidian
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // -----------------------------------------------------------------
          // 2. Animated Floating Ambient Glow Orbs (Aurora effect)
          // -----------------------------------------------------------------
          AnimatedBuilder(
            animation: _ambientLoopController,
            builder: (context, child) {
              final double t = _ambientLoopController.value * 2 * math.pi;
              final double orb1X = math.sin(t) * 40;
              final double orb1Y = math.cos(t) * 35;
              final double orb2X = math.cos(t * 0.8) * 50;
              final double orb2Y = math.sin(t * 0.8) * 40;

              return Stack(
                children: [
                  // Top-Left Indigo Nebula
                  Positioned(
                    top: size.height * 0.15 + orb1Y,
                    left: size.width * 0.1 + orb1X,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF4F46E5).withValues(alpha: 0.35),
                            const Color(0xFF3B82F6).withValues(alpha: 0.12),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Bottom-Right Cyan/Sapphire Nebula
                  Positioned(
                    bottom: size.height * 0.2 + orb2Y,
                    right: size.width * 0.08 + orb2X,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF06B6D4).withValues(alpha: 0.25),
                            const Color(0xFF3B82F6).withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // -----------------------------------------------------------------
          // 3. Custom Canvas: Drifting Constellation & Knowledge Particles
          // -----------------------------------------------------------------
          AnimatedBuilder(
            animation: _ambientLoopController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ConstellationParticlesPainter(
                  progress: _ambientLoopController.value,
                  particleColor: const Color(0xFF38BDF8),
                ),
                size: Size.infinite,
              );
            },
          ),

          // -----------------------------------------------------------------
          // 4. Central Hero Content (Emblem, Typography, Status Bar)
          // -----------------------------------------------------------------
          SafeArea(
            child: Column(
              children: [
                // Top Action Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status Badge Tag
                      FadeTransition(
                        opacity: _taglineFade,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF10B981),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ACADEMY PORTAL',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.75),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Glassmorphic Skip Pill Button
                      FadeTransition(
                        opacity: _taglineFade,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _handleManualSkip,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  width: 0.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Skip',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    size: 14,
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

                const Spacer(flex: 2),

                // -------------------------------------------------------------
                // Center Medallion Emblem with Multi-Layered Glow & Shimmer
                // -------------------------------------------------------------
                Center(
                  child: AnimatedBuilder(
                    animation: _revealController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _logoFade,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: _buildLuxuryLogoMedallion(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 36),

                // -------------------------------------------------------------
                // Brand Typography Hierarchy
                // -------------------------------------------------------------
                FadeTransition(
                  opacity: _titleFade,
                  child: SlideTransition(
                    position: _titleSlide,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Main Brand Name with Gradient Shimmer
                        ShaderMask(
                          shaderCallback: (bounds) {
                            return const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFFFFFF),
                                Color(0xFFE0E7FF),
                                Color(0xFF93C5FD),
                                Color(0xFFFFFFFF),
                              ],
                              stops: [0.0, 0.4, 0.75, 1.0],
                            ).createShader(bounds);
                          },
                          child: Text(
                            'DARVESH CLASSES',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4.5,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Glowing Accent Divider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 1.5,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    const Color(0xFF38BDF8).withValues(alpha: 0.6),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF38BDF8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 32,
                              height: 1.5,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF38BDF8).withValues(alpha: 0.6),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // -------------------------------------------------------------
                // Refined Tagline Capsule
                // -------------------------------------------------------------
                FadeTransition(
                  opacity: _taglineFade,
                  child: SlideTransition(
                    position: _taglineSlide,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFF818CF8).withValues(alpha: 0.25),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFF38BDF8),
                            size: 13,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'EMPOWERING MINDS • SHAPING FUTURES',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.8,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // -------------------------------------------------------------
                // Dynamic Luminous Beam & Contextual Status
                // -------------------------------------------------------------
                FadeTransition(
                  opacity: _footerFade,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Glowing Progress Bar Capsule
                        Container(
                          height: 5,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: AnimatedBuilder(
                            animation: _progressValue,
                            builder: (context, child) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: _progressValue.value.clamp(0.01, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF4F46E5), // Indigo
                                          Color(0xFF06B6D4), // Cyan
                                          Color(0xFF38BDF8), // Sky
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Real-time Status Text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Pulsing Mini Radar Orb
                            AnimatedBuilder(
                              animation: _ambientLoopController,
                              builder: (context, child) {
                                final double pulse = (math.sin(_ambientLoopController.value * 2 * math.pi) + 1) / 2;
                                return Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF38BDF8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF38BDF8).withValues(alpha: 0.3 + 0.7 * pulse),
                                        blurRadius: 6 + 4 * pulse,
                                        spreadRadius: 1 + 2 * pulse,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _statusMessage,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.6,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Institutional Sub-brand
                        Text(
                          'PREMIER EDUCATIONAL EXCELLENCE',
                          style: GoogleFonts.outfit(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.5,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ---------------------------------------------------------------------------
  /// Luxury Multi-Layered Glassmorphic Logo Medallion
  /// ---------------------------------------------------------------------------
  Widget _buildLuxuryLogoMedallion() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. Radiant Multi-Stop Bloom Aura
        AnimatedBuilder(
          animation: Listenable.merge([_ambientLoopController, _bgAuraScale]),
          builder: (context, child) {
            final double breathe = (math.sin(_ambientLoopController.value * 2 * math.pi) + 1) / 2;
            final double scale = _bgAuraScale.value * (0.95 + (0.12 * breathe));
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF4F46E5).withValues(alpha: 0.55),
                      const Color(0xFF38BDF8).withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            );
          },
        ),

        // 2. Sonic Concentric Pulse Rings
        AnimatedBuilder(
          animation: _ambientLoopController,
          builder: (context, child) {
            final double ringPhase = _ambientLoopController.value;
            final double ringScale = 1.0 + (0.35 * ringPhase);
            final double ringOpacity = (1.0 - ringPhase).clamp(0.0, 0.5);

            return Transform.scale(
              scale: ringScale,
              child: Container(
                width: 175,
                height: 175,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: ringOpacity),
                    width: 1.2,
                  ),
                ),
              ),
            );
          },
        ),

        // 3. Frosted Acrylic Pedestal Shield with Elevation Shadow
        AnimatedBuilder(
          animation: _logoElevation,
          builder: (context, child) {
            final double elev = _logoElevation.value;
            return ClipRRect(
              borderRadius: BorderRadius.circular(44),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: 154,
                  height: 154,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(44),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.22),
                        Colors.white.withValues(alpha: 0.06),
                        const Color(0xFF1E293B).withValues(alpha: 0.4),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.35 * elev),
                        blurRadius: 16 + (16 * elev),
                        spreadRadius: 2 * elev,
                        offset: Offset(0, 4 + (8 * elev)),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4 * elev),
                        blurRadius: 12 + (12 * elev),
                        offset: Offset(0, 4 + (4 * elev)),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Inner White Card Glow Pad
                      Container(
                        width: 126,
                        height: 126,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(34),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'media/DC_logo_2.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      // 4. Specular Gleam Shimmer Beam
                      AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, child) {
                          final double shimmerVal = _shimmerController.value;
                          if (shimmerVal <= 0.0 || shimmerVal >= 1.0) {
                            return const SizedBox.shrink();
                          }
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(44),
                            child: Transform.translate(
                              offset: Offset((shimmerVal * 320) - 160, (shimmerVal * 320) - 160),
                              child: Transform.rotate(
                                angle: math.pi / 4,
                                child: Container(
                                  width: 45,
                                  height: 260,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0.0),
                                        Colors.white.withValues(alpha: 0.65),
                                        Colors.white.withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// ============================================================================
/// High-Performance Animated Constellation Particle Painter
/// Renders floating academic/cosmic nodes with dynamic distance linkages
/// ============================================================================
class _ConstellationParticlesPainter extends CustomPainter {
  final double progress;
  final Color particleColor;

  static final List<_SplashParticle> _particles = List.generate(
    28,
    (index) => _SplashParticle(
      initialX: (index * 37.0 % 100) / 100,
      initialY: (index * 53.0 % 100) / 100,
      speedX: ((index % 5) - 2) * 0.03 + 0.015,
      speedY: (((index * 3) % 5) - 2) * 0.03 - 0.02,
      radius: (index % 3 == 0) ? 2.4 : ((index % 2 == 0) ? 1.8 : 1.2),
      alpha: 0.18 + ((index % 4) * 0.15),
    ),
  );

  _ConstellationParticlesPainter({
    required this.progress,
    required this.particleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    final List<Offset> positions = [];

    for (final p in _particles) {
      final double dx = ((p.initialX + (p.speedX * progress)) % 1.0) * size.width;
      final double dy = ((p.initialY + (p.speedY * progress)) % 1.0) * size.height;
      final pos = Offset(dx, dy);
      positions.add(pos);

      // Draw particle dot with soft glow
      paint.color = particleColor.withValues(alpha: p.alpha);
      canvas.drawCircle(pos, p.radius, paint);
    }

    // Connect close particles with faint constellation lines
    for (int i = 0; i < positions.length; i++) {
      for (int j = i + 1; j < positions.length; j++) {
        final double distance = (positions[i] - positions[j]).distance;
        if (distance < 75.0) {
          final double lineAlpha = (1.0 - (distance / 75.0)) * 0.18;
          linePaint.color = particleColor.withValues(alpha: lineAlpha);
          canvas.drawLine(positions[i], positions[j], linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationParticlesPainter oldDelegate) => true;
}

class _SplashParticle {
  final double initialX;
  final double initialY;
  final double speedX;
  final double speedY;
  final double radius;
  final double alpha;

  const _SplashParticle({
    required this.initialX,
    required this.initialY,
    required this.speedX,
    required this.speedY,
    required this.radius,
    required this.alpha,
  });
}
