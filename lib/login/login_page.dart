import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../main_page.dart';
import 'signup_page.dart';
import '../providers/auth_provider.dart';
import 'onboarding_ques.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class LoginPage extends ConsumerStatefulWidget {
  // Login doesn't need to carry the array, so it is optional
  final Map<String, dynamic>? preLoginData;

  const LoginPage({
    super.key,
    this.preLoginData,
  });

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Phone login controllers
  final _phoneController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());

  String _loginMode = "phone";
  bool _showOtpField = false;
  bool _sending = false;

  String _selectedCountryCode = '+91';

  final List<String> _countryCodes = [
    '+91',
    '+1',
    '+44',
    '+61',
  ];
  int _resendCountdown = 30;
  Timer? _resendTimer;
  bool _canResend = false;

  void _signInWithEmail() async {
    final auth = ref.read(authControllerProvider.notifier);
    final success = await auth.signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    if (success && mounted) {
      // Logic: Successfully logged in, go to main and clear stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) =>  MainPage()),
            (route) => false,
      );
    } else {
      final error = ref.read(authControllerProvider).error ?? "Unknown error";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _signInWithGoogle() async {
    final auth = ref.read(authControllerProvider.notifier);
    final success = await auth.signInWithGoogle();
    if (success && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) =>  MainPage()),
            (route) => false,
      );
    }
  }

  void _signUp() {
    // UPDATED: New users must go through Questionnaire first
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OnboardingFlow()),
    );
  }

  // --- Phone Methods ---
  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _resendCountdown = 30;
      _canResend = false;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _resendTimer?.cancel();
      }
    });
  }

  // Change only these two methods inside _LoginPageState in login_page.dart:

  void _sendOtp() async {
    if (_phoneController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter valid phone number")));
      return;
    }
    setState(() => _sending = true);
    String fullPhone = _selectedCountryCode + _phoneController.text.trim();
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        phone: fullPhone,
        shouldCreateUser: false, // Login only
      );
      for (var controller in _otpControllers) controller.clear();
      setState(() {
        _showOtpField = true;
        _sending = false;
      });
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("OTP sent via Twilio")));
    } catch (e) {
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _verifyOtp() async {
    setState(() => _sending = true);
    String otp = _otpControllers.map((c) => c.text).join();
    String fullPhone = _selectedCountryCode + _phoneController.text.trim();
    try {
      final res = await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.sms,
        token: otp,
        phone: fullPhone,
      );
      if (res.user != null && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainPage()));
      }
    } catch (e) {
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid OTP: $e")));
    }
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
        decoration: InputDecoration(
          counterText: "",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
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

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
              Colors.blue.shade400
            ],
          ),
        ),
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
                        const Text(
                          "Set Me Fit",
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 50,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 70,
                          width: 70,
                          child: Image.asset("assets/icon/app_logo.png",
                              fit: BoxFit.contain),
                        ),
                      ],
                    ),
                    const Text(
                      "Zeal Right. Feel Right.",
                      style: TextStyle(color: Colors.yellow, fontSize: 25),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(60),
                    topRight: Radius.circular(60),
                  ),
                ),
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        FadeInUp(
                          duration: const Duration(milliseconds: 800),
                          child: const Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Welcome Back Friend!😍",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  "Please login to your account",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        _buildToggle(),
                        const SizedBox(height: 20),
                        if (_loginMode == "email") ...[
                          FadeInUp(
                            duration: const Duration(milliseconds: 1000),
                            child: Column(
                              children: [
                                _buildTextField(
                                    _emailController, "Email", Icons.email, false),
                                const SizedBox(height: 20),
                                _buildTextField(
                                  _passwordController,
                                  "Password",
                                  Icons.lock,
                                  _obscurePassword,
                                  suffix: IconButton(
                                    icon: Icon(_obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off),
                                    onPressed: () => setState(() =>
                                    _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildActionButton(
                                    state.loading ? null : _signInWithEmail,
                                    "Login",
                                    state.loading),
                              ],
                            ),
                          ),
                        ] else ...[
                          _buildPhoneInput(),
                        ],
                        const SizedBox(height: 30),
                        const Text("Or continue with",
                            style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 20),
                        _buildGoogleButton(
                            state.loading ? null : _signInWithGoogle),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account? "),
                            TextButton(
                              onPressed: _signUp,
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
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

  // REFORMATTED HELPER WIDGETS
  Widget _buildToggle() {
    return Container(
      width: 250,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.blue.shade100.withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: _loginMode == "email"
                ? Alignment.centerLeft
                : Alignment.centerRight,
            duration: const Duration(milliseconds: 250),
            child: Container(
              width: 125,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.blue.shade800,
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _loginMode = "email"),
                  child: Center(
                    child: Text(
                      "Email",
                      style: TextStyle(
                        color: _loginMode == "email"
                            ? Colors.white
                            : Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _loginMode = "phone"),
                  child: Center(
                    child: Text(
                      "Phone",
                      style: TextStyle(
                        color: _loginMode == "phone"
                            ? Colors.white
                            : Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, IconData icon, bool obscure,
      {Widget? suffix}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          prefixIcon: Icon(icon),
          suffixIcon: suffix,
        ),
      ),
    );
  }

  Widget _buildActionButton(VoidCallback? onPressed, String text, bool loading) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[800],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: loading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        icon: Image.network(
          "https://upload.wikimedia.org/wikipedia/commons/4/4a/Logo_2013_Google.png",
          height: 20,
        ),
        label: const Text(
          "Sign in with Google",
          style: TextStyle(fontSize: 16),
        ),
        onPressed: onPressed,
      ),
    );
  }
  Widget _buildPhoneInput() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButton<String>(
                value: _selectedCountryCode,
                items: _countryCodes
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCountryCode = v!),
                underline: const SizedBox(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                decoration: InputDecoration(
                  hintText: "10 digit number",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 15),

        if (!_showOtpField)
          _buildActionButton(
            _sending ? null : _sendOtp,
            "Send OTP",
            _sending,
          )
        else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (i) => _buildOtpField(i)),
          ),

          const SizedBox(height: 12),

          _buildActionButton(
            _sending ? null : _verifyOtp,
            "Verify OTP",
            _sending,
          ),

          const SizedBox(height: 12),

          _canResend
              ? TextButton(
            onPressed: () {
              _sendOtp();
            },
            child: const Text(
              "Resend OTP",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          )
              : Text(
            "Resend OTP in $_resendCountdown sec",
            style: const TextStyle(color: Colors.grey),
          ),
        ]
      ],
    );
  }
}