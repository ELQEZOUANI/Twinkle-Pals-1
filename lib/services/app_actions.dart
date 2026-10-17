import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_brand.dart';

const appStoreUrl = 'https://apps.apple.com/app/id6821077208';

/// Publisher-owned iOS links supplied at build time.
class AppLinks {
  final String publicUrl, iosStoreUrl, privacyUrl, termsUrl;
  const AppLinks({
    this.publicUrl = const String.fromEnvironment('APP_PUBLIC_URL'),
    this.iosStoreUrl = const String.fromEnvironment(
      'APP_STORE_URL_IOS',
      defaultValue: appStoreUrl,
    ),
    this.privacyUrl = const String.fromEnvironment(
      'PRIVACY_POLICY_URL',
      // Blogger's separate mobile template omits this theme's policy content.
      defaultValue: 'https://twinklepals.blogspot.com/2026/10/blog-post.html?m=0',
    ),
    this.termsUrl = const String.fromEnvironment('TERMS_URL'),
  });

  static Uri? publishedUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.host == 'localhost' ||
        uri.host.endsWith('.localhost') ||
        uri.host.endsWith('.local') ||
        uri.host.startsWith('127.') ||
        uri.host == '::1' ||
        uri.host == '[::1]') {
      return null;
    }
    return uri;
  }

  Map<String, Uri> stores() {
    final ios = publishedUrl(iosStoreUrl);
    if (ios == null) return {};
    return {'App Store': ios};
  }

  Uri? shareUrl() => publishedUrl(publicUrl) ?? publishedUrl(iosStoreUrl);

  String shareMessage() {
    const description =
        'Come play $appName! Dress up lovely characters, '
        'help friends, and explore little adventures.';
    final url = shareUrl();
    return url == null ? description : '$description\n$url';
  }
}

class AppActions {
  final AppLinks links;
  const AppActions({this.links = const AppLinks()});

  Future<ShareResult> share(String text, Rect origin) =>
      SharePlus.instance.share(
        ShareParams(
          text: text,
          title: appName,
          subject: 'A little world of $appName',
          sharePositionOrigin: origin,
          downloadFallbackEnabled: false,
        ),
      );

  Future<void> copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  Future<bool> open(Uri url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);
}
