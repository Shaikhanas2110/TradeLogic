import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tradelogic/pages/dashboard_page.dart';
import 'package:tradelogic/pages/register_page.dart';
import 'dart:ui';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String email = "";
  String password = "";
  late bool _obscurePassword;

  @override
  void initState() {
    super.initState();
    _obscurePassword = true;
  }

  Future<void> loginUser(BuildContext context) async {
    _formKey.currentState!.save();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login successful")));

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DashboardPage()),
      );
    } on FirebaseAuthException catch (e) {
      String message = "Login Failed";

      if (e.code == 'user-not-found') {
        message = "User Not Found";
      } else if (e.code == 'wrong-password') {
        message = "Incorrect Password";
      } else if (e.code == 'invalid-email') {
        message = "Invalid Email";
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Something went wrong")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          /// 🔥 DARK GRADIENT BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF000000),
                  Color(0xFF0F0F1A),
                  Color(0xFF1A1A2E),
                ],
              ),
            ),
          ),

          /// 🔵 TOP RIGHT GLOW
          Positioned(
            top: -120,
            right: -120,
            child: _buildGlowCircle(Colors.indigoAccent.withOpacity(0.6)),
          ),

          /// 🔵 BOTTOM LEFT GLOW
          Positioned(
            bottom: -150,
            left: -150,
            child: _buildGlowCircle(Colors.indigo.withOpacity(0.5)),
          ),

          /// 📄 CONTENT
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            /// LOGO
                            SizedBox(
                              height: 120,
                              width: 120,
                              child: Image.asset(
                                'images/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),

                            const SizedBox(height: 15),

                            const Text(
                              "Welcome Back",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 26,
                              ),
                            ),

                            const SizedBox(height: 5),

                            const Text(
                              "Login to your trading dashboard",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 30),

                            /// EMAIL FIELD
                            _glassField(
                              label: "Email",
                              keyboard: TextInputType.emailAddress,
                              onSaved: (value) => email = value!,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Email is required';
                                }
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 15),

                            /// PASSWORD FIELD
                            _glassField(
                              label: "Password",
                              obscure: _obscurePassword,
                              onSaved: (value) => password = value!,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required';
                                }
                                if (value.length < 6) {
                                  return 'Minimum 6 characters';
                                }
                                return null;
                              },
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),

                            const SizedBox(height: 25),

                            /// LOGIN BUTTON
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  loginUser(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: Colors.indigoAccent,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(height: 15),

                            /// REGISTER LINK
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RegisterPage(),
                                  ),
                                );
                              },
                              child: RichText(
                                text: const TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "Don't have an account? ",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    TextSpan(
                                      text: "Sign Up",
                                      style: TextStyle(
                                        color: Colors.indigoAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _glassField({
    required String label,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextFormField(
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboard,
      obscureText: obscure,
      onSaved: onSaved,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),

        filled: true,
        fillColor: Colors.white.withOpacity(0.06),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.indigoAccent, width: 2),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),

        suffixIcon: suffix,
      ),
    );
  }

  Widget _buildGlowCircle(Color color) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}
