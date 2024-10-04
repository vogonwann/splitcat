/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: directives_ordering,unnecessary_import,implicit_dynamic_list_literal,deprecated_member_use

import 'package:flutter/widgets.dart';

class $LinuxGen {
  const $LinuxGen();

  /// Directory path: linux/flutter
  $LinuxFlutterGen get flutter => const $LinuxFlutterGen();
}

class $LinuxFlutterGen {
  const $LinuxFlutterGen();

  /// Directory path: linux/flutter/assets
  $LinuxFlutterAssetsGen get assets => const $LinuxFlutterAssetsGen();
}

class $LinuxFlutterAssetsGen {
  const $LinuxFlutterAssetsGen();

  /// Directory path: linux/flutter/assets/icons
  $LinuxFlutterAssetsIconsGen get icons => const $LinuxFlutterAssetsIconsGen();
}

class $LinuxFlutterAssetsIconsGen {
  const $LinuxFlutterAssetsIconsGen();

  /// Directory path: linux/flutter/assets/icons/128x128
  $LinuxFlutterAssetsIcons128x128Gen get a128x128 => const $LinuxFlutterAssetsIcons128x128Gen();

  /// Directory path: linux/flutter/assets/icons/16x16
  $LinuxFlutterAssetsIcons16x16Gen get a16x16 => const $LinuxFlutterAssetsIcons16x16Gen();

  /// Directory path: linux/flutter/assets/icons/256x256
  $LinuxFlutterAssetsIcons256x256Gen get a256x256 => const $LinuxFlutterAssetsIcons256x256Gen();

  /// Directory path: linux/flutter/assets/icons/32x32
  $LinuxFlutterAssetsIcons32x32Gen get a32x32 => const $LinuxFlutterAssetsIcons32x32Gen();

  /// Directory path: linux/flutter/assets/icons/64x64
  $LinuxFlutterAssetsIcons64x64Gen get a64x64 => const $LinuxFlutterAssetsIcons64x64Gen();
}

class $LinuxFlutterAssetsIcons128x128Gen {
  const $LinuxFlutterAssetsIcons128x128Gen();

  /// File path: linux/flutter/assets/icons/128x128/icon.png
  AssetGenImage get icon => const AssetGenImage('linux/flutter/assets/icons/128x128/icon.png');

  /// List of all assets
  List<AssetGenImage> get values => [icon];
}

class $LinuxFlutterAssetsIcons16x16Gen {
  const $LinuxFlutterAssetsIcons16x16Gen();

  /// File path: linux/flutter/assets/icons/16x16/icon.png
  AssetGenImage get icon => const AssetGenImage('linux/flutter/assets/icons/16x16/icon.png');

  /// List of all assets
  List<AssetGenImage> get values => [icon];
}

class $LinuxFlutterAssetsIcons256x256Gen {
  const $LinuxFlutterAssetsIcons256x256Gen();

  /// File path: linux/flutter/assets/icons/256x256/icon.png
  AssetGenImage get icon => const AssetGenImage('linux/flutter/assets/icons/256x256/icon.png');

  /// List of all assets
  List<AssetGenImage> get values => [icon];
}

class $LinuxFlutterAssetsIcons32x32Gen {
  const $LinuxFlutterAssetsIcons32x32Gen();

  /// File path: linux/flutter/assets/icons/32x32/icon.png
  AssetGenImage get icon => const AssetGenImage('linux/flutter/assets/icons/32x32/icon.png');

  /// List of all assets
  List<AssetGenImage> get values => [icon];
}

class $LinuxFlutterAssetsIcons64x64Gen {
  const $LinuxFlutterAssetsIcons64x64Gen();

  /// File path: linux/flutter/assets/icons/64x64/icon.png
  AssetGenImage get icon => const AssetGenImage('linux/flutter/assets/icons/64x64/icon.png');

  /// List of all assets
  List<AssetGenImage> get values => [icon];
}

class Assets {
  Assets._();

  static const $LinuxGen linux = $LinuxGen();
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
  });

  final String _assetName;

  final Size? size;
  final Set<String> flavors;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = false,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.low,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({
    AssetBundle? bundle,
    String? package,
  }) {
    return AssetImage(
      _assetName,
      bundle: bundle,
      package: package,
    );
  }

  String get path => _assetName;

  String get keyName => _assetName;
}
