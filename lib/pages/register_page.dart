import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tradelogic/pages/dashboard_page.dart';
import 'package:tradelogic/pages/login_page.dart';
import 'package:tradelogic/models/firebase_portfolio_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  String fullName = "";
  String email = "";
  String password = "";
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;
  bool _isLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> registerUser(String email, String password, String name) async {
    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = cred.user!.uid;

      // Save username + email
      await FirebaseDatabase.instance.ref().child("users").child(uid).set({
        "username": name,
        "email": email,
      });

      // ✅ Initialise ₹1,00,000 balance in Firebase (only runs once per user)
      await FirebasePortfolioService.initUserAccount(startingBalance: 100000.0);

      if (mounted) {
        HapticFeedback.lightImpact();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Registration failed";
      if (e.code == 'email-already-in-use') {
        msg = "An account with this email already exists";
      } else if (e.code == 'weak-password') {
        msg = "Password is too weak";
      } else if (e.code == 'invalid-email') {
        msg = "Please enter a valid email address";
      }
      if (mounted) _toast(msg, isSuccess: false);
    } catch (e) {
      if (mounted) _toast("Something went wrong", isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toast(String msg, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isSuccess
            ? const Color(0xFF00C853)
            : const Color(0xFFFF5252),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 36),

                      // ── LOGO ───────────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C853).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.asset(
                                  'images/logo1.png',
                                  fit: BoxFit.contain,
                                  width: 68,
                                  height: 68,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              "Create Account",
                              style: TextStyle(
                                color: Color(0xFF1A1A2E),
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Join thousands of traders using data-driven insights",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF9E9E9E),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      _fieldLabel("Full Name"),
                      const SizedBox(height: 8),
                      _inputField(
                        hint: "John Doe",
                        keyboard: TextInputType.name,
                        prefixIcon: Icons.person_outline_rounded,
                        onSaved: (v) => fullName = v!,
                        validator: (v) => v == null || v.isEmpty
                            ? "Full name is required"
                            : null,
                      ),

                      const SizedBox(height: 16),

                      _fieldLabel("Email Address"),
                      const SizedBox(height: 8),
                      _inputField(
                        hint: "you@example.com",
                        keyboard: TextInputType.emailAddress,
                        prefixIcon: Icons.mail_outline_rounded,
                        onSaved: (v) => email = v!,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(v)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      _fieldLabel("Password"),
                      const SizedBox(height: 8),
                      _inputField(
                        hint: "Min. 6 characters",
                        obscure: _obscurePassword,
                        prefixIcon: Icons.lock_outline_rounded,
                        controller: _passwordController,
                        onSaved: (v) => password = v!,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password is required';
                          }
                          if (v.length < 6) return 'Minimum 6 characters';
                          return null;
                        },
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 18,
                            color: const Color(0xFF9E9E9E),
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      _fieldLabel("Confirm Password"),
                      const SizedBox(height: 8),
                      _inputField(
                        hint: "Re-enter password",
                        obscure: _obscureConfirm,
                        prefixIcon: Icons.lock_reset_rounded,
                        onSaved: (v) {},
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (v != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 18,
                            color: const Color(0xFF9E9E9E),
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Terms checkbox
                      GestureDetector(
                        onTap: () =>
                            setState(() => _acceptedTerms = !_acceptedTerms),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22,
                              height: 22,
                              margin: const EdgeInsets.only(top: 1),
                              decoration: BoxDecoration(
                                color: _acceptedTerms
                                    ? const Color(0xFF00C853)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _acceptedTerms
                                      ? const Color(0xFF00C853)
                                      : const Color(0xFFCCCCCC),
                                  width: 1.5,
                                ),
                              ),
                              child: _acceptedTerms
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                "I agree to the Terms & Conditions and Privacy Policy",
                                style: TextStyle(
                                  color: Color(0xFF555F6E),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Create Account button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  if (!_acceptedTerms) {
                                    _toast(
                                      "Please accept the Terms & Conditions",
                                      isSuccess: false,
                                    );
                                    return;
                                  }
                                  if (_formKey.currentState!.validate()) {
                                    _formKey.currentState!.save();
                                    await registerUser(
                                      email,
                                      password,
                                      fullName,
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C853),
                            disabledBackgroundColor: const Color(
                              0xFF00C853,
                            ).withOpacity(0.5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "Create Account",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          const Expanded(
                            child: Divider(color: Color(0xFFF0F0F0)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              "or",
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: Color(0xFFF0F0F0)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          ),
                          child: RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: "Already have an account? ",
                                  style: TextStyle(
                                    color: Color(0xFF9E9E9E),
                                    fontSize: 14,
                                  ),
                                ),
                                TextSpan(
                                  text: "Log In",
                                  style: TextStyle(
                                    color: Color(0xFF00C853),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) => Text(
    label,
    style: const TextStyle(
      color: Color(0xFF1A1A2E),
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
  );

  Widget _inputField({
    required String hint,
    required void Function(String?)? onSaved,
    required String? Function(String?)? validator,
    required IconData prefixIcon,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    TextEditingController? controller,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(
        color: Color(0xFF1A1A2E),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      keyboardType: keyboard,
      obscureText: obscure,
      onSaved: onSaved,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
        prefixIcon: Icon(prefixIcon, size: 18, color: const Color(0xFF9E9E9E)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00C853), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF5252)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF5252), width: 1.5),
        ),
        errorStyle: const TextStyle(
          color: Color(0xFFFF5252),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
