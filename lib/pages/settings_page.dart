import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// import 'package:webview_flutter/webview_flutter.dart';
// Import platform specific implementations to prevent the 'null instance' error
// import 'package:webview_flutter_android/webview_flutter_android.dart';
// import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Use 10.0.2.2 if testing on Android Emulator to reach your PC's localhost
  // final String backendUrl = "http://10.0.2.2:5000";
  final String backendUrl = "http://127.0.0.1:5000";
  String _status = "Ready";
  final TextEditingController _manualTokenController = TextEditingController();
  // late final WebViewController _webViewController;

  // Function to get the Login URL from Python and open WebView
  // Future<void> _handleUpstoxLogin() async {
  //   setState(() => _status = "Fetching login URL...");
  //   try {
  //     final response = await http.get(
  //       Uri.parse("$backendUrl/upstox/login-url"),
  //     );
  //     if (response.statusCode == 200) {
  //       final url = jsonDecode(response.body)['url'];
  //       _webViewController.loadRequest(Uri.parse(url));

  //       if (!mounted) return;

  //       // Open the WebView in a Full Screen Dialog
  //       showModalBottomSheet(
  //         context: context,
  //         isScrollControlled: true,
  //         builder: (context) => SizedBox(
  //           height: MediaQuery.of(context).size.height * 0.9,
  //           child: WebViewWidget(controller: _webViewController),
  //         ),
  //       );
  //     } else {
  //       setState(() => _status = "Error: Backend not reachable");
  //     }
  //   } catch (e) {
  //     setState(() => _status = "Error: Check if Python server is running");
  //   }
  // }

  Future<void> _handleUpstoxLogin() async {
    print("Button Clicked!"); // Check if this shows in VS Code Console
    setState(() => _status = "Connecting to backend...");

    try {
      // 1. Try to get the URL
      final response = await http
          .get(Uri.parse("$backendUrl/upstox/login-url"))
          .timeout(const Duration(seconds: 5)); // Don't wait forever

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final url = jsonDecode(response.body)['url'];

        // 2. Open the URL
        // If on WEB, use this:
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

        // If on MOBILE, use this:
        // _webViewController.loadRequest(Uri.parse(url));
        // showModalBottomSheet(
        //   context: context,
        //   builder: (context) => WebViewWidget(controller: _webViewController),
        // );
      } else {
        setState(() => _status = "Backend Error: ${response.statusCode}");
      }
    } catch (e) {
      print("CONNECTION ERROR: $e"); // THIS WILL TELL YOU THE REAL PROBLEM
      setState(() => _status = "Could not connect to Python. Is it running?");
    }
  }

  // Function to send the code to your Python backend
  Future<void> _sendCodeToPython(String code) async {
    setState(() => _status = "Exchanging code for token...");
    try {
      final response = await http.post(
        Uri.parse("$backendUrl/upstox/exchange"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"code": code}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _status = "Login Successful! Token Saved.";
          _manualTokenController.text = data['access_token'];
        });
      } else {
        setState(() => _status = "Failed to exchange code");
      }
    } catch (e) {
      setState(() => _status = "Error connecting to backend");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trading Settings")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Upstox Authentication",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _handleUpstoxLogin,
              icon: const Icon(Icons.vpn_key),
              label: const Text("Generate Access Token"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(15),
              ),
            ),
            const SizedBox(height: 30),
            const Text("Manual Access Token Entry:"),
            TextField(
              controller: _manualTokenController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Access Token will appear here or paste it",
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _sendCodeToPython(_manualTokenController.text),
              child: const Text("Submit Token Manually"),
            ),
            const Spacer(),
            Text(
              "Status: $_status",
              style: TextStyle(
                color: _status.contains("Error") ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
