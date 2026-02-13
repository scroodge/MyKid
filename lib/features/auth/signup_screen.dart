import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import '../../core/immich_storage.dart';
import '../../core/supabase_storage.dart';
import '../../l10n/app_localizations.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Future<void> _signUp() async {
    _error = null;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      // Get invite token from route arguments
      final inviteToken = ModalRoute.of(context)?.settings.arguments as String?;
      
      // Use Edge Function for email confirmation redirect
      // It will detect mobile device and redirect to deep link, or show instructions for desktop
      final config = await AppConfig.load();
      var redirectUrl = '${config.supabaseUrl}/functions/v1/auth-confirm';
      if (inviteToken != null) {
        redirectUrl += '?invite_token=$inviteToken';
      }
      
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        emailRedirectTo: redirectUrl,
      );
      
      if (mounted) {
        if (inviteToken != null) {
          // Save invite token for after email confirmation
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('pending_invite_token', inviteToken);
        }
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          // Email confirmation disabled — already logged in, go to home
          Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.checkEmailConfirm)),
          );
          Navigator.of(context).pop(true);
        }
      }
    } on AuthException catch (e) {
      final msg = e.message;
      setState(() => _error = msg.contains('anonymous') || msg.contains('disabled')
          ? AppLocalizations.of(context)!.signUpDisabled
          : msg);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startFromScratch() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.startFromScratchConfirm),
        content: Text(AppLocalizations.of(context)!.startFromScratchConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context)!.startFromScratch),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await SupabaseStorage().clear();
    await ImmichStorage().clear();
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    if (mounted) {
      SystemNavigator.pop();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.createAccount),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.signUpTitle,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.signUpSubtitle,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.email,
                    hintText: AppLocalizations.of(context)!.hintEmail,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return AppLocalizations.of(context)!.enterYourEmail;
                    if (!s.contains('@') || !s.contains('.')) return AppLocalizations.of(context)!.enterValidEmail;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.password,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (v) {
                    final l10n = AppLocalizations.of(context)!;
                    if (v == null || v.isEmpty) return l10n.choosePassword;
                    if (v.length < 6) return l10n.passwordMinLength;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.confirmPassword,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  obscureText: _obscureConfirm,
                  validator: (v) {
                    if (v != _passwordController.text) return AppLocalizations.of(context)!.passwordsDoNotMatch;
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _signUp,
                  child: _loading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(AppLocalizations.of(context)!.signUp),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _loading ? null : () => Navigator.of(context).pushReplacementNamed('/login'),
                  child: Text(AppLocalizations.of(context)!.alreadyHaveAccount),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _loading ? null : _startFromScratch,
                  child: Text(
                    AppLocalizations.of(context)!.startFromScratch,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
