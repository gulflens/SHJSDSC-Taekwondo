import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/blocs/session_cubit.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Parent self-registration. Pushed from the sign-in screen. On success the
/// session becomes authenticated and RoleRouter swaps in the experience shell;
/// a [BlocListener] pops this route so we land there cleanly.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<SessionCubit>().signUp(
          fullName: _name.text.trim(),
          email: _email.text,
          password: _password.text,
        );
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      _email.text.trim().isNotEmpty &&
      _password.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return BlocListener<SessionCubit, SessionState>(
      listenWhen: (prev, curr) =>
          !prev.isAuthenticated && curr.isAuthenticated,
      listener: (context, _) => Navigator.of(context).pop(),
      child: Scaffold(
        appBar: AppBar(title: Text(l.authSignUpTitle)),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: BlocBuilder<SessionCubit, SessionState>(
                  builder: (context, state) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: l.authName,
                            prefixIcon: const Icon(Icons.person_outline),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: l.authEmail,
                            prefixIcon: const Icon(Icons.alternate_email),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _password,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _valid ? _submit() : null,
                          decoration: InputDecoration(
                            labelText: l.authPassword,
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        if (state.authError != null) ...[
                          const SizedBox(height: 12),
                          Text(state.authError!,
                              style: TextStyle(color: AppColors.critical),
                              textAlign: TextAlign.center),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: (state.authenticating || !_valid)
                                ? null
                                : _submit,
                            child: state.authenticating
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Text(l.authSignUp),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
