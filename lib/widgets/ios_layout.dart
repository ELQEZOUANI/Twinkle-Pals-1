import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Layouts for iPhone and iPad windows, independent of phone rotation.
/// An iPad's narrow multitasking window uses compact touch controls too.
class IosLayout {
  final Size size;
  const IosLayout(this.size);
  factory IosLayout.of(BuildContext context) =>
      IosLayout(MediaQuery.sizeOf(context));

  bool get isIPad => size.shortestSide >= 600;
  bool get landscape => size.width > size.height;
  int get characterColumns =>
      isIPad ? (landscape ? 6 : 4) : (landscape ? 4 : 2);
  int get adventureColumns =>
      isIPad ? (landscape ? 3 : 2) : (landscape ? 2 : 1);
  int get galleryColumns => isIPad ? (landscape ? 4 : 3) : (landscape ? 4 : 2);

  // Screen cutouts and compact iPhone landscape windows reduce usable width.
  int cardColumns(int preferred, double availableWidth) =>
      math.min(preferred, math.max(1, ((availableWidth + 14) / 139).floor()));

  bool sideBySideStudio(BoxConstraints available) =>
      isIPad && available.maxWidth >= 700 && available.maxHeight >= 420;
}
