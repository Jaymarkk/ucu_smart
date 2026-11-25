import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/student_api_service.dart';
import '../services/student_auth_service.dart';
import '../validation/input_validators.dart';

class UnifiedLoginScreen extends StatefulWidget {
  const UnifiedLoginScreen({
    required this.studentAuthService,
    this.onStudentAuthenticated,
    super.key,
  });

  final StudentAuthService studentAuthService;
  final Future<void> Function()? onStudentAuthenticated;

  @override
  State<UnifiedLoginScreen> createState() => _UnifiedLoginScreenState();
}

class _UnifiedLoginScreenState extends State<UnifiedLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isBusy = true;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _restoreSessions();
  }

  Future<void> _restoreSessions() async {
    bool studentRestored = false;
    Object? restoreError;

    try {
      studentRestored = await widget.studentAuthService.restoreSession();
    } on StudentApiException catch (error) {
      restoreError = error;
    } on PlatformException {
      restoreError = 'A saved account session could not be checked.';
    } on MissingPluginException {
      restoreError = 'Secure session storage is unavailable on this device.';
    }

    if (!mounted) return;
    if (studentRestored) {
      await _continueAsStudent();
      return;
    }

    setState(() {
      _isBusy = false;
      _errorMessage = restoreError == null
          ? null
          : 'A saved session could not be checked. Please try logging in.';
    });
  }

  Future<void> _submitLogin() async {
    if (_isBusy || !_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      await widget.studentAuthService.login(
        username: username,
        password: password,
      );
      _passwordController.clear();
      if (mounted) await _continueAsStudent();
    } on StudentApiException catch (studentError) {
      _showError(
        studentError.statusCode == 401
            ? 'Invalid username or password.'
            : studentError.message,
      );
    } on StudentAuthorizationException catch (error) {
      _showError(error.toString());
    } on PlatformException {
      _passwordController.clear();
      _showError('Secure sign-in could not be completed on this device.');
    } on MissingPluginException {
      _passwordController.clear();
      _showError('Secure session storage is unavailable on this device.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _isBusy = false;
      _errorMessage = message;
    });
  }

  void _openStudentDashboard() {
    Navigator.of(context).pushReplacementNamed('/student-dashboard');
  }

  Future<void> _continueAsStudent() async {
    final onStudentAuthenticated = widget.onStudentAuthenticated;
    if (onStudentAuthenticated == null) {
      _openStudentDashboard();
    } else {
      await onStudentAuthenticated();
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF062B5C),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xD9062B5C),
                    Color(0xB3073B78),
                    Color(0xF2061835),
                  ],
                  stops: [0, 0.5, 1],
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 440;
                  return Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(compact ? 20 : 28),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Container(
                          padding: EdgeInsets.all(compact ? 24 : 32),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.98),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x44061835),
                                blurRadius: 28,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Welcome!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF0E2958),
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Please log in to your access account.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                if (_errorMessage != null) ...[
                                  _LoginError(message: _errorMessage!),
                                  const SizedBox(height: 16),
                                ],
                                if (_isBusy)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 28),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                else ...[
                                  TextFormField(
                                    controller: _usernameController,
                                    keyboardType: TextInputType.text,
                                    autofillHints: const [
                                      AutofillHints.username,
                                    ],
                                    textInputAction: TextInputAction.next,
                                    decoration: _inputDecoration(
                                      label: 'Username',
                                      icon: Icons.person_outline_rounded,
                                    ),
                                    validator: (value) =>
                                        InputValidators.requiredText(
                                          value,
                                          'Username',
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _submitLogin(),
                                    decoration: _inputDecoration(
                                      label: 'Password',
                                      icon: Icons.lock_outline_rounded,
                                    ).copyWith(
                                      suffixIcon: IconButton(
                                        tooltip: _obscurePassword
                                            ? 'Show password'
                                            : 'Hide password',
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                    validator:
                                        InputValidators.loginPassword,
                                  ),
                                  const SizedBox(height: 22),
                                  SizedBox(
                                    height: 52,
                                    child: FilledButton(
                                      onPressed: _submitLogin,
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF0E4C6B),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(13),
                                        ),
                                      ),
                                      child: const Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF0E4C6B)),
        filled: true,
        fillColor: const Color(0xFFF7F9FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFDCE4ED)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFDCE4ED)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFF0E4C6B), width: 1.5),
        ),
      );
}

class _LoginError extends StatelessWidget {
  const _LoginError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEEEE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7B8B8)),
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: Color(0xFF8B2424),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      );
}
