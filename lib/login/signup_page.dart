import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/auth_provider.dart';
import 'login_page.dart';
import '../main_page.dart';
import '../services/health_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> preLoginData;

  const SignUpPage({super.key, required this.preLoginData});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); // Added
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  // OTP Logic Controllers
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  String _signupMode = "phone"; // "email" or "phone"
  bool _showOtpField = false;
  bool _isProcessing = false;
  String _selectedCountryCode = '+91';

  int _resendCountdown = 30;
  Timer? _resendTimer;
  bool _canResend = false;

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _resendCountdown = 30;
      _canResend = false;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        setState(() => _canResend = true);
        _resendTimer?.cancel();
      }
    });
  }

  void _sendOtp() async {
    if (_phoneController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter valid phone number")));
      return;
    }
    setState(() => _isProcessing = true);
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        phone: '$_selectedCountryCode${_phoneController.text.trim()}',
        shouldCreateUser: true,
      );
      setState(() {
        _showOtpField = true;
        _isProcessing = false;
      });
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("OTP sent successfully")));
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _signUpWithEmail() async {
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    final authNotifier = ref.read(authControllerProvider.notifier);
    final success = await authNotifier.signUpWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          await HealthService().syncHealthData(user.id, widget.preLoginData);
          if (mounted) {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => MainPage()), (route) => false);
          }
        } catch (e) {
          debugPrint("SYNC ERROR: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Account created, but data sync failed: $e")));
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainPage()));
          }
        }
      }
    } else {
      final error = ref.read(authControllerProvider).error ?? "Sign up failed";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _verifyOtpAndSync() async {
    setState(() => _isProcessing = true);
    String otp = _otpControllers.map((c) => c.text).join();
    String fullPhone = '$_selectedCountryCode${_phoneController.text.trim()}';

    try {
      final res = await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.sms,
        token: otp,
        phone: fullPhone,
      );

      final user = res.user;
      if (user != null) {
        // REMOVED: manual Supabase.instance.client.from('profiles').upsert(...)

        // Now HealthService is the only place where the profile is inserted
        if (widget.preLoginData.isNotEmpty) {
          await HealthService().syncHealthData(user.id, widget.preLoginData);
        }

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => MainPage()),
                (route) => false,
          );
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
  void _signUpWithGoogle() async {
    final authNotifier = ref.read(authControllerProvider.notifier);
    final success = await authNotifier.signInWithGoogle();
    if (success && mounted) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          await HealthService().syncHealthData(user.id, widget.preLoginData);
        } catch (e) {
          debugPrint("Google Sync Error: $e");
        }
        if (mounted) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => MainPage()), (route) => false);
        }
      }
    }
  }

  void _goToLogin() {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage(preLoginData: {})), (route) => false);
  }

  Widget _buildToggle() {
    return Container(
      width: 250, height: 45,
      decoration: BoxDecoration(color: Colors.blue.shade100.withOpacity(0.3), borderRadius: BorderRadius.circular(30)),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: _signupMode == "email" ? Alignment.centerLeft : Alignment.centerRight,
            duration: const Duration(milliseconds: 250),
            child: Container(width: 125, height: 45, decoration: BoxDecoration(color: Colors.blue.shade800, borderRadius: BorderRadius.circular(30))),
          ),
          Row(
            children: [
              Expanded(child: InkWell(onTap: () => setState(() { _signupMode = "email"; _showOtpField = false; }), child: Center(child: Text("Email", style: TextStyle(color: _signupMode == "email" ? Colors.white : Colors.blue.shade800, fontWeight: FontWeight.bold))))),
              Expanded(child: InkWell(onTap: () => setState(() => _signupMode = "phone"), child: Center(child: Text("Phone", style: TextStyle(color: _signupMode == "phone" ? Colors.white : Colors.blue.shade800, fontWeight: FontWeight.bold))))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtpField(int index) {
    return SizedBox(
      width: 45,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: InputDecoration(counterText: "", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _otpFocusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  Widget _textField(TextEditingController controller, String hint, IconData icon, bool obscure, {VoidCallback? toggle, TextInputType? type}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        decoration: InputDecoration(border: InputBorder.none, hintText: hint, prefixIcon: Icon(icon), suffixIcon: toggle != null ? IconButton(icon: Icon(obscure ? Icons.visibility : Icons.visibility_off), onPressed: toggle) : null),
      ),
    );
  }

  Widget _actionButton(VoidCallback? onPressed, String text, bool loading) {
    return SizedBox(
      width: double.infinity, height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))),
        child: loading ? const CircularProgressIndicator(color: Colors.white) : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _googleButton(VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity, height: 50,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))),
        icon: Image.network("https://upload.wikimedia.org/wikipedia/commons/4/4a/Logo_2013_Google.png", height: 20),
        label: const Text("Sign up with Google", style: TextStyle(fontSize: 16)),
        onPressed: onPressed,
      ),
    );
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var c in _otpControllers) c.dispose();
    for (var f in _otpFocusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, colors: [Colors.blue.shade900, Colors.blue.shade700, Colors.blue.shade400])),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),
            Padding(
              padding: const EdgeInsets.all(20),
              child: FadeInDown(
                duration: const Duration(milliseconds: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Set Me Fit", style: TextStyle(color: Colors.green, fontSize: 50, fontWeight: FontWeight.bold)),
                        SizedBox(height: 70, width: 70, child: Image.asset("assets/icon/app_logo.png", fit: BoxFit.contain)),
                      ],
                    ),
                    const Text("Fuel Right. Feel Right.", style: TextStyle(color: Colors.yellow, fontSize: 25)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(60), topRight: Radius.circular(60))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        FadeInUp(duration: const Duration(milliseconds: 800), child: _buildToggle()),
                        const SizedBox(height: 30),
                        if (_signupMode == "email") ...[
                          FadeInUp(duration: const Duration(milliseconds: 1000), child: _textField(_emailController, "Email", Icons.email, false)),
                          const SizedBox(height: 20),
                          FadeInUp(duration: const Duration(milliseconds: 1100), child: _textField(_passwordController, "Password", Icons.lock, _obscurePassword, toggle: () => setState(() => _obscurePassword = !_obscurePassword))),
                          const SizedBox(height: 20),
                          FadeInUp(duration: const Duration(milliseconds: 1200), child: _textField(_confirmController, "Confirm Password", Icons.lock_outline, _obscureConfirm, toggle: () => setState(() => _obscureConfirm = !_obscureConfirm))),
                          const SizedBox(height: 30),
                          FadeInUp(duration: const Duration(milliseconds: 1300), child: _actionButton(state.loading ? null : _signUpWithEmail, "Create Account", state.loading)),
                        ] else ...[
                          _buildPhoneSection(),
                        ],
                        const SizedBox(height: 30),
                        FadeInUp(duration: const Duration(milliseconds: 1400), child: const Text("Or continue with", style: TextStyle(color: Colors.grey))),
                        const SizedBox(height: 20),
                        FadeInUp(duration: const Duration(milliseconds: 1500), child: _googleButton(state.loading ? null : _signUpWithGoogle)),
                        const SizedBox(height: 30),
                        FadeInUp(duration: const Duration(milliseconds: 1600), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text("Already have an account? "), TextButton(onPressed: _goToLogin, child: const Text("Login", style: TextStyle(fontWeight: FontWeight.bold)))]))
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneSection() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
              child: DropdownButton<String>(
                value: _selectedCountryCode,
                items: ['+91', '+1', '+44'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCountryCode = v!),
                underline: const SizedBox(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _textField(_phoneController, "10 digit number", Icons.phone, false, type: TextInputType.phone)),
          ],
        ),
        const SizedBox(height: 20),
        if (_showOtpField) ...[
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(6, (i) => _buildOtpField(i))),
          const SizedBox(height: 15),
          _actionButton(_isProcessing ? null : _verifyOtpAndSync, "Verify & Sign Up", _isProcessing),
          const SizedBox(height: 12),
          _canResend ? TextButton(onPressed: _sendOtp, child: const Text("Resend OTP", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))) : Text("Resend OTP in $_resendCountdown sec", style: const TextStyle(color: Colors.grey)),
        ] else
          _actionButton(_isProcessing ? null : _sendOtp, "Send OTP", _isProcessing),
      ],
    );
  }
}