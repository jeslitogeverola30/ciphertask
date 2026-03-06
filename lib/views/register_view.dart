import 'dart:async'; // Required for Timer
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/auth_viewmodel.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _showOtpField = false;
  bool _isSendingOtp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _passwordsMatch = false;

  // Resend OTP Logic
  Timer? _timer;
  int _start = 60;
  bool _canResend = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const Color zinc950 = Color(0xFF09090b);
  static const Color zinc900 = Color(0xFF18181b);
  static const Color zinc800 = Color(0xFF27272a);
  static const Color zinc400 = Color(0xFFa1a1aa);
  static const Color zinc100 = Color(0xFFf4f4f5);
  static const Color emerald500 = Color(0xFF10b981);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validatePassword);
  }

  void _validatePassword() {
    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    setState(() {
      _hasMinLength = pass.length >= 8;
      _hasUppercase = pass.contains(RegExp(r'[A-Z]'));
      _hasNumber = pass.contains(RegExp(r'[0-9]'));
      _passwordsMatch = pass.isNotEmpty && pass == confirm;
    });
  }

  void _startTimer() {
    _canResend = false;
    _start = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _canResend = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _passwordController.removeListener(_validatePassword);
    _confirmPasswordController.removeListener(_validatePassword);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _showLocalNotification(String code) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 160,
          left: 16,
          right: 16,
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: zinc900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: zinc800, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.mark_email_unread_rounded, color: zinc100),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Security Service',
                      style: TextStyle(
                        color: zinc400,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Your verification code is: $code',
                      style: const TextStyle(color: zinc100, fontSize: 13),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  _otpController.text = code;
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                child: const Text(
                  'AUTOFILL',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleInitialRegistration(AuthViewModel auth) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasMinLength || !_hasUppercase || !_hasNumber || !_passwordsMatch)
      return;

    setState(() => _isSendingOtp = true);
    bool sent = await auth.sendOtp(_emailController.text.trim());
    if (mounted) {
      setState(() {
        _isSendingOtp = false;
        if (sent) {
          _showOtpField = true;
          _startTimer();
          _showLocalNotification(auth.simulatedOtp ?? "");
        }
      });
    }
  }

  Future<void> _verifyAndComplete(AuthViewModel auth) async {
    if (_otpController.text.length < 6) return;
    setState(() => _isLoading = true);
    final scaffold = ScaffoldMessenger.of(context);
    bool isValid = auth.verifyOtp(_otpController.text.trim());
    if (isValid) {
      bool success = await auth.register(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (success && mounted) {
        Navigator.of(context).pop();
        scaffold.showSnackBar(
          const SnackBar(
            content: Text('Account verified! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      scaffold.showSnackBar(
        const SnackBar(
          content: Text('Invalid OTP code.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  InputDecoration _fieldStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: zinc400, fontSize: 14),
      prefixIcon: Icon(icon, color: zinc400, size: 20),
      filled: true,
      fillColor: zinc900,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: zinc800),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: zinc400),
      ),
      errorStyle: const TextStyle(height: 0.8, fontSize: 11),
    );
  }

  Widget _buildValidationItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.circle_outlined, size: 14, color: zinc400),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: zinc400, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthViewModel>(context);
    return Scaffold(
      backgroundColor: zinc950,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Icon(Icons.shield_outlined, color: zinc100, size: 40),
                    const SizedBox(height: 16),
                    Text(
                      _showOtpField ? 'Verify Email' : 'Create Account',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: zinc100,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _showOtpField
                          ? 'Check your notifications for the code'
                          : 'Join CipherTask to secure your daily workflow',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: zinc400, fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    Form(
                      key: _formKey,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _showOtpField
                            ? _buildOtpForm(auth)
                            : _buildRegistrationForm(auth),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(color: zinc400),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Log in',
                            style: TextStyle(
                              color: zinc100,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildRegistrationForm(AuthViewModel auth) {
    bool allValid =
        _hasMinLength && _hasUppercase && _hasNumber && _passwordsMatch;

    return Column(
      key: const ValueKey('regForm'),
      children: [
        TextFormField(
          controller: _emailController,
          style: const TextStyle(color: zinc100),
          decoration: _fieldStyle('Email address', Icons.alternate_email),
          validator: (v) =>
              (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: zinc100),
          decoration: _fieldStyle('Password', Icons.lock_open_rounded).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: zinc400,
                size: 18,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: zinc100),
          decoration:
              _fieldStyle(
                'Confirm Password',
                Icons.lock_outline_rounded,
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: zinc400,
                    size: 18,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
        ),

        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Column(
            children: [
              if (!allValid) const SizedBox(height: 16),
              if (!allValid)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: zinc900.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: zinc800),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_hasMinLength)
                        _buildValidationItem('At least 8 characters'),
                      if (!_hasUppercase)
                        _buildValidationItem('Contains an uppercase letter'),
                      if (!_hasNumber)
                        _buildValidationItem('Contains a number'),
                      if (!_passwordsMatch)
                        _buildValidationItem('Passwords must match'),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: (_isSendingOtp || !allValid)
                ? null
                : () => _handleInitialRegistration(auth),
            style: ElevatedButton.styleFrom(
              backgroundColor: zinc100,
              foregroundColor: zinc950,
              disabledBackgroundColor: zinc800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSendingOtp
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: zinc950,
                    ),
                  )
                : const Text(
                    'Create Account',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpForm(AuthViewModel auth) {
    return Column(
      key: const ValueKey('otpForm'),
      children: [
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: zinc100,
            fontSize: 24,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
          ),
          decoration: _fieldStyle(
            '6-Digit Code',
            Icons.pin_outlined,
          ).copyWith(counterText: ""),
        ),
        const SizedBox(height: 16),

        // Timer Display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _canResend ? "Code expired" : "Resend in ",
              style: const TextStyle(color: zinc400, fontSize: 13),
            ),
            if (!_canResend)
              Text(
                "$_start" + "s",
                style: const TextStyle(
                  color: zinc100,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (_canResend)
              GestureDetector(
                onTap: _isSendingOtp
                    ? null
                    : () => _handleInitialRegistration(auth),
                child: const Text(
                  " RESEND",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: (_isLoading || _canResend)
                ? null
                : () => _verifyAndComplete(auth),
            style: ElevatedButton.styleFrom(
              backgroundColor: zinc100,
              foregroundColor: zinc950,
              disabledBackgroundColor: zinc800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: zinc950,
                    ),
                  )
                : const Text(
                    'Verify & Register',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        TextButton(
          onPressed: () {
            _timer?.cancel();
            setState(() => _showOtpField = false);
          },
          child: const Text(
            'Change email',
            style: TextStyle(color: zinc400, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
