import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Ad configuration, isolated from business logic.
///
/// These are Google's official TEST ids. Replace them with the owner's real
/// AdMob ids (and the matching APP ID in AndroidManifest.xml) before release.
/// Never commit invented production ids.
class AdConfig {
  AdConfig._();

  /// Official Google sample banner unit (Android).
  static const String bannerUnitId = 'ca-app-pub-3940256099942544/6300978111';
}

/// Initialises the Mobile Ads SDK after consent (Google UMP). Every failure
/// is swallowed: the app must stay fully usable without ads.
class AdService extends ChangeNotifier {
  AdService({this.enabled = true});

  /// False in tests / unsupported platforms.
  final bool enabled;

  bool _ready = false;
  bool get ready => enabled && _ready;

  Future<void> init() async {
    if (!enabled || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _runConsentFlow();
      if (await ConsentInformation.instance.canRequestAds()) {
        await MobileAds.instance.initialize();
        _ready = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Ads unavailable: $e');
    }
  }

  /// Entry point for the "Privacy options" row in Settings.
  Future<bool> privacyOptionsRequired() async {
    if (!enabled) return false;
    try {
      return await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  Future<void> showPrivacyOptions() async {
    try {
      await ConsentForm.showPrivacyOptionsForm((_) {});
    } catch (_) {}
  }
}

/// Requests consent info and shows the UMP form when required. Completes
/// (never throws) once the flow finished or failed.
Future<void> _runConsentFlow() {
  final done = Completer<void>();
  void finish() {
    if (!done.isCompleted) done.complete();
  }

  ConsentInformation.instance.requestConsentInfoUpdate(
    ConsentRequestParameters(),
    () => ConsentForm.loadAndShowConsentFormIfRequired((_) => finish()),
    (_) => finish(),
  );
  return done.future;
}

/// Adaptive-size banner that renders nothing until an ad has loaded and never
/// throws. Place only away from number-entry controls.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key, required this.service});
  final AdService service;

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    widget.service.addListener(_maybeLoad);
    _maybeLoad();
  }

  void _maybeLoad() {
    if (_ad != null || !widget.service.ready) return;
    final ad = BannerAd(
      adUnitId: AdConfig.bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _ad = null;
              _loaded = false;
            });
          }
        },
      ),
    );
    _ad = ad;
    try {
      ad.load();
    } catch (_) {
      _ad = null;
    }
  }

  @override
  void dispose() {
    widget.service.removeListener(_maybeLoad);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return Semantics(
      label: 'Iklan',
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
