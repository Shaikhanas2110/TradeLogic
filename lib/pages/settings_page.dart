import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final String backendUrl = "http://192.168.1.17:5000";

  String _status = "Generated";
  final TextEditingController _manualTokenController = TextEditingController();

  Future<void> _handleUpstoxLogin() async {
    setState(() => _status = "Connecting to backend...");

    try {
      final response = await http
          .get(Uri.parse("$backendUrl/upstox/login-url"))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final url = jsonDecode(response.body)['url'];
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        setState(() => _status = "Backend Error");
      }
    } catch (e) {
      setState(() => _status = "Connection Failed");
    }
  }

  Future<void> _sendCodeToPython(String code) async {
    setState(() => _status = "Exchanging code...");

    try {
      final response = await http.post(
        Uri.parse("$backendUrl/upstox/exchange"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"code": code}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _status = "Login Successful!";
          _manualTokenController.text = data['access_token'];
        });
      } else {
        setState(() => _status = "Exchange Failed");
      }
    } catch (e) {
      setState(() => _status = "Backend Error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          /// 🔥 IDENTICAL BACKGROUND FROM HOMEPAGE
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

          /// 🔵 SAME GLOW 1
          Positioned(
            top: -120,
            right: -120,
            child: _buildGlowCircle(Colors.indigoAccent.withOpacity(0.6)),
          ),

          /// 🔵 SAME GLOW 2
          Positioned(
            bottom: -150,
            left: -150,
            child: _buildGlowCircle(Colors.indigo.withOpacity(0.5)),
          ),

          /// 📄 CONTENT
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  const Text(
                    "Trading Settings",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  _glassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Upstox Authentication",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _handleUpstoxLogin,
                          icon: const Icon(Icons.vpn_key),
                          label: const Text("Generate Access Token"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  _glassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Manual Token Entry",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _manualTokenController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Paste token here",
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: () =>
                              _sendCodeToPython(_manualTokenController.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Submit Token"),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  Center(
                    child: Text(
                      "Status: $_status",
                      style: TextStyle(
                        color:
                            _status.contains("Fail") ||
                                _status.contains("Error")
                            ? Colors.redAccent
                            : Colors.greenAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// SAME GLASS CARD
Widget _glassCard({required Widget child}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: child,
      ),
    ),
  );
}

/// SAME GLOW FUNCTION
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
