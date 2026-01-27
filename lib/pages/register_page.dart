import 'package:flutter/material.dart';
import 'package:tradelogic/pages/dashboard_page.dart';
import 'package:tradelogic/pages/login_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 150,
                      width: 150,
                      child: Image.asset(
                        'images/logo1.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 10),

                    Text(
                      "Start Your Journey",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Join thousands of traders using data-driven insights.",
                      style: TextStyle(color: Colors.grey, fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 30),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          fieldTitle("Full Name"),
                          TextFormField(
                            style: const TextStyle(color: Colors.black),
                            keyboardType: TextInputType.name,
                            onSaved: (value) {
                              email = value!;
                            },
                            decoration: const InputDecoration(
                              labelText: "Full Name",
                              labelStyle: TextStyle(color: Colors.grey),
                              errorStyle: TextStyle(color: Colors.redAccent),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.indigo,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.redAccent),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.redAccent),
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),
                          fieldTitle("Email"),
                          TextFormField(
                            style: const TextStyle(color: Colors.black),
                            keyboardType: TextInputType.emailAddress,
                            onSaved: (value) {
                              email = value!;
                            },
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
                            decoration: const InputDecoration(
                              labelText: "Email",
                              labelStyle: TextStyle(color: Colors.grey),
                              errorStyle: TextStyle(color: Colors.redAccent),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.indigo,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.redAccent),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.redAccent),
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),
                          fieldTitle("Password"),

                          /// PASSWORD
                          TextFormField(
                            style: const TextStyle(color: Colors.black),
                            obscureText: _obscurePassword == true,
                            onSaved: (value) {
                              password = value!;
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: "Password",
                              labelStyle: const TextStyle(color: Colors.grey),
                              errorStyle: const TextStyle(
                                color: Colors.redAccent,
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.indigo,
                                  width: 2,
                                ),
                              ),
                              errorBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.redAccent),
                              ),
                              focusedErrorBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.redAccent),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),
                          fieldTitle("Confirm Password"),

                          /// PASSWORD
                          TextFormField(
                            style: const TextStyle(color: Colors.black),
                            obscureText: _obscurePassword == true,
                            onSaved: (value) {
                              password = value!;
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: "Confirm Password",
                              labelStyle: const TextStyle(color: Colors.grey),
                              errorStyle: const TextStyle(
                                color: Colors.redAccent,
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.indigo,
                                  width: 2,
                                ),
                              ),
                              errorBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.redAccent),
                              ),
                              focusedErrorBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.redAccent),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _acceptedTerms,
                                activeColor: Colors.indigo,
                                checkColor: Colors.white,
                                onChanged: (value) {
                                  setState(() {
                                    _acceptedTerms = value!;
                                  });
                                },
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                      children: [
                                        const TextSpan(text: "I agree to the "),
                                        TextSpan(
                                          text: "Terms & Conditions",
                                          style: const TextStyle(
                                            color: Colors.indigo,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          // later you can add TapGestureRecognizer for navigation
                                        ),
                                        const TextSpan(text: " and "),
                                        TextSpan(
                                          text: "Privacy Policy",
                                          style: const TextStyle(
                                            color: Colors.indigo,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          ElevatedButton(
                            onPressed: () {
                              if (!_acceptedTerms) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Please accept Privacy Policy & Terms to continue",
                                    ),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }

                              if (_formKey.currentState!.validate()) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return DashboardPage();
                                    },
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(20.0),
                              backgroundColor: _acceptedTerms
                                  ? Colors.indigo
                                  : const Color(0xFFF3F4F6),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: const Text(
                              'Create Account',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),

                          const SizedBox(height: 10),

                          /// REGISTER
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginPage(),
                                ),
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "Already have an account? ",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Log In',
                                    style: TextStyle(
                                      color: Colors.indigo,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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
