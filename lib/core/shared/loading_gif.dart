import 'package:flutter/material.dart';

class LoadingGif extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit fit;

  const LoadingGif({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/loader.gif',
      width: width,
      height: height,
      fit: fit,
    );
  }
}
