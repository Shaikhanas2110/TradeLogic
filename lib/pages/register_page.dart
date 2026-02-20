import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:tradelogic/pages/dashboard_page.dart';
import 'package:tradelogic/pages/login_page.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  String fullName = "";
  String email = "";
  String password = "";
  late bool _obscurePassword;
  bool _acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    _obscurePassword = true;
  }

  Future<void> registerUser(String email, String password, String name) async {
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      final uid = userCredential.user!.uid;

      await FirebaseDatabase.instance.ref().child("users").child(uid).set({
        "username": name,
        "email": email,
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DashboardPage()),
      );

      print("REGISTER SUCCESS!!");
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          /// 🔥 DARK GRADIENT
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
                              height: 110,
                              width: 110,
                              child: Image.asset(
                                'images/logo1.png',
                                fit: BoxFit.contain,
                              ),
                            ),

                            const SizedBox(height: 15),

                            const Text(
                              "Start Your Journey",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),

                            const SizedBox(height: 5),

                            const Text(
                              "Join thousands of traders using data-driven insights.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),

                            const SizedBox(height: 30),

                            /// FULL NAME
                            _glassField(
                              label: "Full Name",
                              keyboard: TextInputType.name,
                              onSaved: (value) => fullName = value!,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? "Full name required"
                                  : null,
                            ),

                            const SizedBox(height: 15),

                            /// EMAIL
                            _glassField(
                              label: "Email",
                              keyboard: TextInputType.emailAddress,
                              onSaved: (value) {
                                email = value!;
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Email required';
                                }
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  return 'Invalid email';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 15),

                            /// PASSWORD
                            _glassField(
                              label: "Password",
                              obscure: _obscurePassword,
                              onSaved: (value) => password = value!,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password required';
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

                            const SizedBox(height: 15),

                            /// CONFIRM PASSWORD
                            _glassField(
                              label: "Confirm Password",
                              obscure: _obscurePassword,
                              onSaved: (value) {},
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Confirm password';
                                }
                                // if (value != password) {
                                //   return 'Passwords do not match';
                                // }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            /// TERMS CHECKBOX
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _acceptedTerms,
                                  activeColor: Colors.indigoAccent,
                                  checkColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _acceptedTerms = value!;
                                    });
                                  },
                                ),
                                const Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 12),
                                    child: Text(
                                      "I agree to the Terms & Conditions and Privacy Policy",
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            /// CREATE ACCOUNT BUTTON
                            ElevatedButton(
                              onPressed: () async {
                                if (!_acceptedTerms) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Please accept Terms"),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }

                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();
                                  await registerUser(email, password, fullName);
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
                                'Create Account',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),

                            const SizedBox(height: 15),

                            /// LOGIN LINK
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LoginPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Already have an account? Log In",
                                style: TextStyle(color: Colors.white70),
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

Widget fieldTitle(String title) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}
