import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/immich_client.dart';
import '../../core/immich_storage.dart';
import '../../core/supabase_storage.dart';
import '../../l10n/app_localizations.dart';

/// Multi-step onboarding for new users. Collects Immich, Supabase, and creates account.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  // 0 = new account, 1 = family, 2 = existing account (sign in)
  int _accountType = 0;

  // Immich
  final _immichUrlController = TextEditingController();
  final _immichApiKeyController = TextEditingController();

  // Supabase
  final _supabaseUrlController = TextEditingController();
  final _supabaseAnonKeyController = TextEditingController();
  bool _supabaseSchemaOk = false; // true if journal_entries table exists
  bool _showSupabaseMigrationHelp = false;

  // Sign up
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _immichStorage = ImmichStorage();
  final _supabaseStorage = SupabaseStorage();
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _immichUrlController.dispose();
    _immichApiKeyController.dispose();
    _supabaseUrlController.dispose();
    _supabaseAnonKeyController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() {
      _step++;
      _error = null;
    });
  }

  void _prevStep() {
    setState(() {
      _step = (_step - 1).clamp(0, 10);
      _error = null;
      if (_step < 2) {
        _supabaseSchemaOk = false;
        _showSupabaseMigrationHelp = false;
      }
    });
  }

  Future<void> _openPikaPods() async {
    final uri = Uri.parse('https://www.pikapods.com');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _testImmichAndContinue() async {
    final url = _immichUrlController.text.trim();
    final key = _immichApiKeyController.text.trim();
    if (url.isEmpty || key.isEmpty) {
      setState(() => _error = AppLocalizations.of(context)!.enterUrlAndKey);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    final client = ImmichClient(baseUrl: baseUrl, apiKey: key);
    final ok = await client.checkConnection();
    if (mounted) {
      if (ok) {
        await _immichStorage.setServerUrl(url);
        await _immichStorage.setApiKey(key);
        _nextStep();
      } else {
        setState(() => _error = AppLocalizations.of(context)!.connectionFailed);
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _skipImmichAndContinue() async {
    _nextStep();
  }

  Future<void> _testSupabaseConnection() async {
    final url = _supabaseUrlController.text.trim();
    final key = _supabaseAnonKeyController.text.trim();
    if (url.isEmpty || key.isEmpty) {
      setState(() => _error = AppLocalizations.of(context)!.enterUrlAndKey);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _supabaseSchemaOk = false;
      _showSupabaseMigrationHelp = false;
    });
    try {
      final baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
      final client = SupabaseClient(baseUrl, key);
      await client.from('journal_entries').select('id').limit(1).maybeSingle().timeout(
        const Duration(seconds: 10),
      );
      if (mounted) {
        setState(() {
          _supabaseSchemaOk = true;
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.connectedSuccessfully)),
        );
      }
    } on PostgrestException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('relation') && msg.contains('does not exist')) {
        if (mounted) {
          setState(() {
            _supabaseSchemaOk = false;
            _showSupabaseMigrationHelp = true;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = e.message;
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _copySupabaseSetupSql() async {
    try {
      final sql = await rootBundle.loadString('assets/supabase/setup.sql');
      await Clipboard.setData(ClipboardData(text: sql));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.onboardingSqlCopied)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.onboardingSqlCopyFailed)),
        );
      }
    }
  }

  Future<void> _openSupabaseSqlEditor() async {
    final url = _supabaseUrlController.text.trim();
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return;
    final ref = uri.host.split('.').first;
    final dashboardUrl = 'https://supabase.com/dashboard/project/$ref/sql/new';
    final parsed = Uri.tryParse(dashboardUrl);
    if (parsed != null && await canLaunchUrl(parsed)) {
      await launchUrl(parsed, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _saveSupabaseAndContinue() async {
    final url = _supabaseUrlController.text.trim();
    final key = _supabaseAnonKeyController.text.trim();
    if (url.isEmpty || key.isEmpty) {
      setState(() => _error = AppLocalizations.of(context)!.enterUrlAndKey);
      return;
    }
    if (!_supabaseSchemaOk) {
      setState(() => _error = AppLocalizations.of(context)!.onboardingRunMigrationsFirst);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _supabaseStorage.setUrl(url);
      await _supabaseStorage.setAnonKey(key);
      await Supabase.initialize(url: url, anonKey: key);
      if (mounted) {
        if (_accountType == 2) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
        } else {
          _nextStep();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _signUp() async {
    _error = null;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          // Email confirmation disabled — already logged in, go to home
          Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.checkEmailConfirm)),
          );
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.onboardingTitle),
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _loading ? null : _prevStep,
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _buildStep(l10n),
        ),
      ),
    );
  }

  Widget _buildStep(AppLocalizations l10n) {
    if (_step == 0) return _buildAccountTypeStep(l10n);
    if (_accountType == 1) return _buildFamilyComingSoon(l10n);
    if (_accountType == 2) {
      // Existing account: Supabase only, then login
      return _buildSupabaseStep(l10n);
    }
    if (_step == 1) return _buildImmichStep(l10n);
    if (_step == 2) return _buildSupabaseStep(l10n);
    if (_step == 3) return _buildSignUpStep(l10n);
    return _buildAccountTypeStep(l10n);
  }

  Widget _buildAccountTypeStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.onboardingAccountTypeTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 32),
        _AccountTypeCard(
          title: l10n.onboardingNewAccount,
          subtitle: l10n.onboardingNewAccountSubtitle,
          icon: Icons.person_add,
          selected: _accountType == 0,
          onTap: () => setState(() => _accountType = 0),
        ),
        const SizedBox(height: 16),
        _AccountTypeCard(
          title: l10n.onboardingExistingAccount,
          subtitle: l10n.onboardingExistingAccountSubtitle,
          icon: Icons.login,
          selected: _accountType == 2,
          onTap: () => setState(() => _accountType = 2),
        ),
        const SizedBox(height: 16),
        _AccountTypeCard(
          title: l10n.onboardingFamily,
          subtitle: l10n.onboardingFamilySubtitle,
          icon: Icons.family_restroom,
          selected: _accountType == 1,
          onTap: () => setState(() => _accountType = 1),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => _nextStep(),
          child: Text(l10n.onboardingContinue),
        ),
      ],
    );
  }

  Widget _buildFamilyComingSoon(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.info_outline, size: 48, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 24),
        Text(
          l10n.onboardingFamilyComingSoon,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => setState(() => _accountType = 0),
          child: Text(l10n.onboardingNewAccount),
        ),
      ],
    );
  }

  Widget _buildImmichStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.onboardingImmichTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.onboardingImmichQuestion,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _openPikaPods,
          icon: const Icon(Icons.open_in_new),
          label: Text(l10n.onboardingCreateImmich),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.onboardingCreateImmichSubtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _immichUrlController,
          decoration: InputDecoration(
            labelText: l10n.serverUrl,
            hintText: l10n.serverUrlHint,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
          autocorrect: false,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _immichApiKeyController,
          decoration: InputDecoration(
            labelText: l10n.apiKey,
            border: const OutlineInputBorder(),
          ),
          obscureText: true,
          autocorrect: false,
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loading ? null : _testImmichAndContinue,
          child: _loading
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.onboardingTestAndContinue),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _loading ? null : _skipImmichAndContinue,
          child: Text(l10n.onboardingSkipImmich),
        ),
      ],
    );
  }

  Widget _buildSupabaseStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.onboardingSupabaseTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.onboardingSupabaseDescription,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _supabaseUrlController,
          decoration: InputDecoration(
            labelText: l10n.serverUrl,
            hintText: l10n.onboardingSupabaseUrlHint,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
          autocorrect: false,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _supabaseAnonKeyController,
          decoration: InputDecoration(
            labelText: l10n.onboardingAnonKey,
            border: const OutlineInputBorder(),
          ),
          obscureText: true,
          autocorrect: false,
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        if (_supabaseSchemaOk) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.connectedSuccessfully,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ],
        if (_showSupabaseMigrationHelp) ...[
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.onboardingSchemaMissingTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.onboardingSchemaMissingDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _copySupabaseSetupSql,
                    icon: const Icon(Icons.copy),
                    label: Text(l10n.onboardingCopySql),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _openSupabaseSqlEditor,
                    icon: const Icon(Icons.open_in_new),
                    label: Text(l10n.onboardingOpenSupabaseDashboard),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _loading ? null : _testSupabaseConnection,
                    icon: _loading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh),
                    label: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loading ? null : _testSupabaseConnection,
          child: _loading
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.testConnection),
        ),
        if (!_supabaseSchemaOk) ...[
          const SizedBox(height: 8),
          Text(
            l10n.onboardingTestSupabaseFirst,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ] else ...[
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _loading ? null : _saveSupabaseAndContinue,
            child: Text(l10n.onboardingContinue),
          ),
        ],
      ],
    );
  }

  Widget _buildSignUpStep(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.signUpTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.signUpSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: l10n.email,
              hintText: l10n.hintEmail,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            validator: (v) {
              final s = v?.trim() ?? '';
              if (s.isEmpty) return l10n.enterYourEmail;
              if (!s.contains('@') || !s.contains('.')) return l10n.enterValidEmail;
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: l10n.password,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            obscureText: _obscurePassword,
            validator: (v) {
              if (v == null || v.isEmpty) return l10n.choosePassword;
              if (v.length < 6) return l10n.passwordMinLength;
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: l10n.confirmPassword,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            obscureText: _obscureConfirm,
            validator: (v) {
              if (v != _passwordController.text) return l10n.passwordsDoNotMatch;
              return null;
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _signUp,
            child: _loading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.signUp),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _loading ? null : () => Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false),
            child: Text(l10n.alreadyHaveAccount),
          ),
        ],
      ),
    );
  }
}

class _AccountTypeCard extends StatelessWidget {
  const _AccountTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 40, color: selected ? Theme.of(context).colorScheme.primary : null),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
