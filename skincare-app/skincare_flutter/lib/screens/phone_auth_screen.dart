import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import 'home_screen.dart';
import 'profile_setup_screen.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  // Controllers
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  // OTP digit controllers
  final List<TextEditingController> _otpDigits =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  // State
  bool _isLoading = false;
  bool _otpSent = false;
  bool _requiresName = false;
  String _verificationId = '';
  int _resendToken = 0;
  int _countdown = 60;
  Timer? _timer;
  String _selectedCountryCode = '+91';
  String? _pendingIdToken;

  // Web only — ConfirmationResult from signInWithPhoneNumber
  ConfirmationResult? _webConfirmationResult;

  // Web only — reCAPTCHA verifier
  RecaptchaVerifier? _recaptchaVerifier;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _timer?.cancel();
    for (final c in _otpDigits) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    _recaptchaVerifier?.clear();
    super.dispose();
  }

  // ── Countdown Timer ─────────────────────────────────────────
  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown == 0) {
        timer.cancel();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  String get _fullPhone =>
      '$_selectedCountryCode${_phoneController.text.trim()}';

  String get _otp => _otpDigits.map((c) => c.text).join();

  // ── SEND OTP — Platform aware ────────────────────────────────
  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      _showError('Please enter a valid phone number');
      return;
    }

    setState(() => _isLoading = true);

    if (kIsWeb) {
      await _sendOTPWeb();
    } else {
      await _sendOTPMobile();
    }
  }

  // ── WEB OTP via signInWithPhoneNumber + reCAPTCHA ───────────
  Future<void> _sendOTPWeb() async {
    try {
      // Clear old verifier if exists
      _recaptchaVerifier?.clear();

      // Create invisible reCAPTCHA verifier natively supported by Flutter Web
     _recaptchaVerifier = RecaptchaVerifier(
  auth: FirebaseAuthPlatform.instance, // Updated to platform interface
  container: 'recaptcha-container',
  size: RecaptchaVerifierSize.normal, // Changed from invisible
  onSuccess: () => debugPrint('reCAPTCHA verified successfully'),
  onError: (FirebaseAuthException error) {
    debugPrint('reCAPTCHA error: ${error.message}');
    _showError('reCAPTCHA failed. Please try again.');
  },
  onExpired: () {
    debugPrint('reCAPTCHA expired');
    _showError('reCAPTCHA expired. Please try again.');
  },
);

      // Sign in with phone number using reCAPTCHA verifier
      _webConfirmationResult = await FirebaseAuth.instance
          .signInWithPhoneNumber(_fullPhone, _recaptchaVerifier!);

      setState(() {
        _isLoading = false;
        _otpSent = true;
      });
      _startCountdown();
      _showSuccess('OTP sent to $_fullPhone');
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _recaptchaVerifier?.clear();
      switch (e.code) {
        case 'invalid-phone-number':
          _showError('Invalid phone number format.');
          break;
        case 'too-many-requests':
          _showError('Too many requests. Please try again later.');
          break;
        case 'captcha-check-failed':
          _showError('reCAPTCHA verification failed. Please try again.');
          break;
        default:
          _showError(e.message ?? 'Failed to send OTP. Try again.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _recaptchaVerifier?.clear();
      _showError('Error: ${e.toString()}');
    }
  }

  // ── MOBILE OTP via verifyPhoneNumber ────────────────────────
  Future<void> _sendOTPMobile() async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _fullPhone,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken == 0 ? null : _resendToken,

      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-verified on Android
        try {
          final userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);
          final idToken = await userCredential.user?.getIdToken();
          if (idToken != null) await _loginWithToken(idToken);
        } catch (e) {
          _showError('Auto verification failed: $e');
        }
      },

      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        switch (e.code) {
          case 'invalid-phone-number':
            _showError('Invalid phone number format.');
            break;
          case 'too-many-requests':
            _showError('Too many requests. Please try again later.');
            break;
          default:
            _showError(e.message ?? 'Failed to send OTP. Try again.');
        }
      },

      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _isLoading = false;
          _otpSent = true;
          _verificationId = verificationId;
          _resendToken = resendToken ?? 0;
        });
        _startCountdown();
        _showSuccess('OTP sent to $_fullPhone');
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  // ── VERIFY OTP — Platform aware ──────────────────────────────
  Future<void> _verifyOTP() async {
    if (_otp.length != 6) {
      _showError('Please enter the complete 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    if (kIsWeb) {
      await _verifyOTPWeb();
    } else {
      await _verifyOTPMobile();
    }
  }

  // ── WEB OTP Verification ─────────────────────────────────────
  Future<void> _verifyOTPWeb() async {
    try {
      if (_webConfirmationResult == null) {
        _showError('Session expired. Please request a new OTP.');
        setState(() {
          _isLoading = false;
          _otpSent = false;
        });
        return;
      }

      final userCredential =
          await _webConfirmationResult!.confirm(_otp);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        _showError('Failed to get token. Please try again.');
        setState(() => _isLoading = false);
        return;
      }

      await _loginWithToken(idToken);
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      switch (e.code) {
        case 'invalid-verification-code':
          _showError('Incorrect OTP. Please check and try again.');
          break;
        case 'session-expired':
          _showError('OTP expired. Please request a new one.');
          setState(() => _otpSent = false);
          break;
        case 'too-many-requests':
          _showError('Too many attempts. Please try again later.');
          break;
        default:
          _showError(e.message ?? 'Verification failed. Try again.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Something went wrong. Please try again.');
    }
  }

  // ── MOBILE OTP Verification ──────────────────────────────────
  Future<void> _verifyOTPMobile() async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otp,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        _showError('Failed to get token. Please try again.');
        setState(() => _isLoading = false);
        return;
      }

      await _loginWithToken(idToken);
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      switch (e.code) {
        case 'invalid-verification-code':
          _showError('Incorrect OTP. Please check and try again.');
          break;
        case 'session-expired':
          _showError('OTP expired. Please request a new one.');
          setState(() => _otpSent = false);
          break;
        case 'too-many-requests':
          _showError('Too many attempts. Please try again later.');
          break;
        default:
          _showError(e.message ?? 'Verification failed. Try again.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Something went wrong. Please try again.');
    }
  }

  // ── Login with Backend Token ─────────────────────────────────
  Future<void> _loginWithToken(String idToken) async {
    final auth =
        Provider.of<app_auth.AuthProvider>(context, listen: false);

    try {
      final data = await auth.phoneLoginWithToken(idToken);

      if (!mounted) return;

      if (data['requiresName'] == true) {
        setState(() {
          _isLoading = false;
          _requiresName = true;
          _pendingIdToken = idToken;
        });
        return;
      }

      setState(() => _isLoading = false);

      if (data['token'] != null) {
        if (data['isNewUser'] == true) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const ProfileSetupScreen()));
        } else {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
      } else {
        _showError(data['message'] ?? 'Login failed. Please try again.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error: $e');
    }
  }

  // ── Submit Name (new users) ──────────────────────────────────
  Future<void> _submitName() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter your name');
      return;
    }
    if (_pendingIdToken == null) return;

    setState(() => _isLoading = true);

    final auth =
        Provider.of<app_auth.AuthProvider>(context, listen: false);
    final data = await auth.phoneLoginWithToken(
      _pendingIdToken!,
      name: _nameController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (data['token'] != null) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()));
    } else {
      _showError(data['message'] ?? 'Registration failed.');
    }
  }

  // ── Snackbars ────────────────────────────────────────────────
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Country Picker ───────────────────────────────────────────
  void _showCountryPicker() {
    final codes = [
      {'code': '+91', 'country': '🇮🇳 India'},
      {'code': '+1', 'country': '🇺🇸 USA'},
      {'code': '+44', 'country': '🇬🇧 UK'},
      {'code': '+61', 'country': '🇦🇺 Australia'},
      {'code': '+971', 'country': '🇦🇪 UAE'},
      {'code': '+65', 'country': '🇸🇬 Singapore'},
      {'code': '+60', 'country': '🇲🇾 Malaysia'},
      {'code': '+49', 'country': '🇩🇪 Germany'},
      {'code': '+33', 'country': '🇫🇷 France'},
      {'code': '+81', 'country': '🇯🇵 Japan'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Country Code',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: codes.length,
                itemBuilder: (_, i) => ListTile(
                  title: Text(codes[i]['country']!),
                  trailing: Text(codes[i]['code']!,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE91E8C))),
                  onTap: () {
                    setState(() =>
                        _selectedCountryCode = codes[i]['code']!);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BUILD ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () {
            if (_requiresName) {
              setState(() => _requiresName = false);
            } else if (_otpSent) {
              setState(() {
                _otpSent = false;
                _timer?.cancel();
                _webConfirmationResult = null;
                _recaptchaVerifier?.clear();
                for (final c in _otpDigits) c.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _requiresName
              ? _buildNameStep()
              : _otpSent
                  ? _buildOTPStep()
                  : _buildPhoneStep(),
        ),
      ),
    );
  }

  // ── STEP 1: Phone Input ──────────────────────────────────────
  Widget _buildPhoneStep() {
    return Column(
      key: const ValueKey('phone'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.phone_android,
              size: 36, color: Color(0xFFE91E8C)),
        ),
        const SizedBox(height: 24),
        const Text('Enter Your Phone',
            style:
                TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          "We'll send you a one-time password to verify your number.",
          style: TextStyle(
              color: Colors.grey.shade600, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 36),

        // Phone input
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _showCountryPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 18),
                  decoration: BoxDecoration(
                      border: Border(
                          right:
                              BorderSide(color: Colors.grey.shade200))),
                  child: Row(
                    children: [
                      Text(_selectedCountryCode,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down,
                          color: Colors.grey, size: 20),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: '9876543210',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendOTP,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E8C),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Send OTP',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline,
                  color: Color(0xFFE91E8C), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Standard SMS rates may apply. OTP is valid for 60 seconds.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── STEP 2: OTP Input ────────────────────────────────────────
  Widget _buildOTPStep() {
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.sms_outlined,
              size: 36, color: Color(0xFFE91E8C)),
        ),
        const SizedBox(height: 24),
        const Text('Enter OTP',
            style:
                TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: TextStyle(
                color: Colors.grey.shade600, fontSize: 14, height: 1.5),
            children: [
              const TextSpan(text: 'OTP sent to '),
              TextSpan(
                text: _fullPhone,
                style: const TextStyle(
                    color: Color(0xFFE91E8C),
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => _otpBox(i)),
        ),
        const SizedBox(height: 32),

        Center(
          child: _countdown > 0
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('Resend OTP in $_countdown seconds',
                        style: const TextStyle(color: Colors.grey)),
                  ],
                )
              : GestureDetector(
                  onTap: () {
                    for (final c in _otpDigits) c.clear();
                    _webConfirmationResult = null;
                    _recaptchaVerifier?.clear();
                    setState(() => _otpSent = false);
                    _sendOTP();
                  },
                  child: const Text('Resend OTP',
                      style: TextStyle(
                          color: Color(0xFFE91E8C),
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyOTP,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E8C),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Verify & Login',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // ── STEP 3: Name Input ───────────────────────────────────────
  Widget _buildNameStep() {
    return Column(
      key: const ValueKey('name'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.person_outline,
              size: 36, color: Color(0xFFE91E8C)),
        ),
        const SizedBox(height: 24),
        const Text("What's Your Name?",
            style:
                TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'Since this is your first time, tell us your name to personalize your experience.',
          style: TextStyle(
              color: Colors.grey.shade600, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 36),

        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Full Name',
            hintText: 'e.g. Adarsh Sahay',
            prefixIcon: const Icon(Icons.person_outline,
                color: Color(0xFFE91E8C)),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: Color(0xFFE91E8C), width: 1.5),
            ),
            labelStyle: const TextStyle(color: Color(0xFFE91E8C)),
          ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitName,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E8C),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Create Account',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // ── OTP Box ──────────────────────────────────────────────────
  Widget _otpBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: _otpDigits[index],
        focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFFFFF0F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: Color(0xFFE91E8C), width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _otpFocusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
          if (_otp.length == 6) {
            FocusScope.of(context).unfocus();
          }
        },
      ),
    );
  }
}