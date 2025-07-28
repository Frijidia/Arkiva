import 'package:flutter/material.dart';

class ResponsiveService {
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 900;
  static const double _desktopBreakpoint = 1200;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < _mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= _mobileBreakpoint && width < _tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= _desktopBreakpoint;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static double getPadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 24.0;
    return 32.0;
  }

  static double getCardPadding(BuildContext context) {
    if (isMobile(context)) return 12.0;
    if (isTablet(context)) return 16.0;
    return 20.0;
  }

  static double getBorderRadius(BuildContext context) {
    if (isMobile(context)) return 8.0;
    if (isTablet(context)) return 12.0;
    return 16.0;
  }

  static double getIconSize(BuildContext context) {
    if (isMobile(context)) return 20.0;
    if (isTablet(context)) return 24.0;
    return 28.0;
  }

  static double getFontSize(BuildContext context, {double baseSize = 16.0}) {
    if (isMobile(context)) return baseSize;
    if (isTablet(context)) return baseSize * 1.1;
    return baseSize * 1.2;
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    final padding = getPadding(context);
    return EdgeInsets.all(padding);
  }

  static EdgeInsets getHorizontalPadding(BuildContext context) {
    final padding = getPadding(context);
    return EdgeInsets.symmetric(horizontal: padding);
  }

  static EdgeInsets getVerticalPadding(BuildContext context) {
    final padding = getPadding(context);
    return EdgeInsets.symmetric(vertical: padding);
  }

  static double getMaxWidth(BuildContext context) {
    if (isMobile(context)) return double.infinity;
    if (isTablet(context)) return 600;
    return 800;
  }

  static Widget responsiveBuilder({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    }
    if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  static Widget responsiveGrid({
    required BuildContext context,
    required List<Widget> children,
    int mobileCrossAxisCount = 1,
    int tabletCrossAxisCount = 2,
    int desktopCrossAxisCount = 3,
    double childAspectRatio = 1.0,
    double crossAxisSpacing = 16.0,
    double mainAxisSpacing = 16.0,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    int crossAxisCount;
    double aspectRatio;
    double spacing;
    
    if (isMobile(context)) {
      crossAxisCount = mobileCrossAxisCount;
      aspectRatio = childAspectRatio * 0.9;
      spacing = crossAxisSpacing * 0.8;
    } else if (isTablet(context)) {
      crossAxisCount = tabletCrossAxisCount;
      aspectRatio = childAspectRatio * 1.0;
      spacing = crossAxisSpacing * 1.0;
    } else {
      crossAxisCount = desktopCrossAxisCount;
      aspectRatio = childAspectRatio * 1.2;
      spacing = crossAxisSpacing * 1.2;
    }

    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics ?? (shrinkWrap ? NeverScrollableScrollPhysics() : null),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }

  static SliverGridDelegateWithFixedCrossAxisCount getResponsiveGridDelegate(BuildContext context, {
    int mobileCrossAxisCount = 1,
    int tabletCrossAxisCount = 2,
    int desktopCrossAxisCount = 3,
    double childAspectRatio = 1.0,
    double crossAxisSpacing = 16.0,
    double mainAxisSpacing = 16.0,
  }) {
    int crossAxisCount;
    double aspectRatio;
    double spacing;
    
    if (isMobile(context)) {
      crossAxisCount = mobileCrossAxisCount;
      aspectRatio = childAspectRatio * 0.9;
      spacing = crossAxisSpacing * 0.8;
    } else if (isTablet(context)) {
      crossAxisCount = tabletCrossAxisCount;
      aspectRatio = childAspectRatio * 1.0;
      spacing = crossAxisSpacing * 1.0;
    } else {
      crossAxisCount = desktopCrossAxisCount;
      aspectRatio = childAspectRatio * 1.2;
      spacing = crossAxisSpacing * 1.2;
    }

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      childAspectRatio: aspectRatio,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
    );
  }

  static Widget responsiveList({
    required BuildContext context,
    required List<Widget> children,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }

  static Widget responsiveCard({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry? padding,
    double? elevation,
    Color? color,
    ShapeBorder? shape,
  }) {
    return Card(
      elevation: elevation ?? (isMobile(context) ? 2.0 : 4.0),
      shape: shape ?? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(getBorderRadius(context)),
      ),
      color: color,
      child: Padding(
        padding: padding ?? EdgeInsets.all(getCardPadding(context)),
        child: child,
      ),
    );
  }

  static Widget responsiveButton({
    required BuildContext context,
    required VoidCallback? onPressed,
    required Widget child,
    EdgeInsetsGeometry? padding,
    double? height,
    Color? backgroundColor,
    Color? foregroundColor,
    double? borderRadius,
  }) {
    return SizedBox(
      height: height ?? (isMobile(context) ? 48.0 : 56.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: padding ?? EdgeInsets.symmetric(
            horizontal: isMobile(context) ? 16.0 : 24.0,
            vertical: isMobile(context) ? 12.0 : 16.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              borderRadius ?? getBorderRadius(context),
            ),
          ),
        ),
        child: child,
      ),
    );
  }

  static Widget responsiveTextField({
    required BuildContext context,
    required TextEditingController controller,
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(getBorderRadius(context)),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile(context) ? 12.0 : 16.0,
          vertical: isMobile(context) ? 16.0 : 20.0,
        ),
      ),
    );
  }
} 