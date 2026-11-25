import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/student_api_service.dart';
import '../services/student_auth_service.dart';
import '../validation/input_validators.dart';

class StudentLoginScreen extends StatefulWidget {
  StudentLoginScreen({super.key, StudentAuthService? authService})
      : authService = authService ?? StudentAuthService.instance;

  final StudentAuthService authService;

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isBusy = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final restored = await widget.authService.restoreSession();
      if (!mounted) return;
      if (restored) {
        _openDashboard();
      } else {
        setState(() => _isBusy = false);
      }
    } on StudentApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _errorMessage = error.message;
      });
    } on PlatformException {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _errorMessage = 'The saved student session could not be checked.';
      });
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _errorMessage = 'Secure session storage is unavailable on this device.';
      });
    }
  }

  Future<void> _submitLogin() async {
    if (_isBusy || !_formKey.currentState!.validate()) return;

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      await widget.authService.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      _passwordController.clear();
      if (mounted) _openDashboard();
    } on StudentApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _errorMessage = error.message;
      });
    } on StudentAuthorizationException catch (error) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _errorMessage = error.toString();
      });
    } on PlatformException {
      if (!mounted) return;
      _passwordController.clear();
      setState(() {
        _isBusy = false;
        _errorMessage = 'Secure sign-in could not be completed on this device.';
      });
    } on MissingPluginException {
      if (!mounted) return;
      _passwordController.clear();
      setState(() {
        _isBusy = false;
        _errorMessage = 'Secure session storage is unavailable on this device.';
      });
    }
  }

  void _openDashboard() {
    Navigator.of(context).pushReplacementNamed('/student-dashboard');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF062B5C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF073B78),
        foregroundColor: Colors.white,
        title: const Text(
          'Student Login',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
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
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.97),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.school_rounded,
                          color: Color(0xFF0755A0),
                          size: 52,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Student Portal access',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF073B78),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (_errorMessage != null) ...[
                          _StudentLoginError(message: _errorMessage!),
                          const SizedBox(height: 14),
                        ],
                        if (_isBusy)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 28),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _usernameController,
                                  keyboardType: TextInputType.text,
                                  autofillHints: const [AutofillHints.username],
                                  textInputAction: TextInputAction.next,
                                  decoration: _studentInputDecoration(
                                    label: 'Username',
                                    icon: Icons.person_outline_rounded,
                                  ),
                                  validator: (value) =>
                                      InputValidators.requiredText(
                                    value,
                                    'Student Portal username',
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  autofillHints: const [AutofillHints.password],
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submitLogin(),
                                  decoration: _studentInputDecoration(
                                    label: 'Password',
                                    icon: Icons.lock_outline_rounded,
                                  ),
                                  validator: InputValidators.loginPassword,
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  height: 50,
                                  child: FilledButton(
                                    onPressed: _submitLogin,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF0755A0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text(
                                      'Sign in',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _isBusy
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Back to login options'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _studentInputDecoration({
  required String label,
  required IconData icon,
}) =>
    InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF4F7FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD8E1EC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0755A0), width: 1.5),
      ),
    );

class _StudentLoginError extends StatelessWidget {
  const _StudentLoginError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEF9A9A)),
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: Color(0xFF9B1C1C),
            height: 1.4,
          ),
        ),
      );
}
