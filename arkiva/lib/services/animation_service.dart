import 'package:flutter/material.dart';

class AnimationService {
  static const Duration _defaultDuration = Duration(milliseconds: 300);
  static const Curve _defaultCurve = Curves.easeInOut;

  // Animation de transition de page
  static PageRouteBuilder<T> fadeTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: _defaultDuration,
    );
  }

  // Animation de transition de page avec slide
  static PageRouteBuilder<T> slideTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: _defaultDuration,
    );
  }

  // Animation de scale pour les boutons
  static Widget scaleOnTap({
    required Widget child,
    required VoidCallback onTap,
    double scale = 0.95,
  }) {
    return GestureDetector(
      onTapDown: (_) => onTap(),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: scale),
        duration: _defaultDuration,
        curve: _defaultCurve,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: child,
      ),
    );
  }

  // Animation de rebond pour les notifications
  static Widget bounceAnimation({
    required Widget child,
    required bool isVisible,
  }) {
    return AnimatedContainer(
      duration: _defaultDuration,
      curve: _defaultCurve,
      transform: Matrix4.identity()
        ..translate(0.0, isVisible ? 0.0 : -100.0)
        ..scale(isVisible ? 1.0 : 0.8),
      child: child,
    );
  }

  // Animation de chargement personnalisée
  static Widget loadingAnimation({
    Color? color,
    double size = 24.0,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Colors.blue,
        ),
      ),
    );
  }

  // Animation de transition pour les listes
  static Widget listItemAnimation({
    required Widget child,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: _defaultCurve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0.0, 50.0 * (1.0 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // Animation de transition pour les cartes
  static Widget cardAnimation({
    required Widget child,
    required bool isSelected,
  }) {
    return AnimatedContainer(
      duration: _defaultDuration,
      curve: _defaultCurve,
      transform: Matrix4.identity()
        ..scale(isSelected ? 1.02 : 1.0),
      child: child,
    );
  }

  // Animation de transition pour les icônes
  static Widget iconAnimation({
    required IconData icon,
    required bool isActive,
    Color? activeColor,
    Color? inactiveColor,
    double size = 24.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isActive ? 1.0 : 0.0),
      duration: _defaultDuration,
      curve: _defaultCurve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (value * 0.2),
          child: Icon(
            icon,
            color: Color.lerp(
              inactiveColor ?? Colors.grey,
              activeColor ?? Colors.blue,
              value,
            ),
            size: size,
          ),
        );
      },
    );
  }
} 