import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/config/app_config.dart';
import 'package:al_wahat_farm_flutter/core/supabase/auth_repository.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.config, super.key});

  final AppConfig config;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !widget.config.isConfigured) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await AuthRepository(
        Supabase.instance.client,
      ).signIn(email: _email.text.trim(), password: _password.text);
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to sign in. Check your connection.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: PaperBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Center(
                        child: Icon(
                          Icons.park_outlined,
                          size: 54,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(child: Eyebrow('Farm operations')),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome to\nAl Wahat.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: 28),
                      WahatCard(
                        padding: const EdgeInsets.all(22),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Text(
                                'Sign in',
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 6),
                              const Text('Use your farm operations account.'),
                              const SizedBox(height: 20),
                              TextFormField(
                                key: const Key('login-email'),
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const <String>[
                                  AutofillHints.email
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                ),
                                validator: (value) =>
                                    value == null || !value.contains('@')
                                        ? 'Enter a valid email address'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                key: const Key('login-password'),
                                controller: _password,
                                obscureText: true,
                                autofillHints: const <String>[
                                  AutofillHints.password,
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                        ? 'Password is required'
                                        : null,
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              if (_error != null) ...<Widget>[
                                const SizedBox(height: 12),
                                Text(
                                  _error!,
                                  style:
                                      const TextStyle(color: AppColors.issue),
                                ),
                              ],
                              if (!widget.config.isConfigured) ...<Widget>[
                                const SizedBox(height: 12),
                                const Text(
                                  'Supabase is not configured. Run with '
                                  '--dart-define-from-file=config.json.',
                                  style: TextStyle(color: AppColors.issue),
                                ),
                              ],
                              const SizedBox(height: 18),
                              FilledButton(
                                key: const Key('login-submit'),
                                onPressed:
                                    _submitting || !widget.config.isConfigured
                                        ? null
                                        : _submit,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                ),
                                child: _submitting
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Sign in'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
