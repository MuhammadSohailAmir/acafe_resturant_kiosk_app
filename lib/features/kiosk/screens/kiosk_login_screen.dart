import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:acafe_customer/common/models/response_model.dart';
import 'package:acafe_customer/features/kiosk/providers/kiosk_auth_provider.dart';
import 'package:acafe_customer/helper/kiosk_login_permissions_helper.dart';
import 'package:acafe_customer/helper/router_helper.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/theme/brand_colors.dart';
import 'package:acafe_customer/utill/app_constants.dart';
import 'package:provider/provider.dart';

/// One-time device login for the kiosk. After a successful login the token and
/// bound branch are persisted and the kiosk goes to the Intro screen; it will
/// never show this screen again until the device is revoked/inactive.
class KioskLoginScreen extends StatefulWidget {
  const KioskLoginScreen({super.key});

  @override
  State<KioskLoginScreen> createState() => _KioskLoginScreenState();
}

class _KioskLoginScreenState extends State<KioskLoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb) {
        unawaited(KioskLoginPermissionsHelper.requestNativePermissions());
      }
      KioskLoginPermissionsHelper.completeOnLoginScreen(context);
      _redirectIfAlreadyLoggedIn();
    });
  }

  /// Returning kiosk devices skip login when the stored session is still valid.
  Future<void> _redirectIfAlreadyLoggedIn() async {
    final kioskAuth = Provider.of<KioskAuthProvider>(context, listen: false);
    if (!kioskAuth.isLoggedIn()) return;

    final valid = await kioskAuth.validateSession();
    if (!mounted) return;
    if (valid) {
      RouterHelper.getKioskWelcomeRoute(action: RouteAction.pushReplacement);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<KioskAuthProvider>(context, listen: false);
    final ResponseModel response = await provider.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (!mounted) return;
    if (response.isSuccess) {
      RouterHelper.getKioskWelcomeRoute(action: RouteAction.pushNamedAndRemoveUntil);
    }
    // On failure the error is shown inline via the provider's loginError.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Consumer<KioskAuthProvider>(
                builder: (context, provider, _) {
                  return Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          AppConstants.appName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                            color: BrandColors.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          getTranslated('kiosk_device_login', context) ??
                              'Device Login',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: BrandColors.onBackground,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          getTranslated('kiosk_login_hint', context) ??
                              'Sign in once to bind this kiosk to its branch.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: BrandColors.onBackground.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 36),

                        _label(getTranslated('username', context) ?? 'Username'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _usernameController,
                          focusNode: _usernameFocus,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          style: const TextStyle(fontSize: 18),
                          decoration: _fieldDecoration(
                            hint: getTranslated('enter_username', context) ?? 'Enter username',
                            icon: Icons.person_outline,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? getTranslated('username_required', context) ??
                                  'Username is required'
                              : null,
                          onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                        ),
                        const SizedBox(height: 22),

                        _label(getTranslated('password', context) ?? 'Password'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(fontSize: 18),
                          decoration: _fieldDecoration(
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                            suffix: IconButton(
                              icon: Icon(
                                _obscure ? Icons.visibility_off : Icons.visibility,
                                color: BrandColors.onBackground.withValues(alpha: 0.6),
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? getTranslated('password_required', context) ??
                                  'Password is required'
                              : null,
                          onFieldSubmitted: (_) => _submit(),
                        ),

                        if (provider.loginError.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    provider.loginError,
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),
                        SizedBox(
                          height: 60,
                          child: ElevatedButton(
                            onPressed: provider.isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BrandColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: provider.isLoading
                                ? const SizedBox(
                                    height: 26,
                                    width: 26,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: BrandColors.onBackground,
        ),
      );

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: BrandColors.primary),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
            color: BrandColors.onBackground.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: BrandColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.6),
      ),
    );
  }
}
