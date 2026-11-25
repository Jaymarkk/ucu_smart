import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    required this.destinationBuilder,
    required this.loginBuilder,
    this.onVisitorTap,
    super.key,
  });

  final WidgetBuilder destinationBuilder;
  final WidgetBuilder loginBuilder;
  final VoidCallback? onVisitorTap;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleFade;
  late final Animation<double> _taglineFade;
  late final Animation<double> _progress;
  bool _showEntryOptions = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _logoFade = _curve(0.0, 0.34);
    _logoScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.42, curve: Curves.easeOutCubic),
      ),
    );
    _titleFade = _curve(0.16, 0.55);
    _taglineFade = _curve(0.32, 0.72);
    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.28, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    _controller.forward().then((_) {
      if (mounted) {
        setState(() => _showEntryOptions = true);
      }
    });
  }

  void _openVisitorCampusMap() {
    final onVisitorTap = widget.onVisitorTap;
    if (onVisitorTap != null) {
      onVisitorTap();
      return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: '/campus-map'),
        pageBuilder: (context, __, ___) => widget.destinationBuilder(context),
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _openLogin() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/login'),
        builder: widget.loginBuilder,
      ),
    );
  }

  Animation<double> _curve(double start, double end) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 700;
                final logoWidth = _showEntryOptions && compact
                    ? 118.0
                    : (constraints.maxWidth * 0.38).clamp(118.0, 174.0);

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 22 : 28,
                    vertical: compact ? 12 : 22,
                  ),
                  child: _showEntryOptions
                      ? SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight:
                                  constraints.maxHeight - (compact ? 24 : 44),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FadeTransition(
                                    opacity: _logoFade,
                                    child: ScaleTransition(
                                      scale: _logoScale,
                                      child: Image.asset(
                                        'assets/images/logo.png',
                                        width: logoWidth,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: compact ? 8 : 14),
                                  FadeTransition(
                                    opacity: _titleFade,
                                    child: const _BrandName(),
                                  ),
                                  const SizedBox(height: 8),
                                  FadeTransition(
                                    opacity: _titleFade,
                                    child: const _Subtitle(),
                                  ),
                                  SizedBox(height: compact ? 16 : 28),
                                  _EntryOptions(
                                    onVisitorTap: _openVisitorCampusMap,
                                    onLoginTap: _openLogin,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight:
                                  constraints.maxHeight - (compact ? 24 : 44),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FadeTransition(
                                    opacity: _logoFade,
                                    child: ScaleTransition(
                                      scale: _logoScale,
                                      child: Image.asset(
                                        'assets/images/logo.png',
                                        width: logoWidth,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: compact ? 10 : 14),
                                  FadeTransition(
                                    opacity: _titleFade,
                                    child: const _BrandName(),
                                  ),
                                  const SizedBox(height: 8),
                                  FadeTransition(
                                    opacity: _titleFade,
                                    child: const _Subtitle(),
                                  ),
                                  SizedBox(height: compact ? 28 : 44),
                                  FadeTransition(
                                    opacity: _taglineFade,
                                    child: const _Tagline(),
                                  ),
                                  SizedBox(height: compact ? 28 : 44),
                                  AnimatedBuilder(
                                    animation: _progress,
                                    builder: (context, child) {
                                      return _LoadingProgress(
                                        value: _progress.value,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Initializing your campus experience...',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
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
  }
}

class _EntryOptions extends StatelessWidget {
  const _EntryOptions({
    required this.onVisitorTap,
    required this.onLoginTap,
  });

  final VoidCallback onVisitorTap;
  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('entry-options'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: onVisitorTap,
            icon: const Icon(Icons.map_rounded),
            label: const Text('Continue as Visitor'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF073B78),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: onLoginTap,
            icon: const Icon(Icons.login_rounded),
            label: const Text('Login'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFB8C9DE)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandName extends StatelessWidget {
  const _BrandName();

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          height: 1.0,
        ),
        children: [
          TextSpan(
            text: 'UCU ',
            style: TextStyle(color: Color(0xFFFFC107)),
          ),
          TextSpan(
            text: 'SMART',
            style: TextStyle(color: Colors.white),
          ),
          TextSpan(
            text: '+',
            style: TextStyle(color: Color(0xFFFFC107)),
          ),
        ],
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        style: TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
        ),
        children: [
          TextSpan(text: 'EXPLORE '),
          TextSpan(text: '•', style: TextStyle(color: Color(0xFFFFC107))),
          TextSpan(text: ' NAVIGATE '),
          TextSpan(text: '•', style: TextStyle(color: Color(0xFFFFC107))),
          TextSpan(text: ' CONNECT'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Explore\nLearn\nBelong',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w300,
            height: 1.18,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 13),
        CustomPaint(
          size: const Size(92, 12),
          painter: _GoldAccentPainter(),
        ),
      ],
    );
  }
}

class _GoldAccentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.58)
      ..quadraticBezierTo(
        size.width * 0.5,
        -size.height * 0.2,
        size.width,
        size.height * 0.48,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFC107)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LoadingProgress extends StatelessWidget {
  const _LoadingProgress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: SizedBox(
        height: 7,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: const Color(0x664F7099),
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color(0xFFFFC107),
            ),
          ),
        ),
      ),
    );
  }
}
