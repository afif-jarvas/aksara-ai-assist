import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';
import 'dart:math';
import '../theme/app_theme.dart';

class AnimatedBackground extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const AnimatedBackground({super.key, required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Layer
        Positioned.fill(
          child: isDark ? const _GalaxyBackground() : _buildGhibliBackground(),
        ),
        // Content Layer
        SafeArea(child: child),
      ],
    );
  }

  Widget _buildGhibliBackground() {
    // Efek Ombak Awan (Ghibli Style)
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF89CFF0), 
            Color(0xFFFFFDD0)
          ],
        ),
      ),
      child: MirrorAnimationBuilder<double>(
        tween: Tween(begin: -50.0, end: 0.0),
        duration: const Duration(seconds: 10),
        curve: Curves.easeInOutSine,
        builder: (context, value, child) {
          return Stack(
            children: [
              Positioned(
                top: value,
                left: 0,
                right: 0,
                height: 200,
                child: Opacity(
                  opacity: 0.3,
                  child: Image.asset(
                    'assets/images/clouds.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_,__,___) => Container(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GalaxyBackground extends StatelessWidget {
  const _GalaxyBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24CBFF)],
        ),
      ),
      child: LoopAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 2 * pi),
        duration: const Duration(seconds: 20),
        builder: (context, value, child) {
          return Stack(
            children: List.generate(50, (index) {
              final random = Random(index);
              final size = random.nextDouble() * 3;
              final left = random.nextDouble() * MediaQuery.of(context).size.width;
              final top = random.nextDouble() * MediaQuery.of(context).size.height;
              
              return Positioned(
                left: left + sin(value + index) * 10, // Gentle floating movement
                top: top + cos(value + index) * 10,
                child: Opacity(
                  opacity: random.nextDouble(),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.white, blurRadius: 5, spreadRadius: 1)
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}