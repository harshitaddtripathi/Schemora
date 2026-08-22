import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherHelper {
  /// Opens a raw URL string using external application, platform default, or in-app webview fallback.
  /// Includes automatic DNS pre-validation to avoid ERR_NAME_NOT_RESOLVED on unreachable subdomains.
  static Future<bool> openUrl(BuildContext context, String rawUrl) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      _showSnackBar(context, 'Invalid scheme URL');
      return false;
    }

    var formattedUrl = trimmed;
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }

    final uri = Uri.parse(formattedUrl);
    var targetUri = uri;
    bool isDnsFailed = false;

    // Fast DNS pre-check to catch ERR_NAME_NOT_RESOLVED before browser launch
    if (uri.hasAuthority && uri.host.isNotEmpty) {
      try {
        final addresses = await InternetAddress.lookup(uri.host)
            .timeout(const Duration(milliseconds: 1200));
        if (addresses.isEmpty || addresses.first.rawAddress.isEmpty) {
          isDnsFailed = true;
        }
      } catch (_) {
        // DNS lookup failed (ERR_NAME_NOT_RESOLVED)
        isDnsFailed = true;
      }
    }

    if (isDnsFailed) {
      // Determine domain-specific fallback portal
      String fallbackUrl = 'https://www.india.gov.in/';
      final host = uri.host.toLowerCase();
      if (host.contains('maharashtra.gov.in')) {
        fallbackUrl = 'https://www.maharashtra.gov.in/';
      } else if (host.contains('karnataka.gov.in')) {
        fallbackUrl = 'https://www.karnataka.gov.in/';
      } else if (host.contains('up.gov.in')) {
        fallbackUrl = 'https://up.gov.in/';
      } else if (host.contains('guj.nic.in') || host.contains('gujarat.gov.in')) {
        fallbackUrl = 'https://gujaratindia.gov.in/';
      }

      targetUri = Uri.parse(fallbackUrl);
      if (context.mounted) {
        _showSnackBar(
          context,
          'Scheme portal server is currently offline. Redirecting to official State directory...',
        );
      }
    }

    try {
      // 1. Try external application (native browser / app)
      if (await canLaunchUrl(targetUri)) {
        final launched = await launchUrl(targetUri, mode: LaunchMode.externalApplication);
        if (launched) return true;
      }

      // 2. Try platform default mode
      final launchedPlatform = await launchUrl(targetUri, mode: LaunchMode.platformDefault);
      if (launchedPlatform) return true;

      // 3. Try in-app web view mode fallback
      final launchedInApp = await launchUrl(targetUri, mode: LaunchMode.inAppBrowserView);
      if (launchedInApp) return true;

      if (context.mounted) {
        _showSnackBar(context, 'Could not open portal link: $targetUri');
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Unable to open link. Please verify browser availability.');
      }
      return false;
    }
  }

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
