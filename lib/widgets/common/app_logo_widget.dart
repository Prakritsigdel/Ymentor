import 'package:flutter/material.dart';

class AppLogoWidget extends StatelessWidget {
  const AppLogoWidget({super.key, this.height = 72.0});

  final double height;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/images/app_logo.png',
        height: height,
        width: height,
        fit: BoxFit.contain,
        semanticLabel: 'Ymentor logo',
        errorBuilder: (context, error, stackTrace) => SizedBox(
          height: height,
          width: height,
          child: const Icon(Icons.image_not_supported_outlined),
        ),
      );
}
