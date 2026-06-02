import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;

  const AppLogo({
    super.key,
    this.width,
    this.height,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Image.asset(
        'assets/images/logo.png',
        width: width ?? 120,
        height: height ?? 120,
        fit: BoxFit.contain,
      ),
    );
  }
}
