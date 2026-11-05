import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final authControllerProvider =
StateNotifierProvider<AuthController, AuthState>((ref) {
  final supabase = ref.read(supabaseProvider);
  return AuthController(supabase);
});

class AuthState {
  final bool loading;
  final String? error;

  AuthState({this.loading = false, this.error});
}

class AuthController extends StateNotifier<AuthState> {
  final SupabaseClient supabase;

  static const String _webClientId =
      "480093477681-ogagb3hqc3q2ertsaot9np5fmj994ik9.apps.googleusercontent.com";

  AuthController(this.supabase) : super(AuthState());

  // ✅ Email signup
  Future<bool> signUpWithEmail(String email, String password) async {
    state = AuthState(loading: true);
    try {
      final response = await supabase.auth.signUp(email: email, password: password);
      if (response.user != null) {
        state = AuthState(loading: false);
        return true;
      } else {
        state = AuthState(loading: false, error: "Sign up failed");
        return false;
      }
    } catch (e) {
      state = AuthState(loading: false, error: e.toString());
      return false;
    }
  }

  // ✅ Email login
  Future<bool> signInWithEmail(String email, String password) async {
    state = AuthState(loading: true, error: null);

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        state = AuthState(loading: false);
        return true;
      } else {
        state = AuthState(
          loading: false,
          error: "Invalid email or password",
        );
        return false;
      }
    } on AuthException catch (e) {
      state = AuthState(
        loading: false,
        error: e.message,
      );
      return false;
    } catch (e) {
      state = AuthState(
        loading: false,
        error: "Unexpected error occurred",
      );
      return false;
    }
  }


  // ✅ Google login/signup (same method works for both)
  Future<bool> signInWithGoogle() async {
    state = AuthState(loading: true);
    try {
      final googleUser = await GoogleSignIn(clientId: _webClientId).signIn();
      if (googleUser == null) {
        state = AuthState(loading: false);
        return false;
      }
      final googleAuth = await googleUser.authentication;
      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      if (response.session != null) {
        state = AuthState(loading: false);
        return true;
      } else {
        state = AuthState(loading: false, error: "Google sign-in failed");
        return false;
      }
    } catch (e) {
      state = AuthState(loading: false, error: e.toString());
      return false;
    }
  }

  // ✅ Forgot password
  Future<void> forgotPassword(String email) async {
    if (email.isEmpty) return;
    state = AuthState(loading: true);
    try {
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.foodlog://reset-password',
      );
    } catch (e) {
      state = AuthState(loading: false, error: e.toString());
    } finally {
      state = AuthState(loading: false);
    }
  }

  // ✅ Check login flag
  Future<bool> checkLoginFlag() async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    final response = await supabase
        .from('user_details')
        .select('login_flag')
        .eq('id', user.id)
        .maybeSingle();

    final loginFlag = response?['login_flag'] ?? 0;
    return loginFlag == 1;
  }


  Future<void> saveUserDetails({
    required String username,
    required String email,
    DateTime? dob,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? avatarUrl,
    String? activityLevel,
    String? dietGoal,
  }) async {
    print("👉 saveUserDetails called");
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      print("👉 inserting user_details for userId=${user.id}");
      await supabase.from('user_details').upsert({
        'id': user.id,
        'username': username,
        'email': email,
        'dob': dob?.toIso8601String(),
        'gender': gender,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'avatar_url': avatarUrl,
        'activity_level': activityLevel,
        'diet_goal': dietGoal,
        'login_flag': 1,
        'updated_at': DateTime.now().toIso8601String(),
      });
      print("working");
    } catch (e) {
      state = AuthState(loading: false, error: e.toString());
    }
  }
  // =========================================================
  //             PHONE NUMBER AUTH + OTP (NEW)
  // =========================================================

  // ---------------------------------------------------------
  // SEND OTP
  // ---------------------------------------------------------
  Future<bool> sendOtpToPhone(String phone) async {
    state = AuthState(loading: true);
    try {
      final formattedPhone =
      phone.startsWith("+") ? phone : "+91$phone"; // Adjust for India

      await supabase.auth.signInWithOtp(phone: formattedPhone);

      state = AuthState(loading: false);
      return true;
    } catch (e) {
      state = AuthState(loading: false, error: e.toString());
      return false;
    }
  }

  // ---------------------------------------------------------
  // VERIFY OTP
  // ---------------------------------------------------------
  Future<bool> verifyPhoneOtp(String phone, String otp) async {
    state = AuthState(loading: true);
    try {
      final formattedPhone =
      phone.startsWith("+") ? phone : "+91$phone";

      final response = await supabase.auth.verifyOTP(
        token: otp,
        type: OtpType.sms,
        phone: formattedPhone,
      );

      if (response.session != null) {
        state = AuthState(loading: false);
        return true;
      } else {
        state =
            AuthState(loading: false, error: "Invalid OTP");
        return false;
      }
    } catch (e) {
      state = AuthState(loading: false, error: e.toString());
      return false;
    }
  }
}


