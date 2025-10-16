import 'package:flutter/material.dart';

class MetartPayColors {
  // Official MetartPay brand colors
  // Official app theme color updated to #c62b14
  static const Color primary = Color(0xFFC62B14);      // Main brand color (updated)
  static const Color secondary = Color(0xFFf79816);    // Orange accent (kept)
  static const Color tertiary = Color(0xFFe05414);     // Red accent (kept)
  // Darker primary used for selected borders/highlights
  static const Color primaryDark = Color(0xFF9E2410);
  // Border color (60% opacity of primary)
  // Avoid deprecated withOpacity use for analyzer; construct color with RGBA
  static Color primaryBorder60 = const Color.fromRGBO(198, 43, 20, 0.6);
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFF79A3A), Color(0xFFE05414), Color(0xFFC62B14)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient lightGradient = LinearGradient(
    colors: [Color(0xFFFFB869), Color(0xFFE05414)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFFE05414), Color(0xFF9E2410)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class MetartPayLogo extends StatelessWidget {
  final double height;
  final bool isDarkBackground;
  final Color? color;

  const MetartPayLogo({
    super.key,
    this.height = 40,
    this.isDarkBackground = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final asset = isDarkBackground ? 'assets/icons/app_logo white.png' : 'assets/icons/app_logo black.png';
    return Image.asset(
      asset,
      height: height,
      color: color,
      colorBlendMode: color != null ? BlendMode.srcIn : null,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to text logo if image fails
        return Text(
          'MetartPay',
          style: TextStyle(
            fontSize: height * 0.6,
            fontWeight: FontWeight.bold,
            color: isDarkBackground ? Colors.white : MetartPayColors.primary,
          ),
        );
      },
    );
  }
}

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showLogo;
  final bool plainWhiteBackground;
  final VoidCallback? onLogoTap;
  final PreferredSizeWidget? bottom;

  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showLogo = false,
    this.plainWhiteBackground = false,
    this.onLogoTap,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: plainWhiteBackground
          ? const BoxDecoration(color: Colors.white)
          : const BoxDecoration(gradient: MetartPayColors.primaryGradient),
      child: AppBar(
        // When `showLogo` is true we only render the app icon (black PNG suited
        // for the gradient background) and omit the textual label as requested.
        title: showLogo
            ? GestureDetector(
                onTap: onLogoTap,
                child: MetartPayLogo(
                  height: 56,
                  // Per UI instruction: when the header is plain white, use the
                  // white logo asset. When the header uses gradient, use the
                  // black logo variant so it contrasts with the gradient.
                  isDarkBackground: plainWhiteBackground ? true : false,
                ),
              )
            : Text(
                title,
                style: TextStyle(
                  color: plainWhiteBackground ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
        // Align title/logo to the left for a compact header layout
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: leading,
        actions: actions?.map((action) {
          // When on a plain white background action icons should be black
          if (action is IconButton) {
            return IconButton(
              onPressed: action.onPressed,
              icon: action.icon,
              color: plainWhiteBackground ? Colors.black : Colors.white,
            );
          }
          return action;
        }).toList(),
        iconTheme: IconThemeData(color: plainWhiteBackground ? Colors.black : Colors.white),
        bottom: bottom,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );
}

class GradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Gradient? gradient;

  const GradientCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient ?? MetartPayColors.lightGradient,
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
        boxShadow: [
          BoxShadow(
            color: MetartPayColors.primary.withAlpha((0.2 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class MetartPayButton extends StatelessWidget {
  final String? text;
  final Widget? child;
  final VoidCallback? onPressed;
  final bool isGradient;
  final bool isOutlined;
  final IconData? icon;
  final double? width;
  final double? height;

  const MetartPayButton({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.isGradient = false,
    this.isOutlined = false,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    Widget buttonContent = child ?? Text(text ?? '');
    
    if (isOutlined) {
      return SizedBox(
        width: width,
        height: height ?? 48,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: MetartPayColors.primary, width: 2),
            foregroundColor: MetartPayColors.primary,
          ),
          child: icon != null 
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon),
                  const SizedBox(width: 8),
                  Flexible(child: buttonContent),
                ],
              )
            : buttonContent,
        ),
      );
    }

    if (!isGradient) {
      return SizedBox(
        width: width,
        height: height ?? 48,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: MetartPayColors.primary,
            foregroundColor: Colors.white,
          ),
          child: icon != null 
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 8),
                  Flexible(child: buttonContent),
                ],
              )
            : buttonContent,
        ),
      );
    }

    return Container(
      width: width,
      height: height ?? 48,
      decoration: BoxDecoration(
        gradient: MetartPayColors.primaryGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: icon != null 
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Flexible(child: buttonContent),
              ],
            )
          : buttonContent,
      ),
    );
  }
}