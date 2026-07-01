import 'package:flutter/material.dart';
import 'package:acafe_customer/features/category/providers/category_provider.dart';
import 'package:acafe_customer/features/kiosk/domain/kiosk_menu_image_helper.dart';
import 'package:acafe_customer/features/language/providers/localization_provider.dart';
import 'package:acafe_customer/features/splash/providers/splash_provider.dart';
import 'package:acafe_customer/helper/router_helper.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/utill/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

/// First screen of the kiosk app: a full-screen background video with an
/// "ORDER HERE" call to action and a row of language flags at the bottom.
/// There is no login on the kiosk; tapping "ORDER HERE" goes straight to the
/// menu.
///
/// Menu data (categories + products) is prefetched in the background so the
/// menu screen renders instantly when the user taps ORDER HERE.
class KioskWelcomeScreen extends StatefulWidget {
  const KioskWelcomeScreen({super.key});

  @override
  State<KioskWelcomeScreen> createState() => _KioskWelcomeScreenState();
}

class _KioskWelcomeScreenState extends State<KioskWelcomeScreen> {
  static const String _videoAsset = 'assets/video/kiosk_intro.mp4';

  VideoPlayerController? _controller;
  bool _videoReady = false;
  bool _orderLoading = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMenuPrefetch());
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset(_videoAsset);
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _videoReady = true;
      });
    } catch (_) {
      // No video asset bundled (or it failed to load) -> use the fallback
      // background image instead of crashing the kiosk.
      controller.dispose();
      if (mounted) setState(() => _videoReady = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _startMenuPrefetch() {
    if (!mounted) return;
    final locale =
        Provider.of<LocalizationProvider>(context, listen: false).locale.languageCode;
    final categories = Provider.of<CategoryProvider>(context, listen: false);
    final splash = Provider.of<SplashProvider>(context, listen: false);

    categories.warmKioskMenuFromDisk(locale).then((_) {
      if (!mounted) return;
      KioskMenuImageHelper.precacheFromProvider(context, categories, splash);
    });
  }

  void _onSelectLanguage(int index) {
    final language = AppConstants.languages[index];
    Provider.of<LocalizationProvider>(context, listen: false).setLanguage(
      Locale(language.languageCode!, language.countryCode),
      isDataUpdate: false,
    );
    _startMenuPrefetch();
  }

  Future<void> _onOrderNow() async {
    if (_orderLoading) return;
    setState(() => _orderLoading = true);

    final locale =
        Provider.of<LocalizationProvider>(context, listen: false).locale.languageCode;
    final categories = Provider.of<CategoryProvider>(context, listen: false);
    final splash = Provider.of<SplashProvider>(context, listen: false);

    await categories.ensureKioskMenuReady(localeCode: locale);

    if (!mounted) return;
    KioskMenuImageHelper.precacheFromProvider(context, categories, splash);
    setState(() => _orderLoading = false);

    RouterHelper.getKioskMenuRoute(action: RouteAction.pushReplacement);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background: video if available, otherwise a static image.
          _buildBackground(),

          // Subtle dark gradient so the button/flags stay readable.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black54,
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(),
                  _OrderHereButton(
                    loading: _orderLoading,
                    onTap: _onOrderNow,
                  ),
                  const SizedBox(height: 28),
                  _buildLanguageRow(),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    final bool ready = _videoReady && _controller != null;
    // Solid background that matches the video's dark first frame — no default
    // image is ever shown, so there is no poster->video swap/flicker. The video
    // then fades in once initialized and the first frame is ready.
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        AnimatedOpacity(
          opacity: ready ? 1 : 0,
          duration: const Duration(milliseconds: 400),
          child: ready
              ? FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildLanguageRow() {
    final String currentCode =
        Provider.of<LocalizationProvider>(context).locale.languageCode;

    // Always lay the flags out left-to-right so the order stays fixed even
    // when an RTL language (Arabic) flips the app's text direction.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 14,
        runSpacing: 12,
        children: List.generate(AppConstants.languages.length, (index) {
          final language = AppConstants.languages[index];
          final bool selected = language.languageCode == currentCode;
          return _FlagButton(
            imageUrl: language.imageUrl!,
            selected: selected,
            onTap: () => _onSelectLanguage(index),
          );
        }),
      ),
    );
  }
}

class _OrderHereButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _OrderHereButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(40),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: loading ? null : onTap,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white24),
          ),
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  getTranslated('order_here', context) ?? 'ORDER HERE',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                  ),
                ),
        ),
      ),
    );
  }
}

class _FlagButton extends StatelessWidget {
  final String imageUrl;
  final bool selected;
  final VoidCallback onTap;
  const _FlagButton({
    required this.imageUrl,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.white38,
            width: selected ? 3 : 1.5,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 6),
          ],
        ),
        child: ClipOval(
          child: Image.asset(imageUrl, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
