import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tradelogic/pages/login_page.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  final String backendUrl = "http://127.0.0.1:4000";
  // final String backendUrl = "http://172.20.10.2:4000";
  // final String backendUrl = "https://tradelogic-sever.onrender.com";
  final _auth = FirebaseAuth.instance;

  // Broker state
  String _status = "Generated";
  final TextEditingController _manualTokenController = TextEditingController();
  bool _tokenObscured = true;

  // Account sheet controllers
  final TextEditingController _newUsernameController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _currentPwObscured = true;
  bool _newPwObscured = true;
  bool _confirmPwObscured = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _manualTokenController.dispose();
    _newUsernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ── STATUS HELPERS ────────────────────────────────────────────────────────

  bool get _isError => _status.contains("Fail") || _status.contains("Error");
  bool get _isSuccess =>
      _status.contains("Successful") || _status.contains("Generated");

  Color get _statusColor {
    if (_isError) return const Color(0xFFFF5252);
    if (_isSuccess) return const Color(0xFF00C853);
    return const Color(0xFFFFAB00);
  }

  IconData get _statusIcon {
    if (_isError) return Icons.error_outline_rounded;
    if (_isSuccess) return Icons.check_circle_outline_rounded;
    return Icons.sync_rounded;
  }

  // ── BROKER METHODS ────────────────────────────────────────────────────────

  Future<void> _handleUpstoxLogin() async {
    setState(() => _status = "Connecting...");
    try {
      final response = await http
          .get(Uri.parse("$backendUrl/upstox/login-url"))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final url = jsonDecode(response.body)['url'];
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        setState(() => _status = "Browser opened");
      } else {
        setState(() => _status = "Backend Error");
      }
    } catch (e) {
      setState(() => _status = "Connection Failed");
    }
  }

  Future<void> _sendCodeToPython(String code) async {
    if (code.trim().isEmpty) return;
    setState(() => _status = "Exchanging code...");
    try {
      final response = await http.post(
        Uri.parse("$backendUrl/upstox/exchange"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"code": code}),
      );

      await http.get(Uri.parse("$backendUrl/callback"));

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

  // ── ACCOUNT METHODS ───────────────────────────────────────────────────────

  Future<void> _changeUsername() async {
    final newName = _newUsernameController.text.trim();
    if (newName.isEmpty) return;
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await FirebaseDatabase.instance
          .ref()
          .child("users")
          .child(user.uid)
          .child("username")
          .set(newName);
      if (mounted) {
        Navigator.pop(context);
        _showToast("Username updated successfully", isSuccess: true);
      }
    } catch (e) {
      _showToast("Failed to update username", isSuccess: false);
    }
  }

  Future<void> _changePassword() async {
    final current = _currentPasswordController.text.trim();
    final newPw = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();
    if (current.isEmpty || newPw.isEmpty || confirm.isEmpty) {
      _showToast("Please fill all fields", isSuccess: false);
      return;
    }
    if (newPw != confirm) {
      _showToast("Passwords don't match", isSuccess: false);
      return;
    }
    if (newPw.length < 6) {
      _showToast("Password must be at least 6 characters", isSuccess: false);
      return;
    }
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;
    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: current,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPw);
      if (mounted) {
        Navigator.pop(context);
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _showToast("Password changed successfully", isSuccess: true);
      }
    } on FirebaseAuthException catch (e) {
      _showToast(
        e.code == 'wrong-password'
            ? "Current password is incorrect"
            : "Error: ${e.message}",
        isSuccess: false,
      );
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  void _showToast(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isSuccess
            ? const Color(0xFF00C853)
            : const Color(0xFFFF5252),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── BOTTOM SHEETS ─────────────────────────────────────────────────────────

  void _showChangeUsernameSheet() {
    _newUsernameController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHandle(),
            const SizedBox(height: 20),
            _sheetTitle(
              "Change Username",
              "Enter a new display name for your account",
            ),
            const SizedBox(height: 20),
            _sheetTextField(
              controller: _newUsernameController,
              hint: "New username",
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 16),
            _sheetButton(
              label: "Update Username",
              color: const Color(0xFF00C853),
              onTap: _changeUsername,
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordSheet() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              const SizedBox(height: 20),
              _sheetTitle(
                "Change Password",
                "You'll need to re-login after changing your password",
              ),
              const SizedBox(height: 20),
              _sheetTextField(
                controller: _currentPasswordController,
                hint: "Current password",
                icon: Icons.lock_outline_rounded,
                obscure: _currentPwObscured,
                onToggle: () => setSheetState(
                  () => _currentPwObscured = !_currentPwObscured,
                ),
              ),
              const SizedBox(height: 12),
              _sheetTextField(
                controller: _newPasswordController,
                hint: "New password",
                icon: Icons.lock_reset_rounded,
                obscure: _newPwObscured,
                onToggle: () =>
                    setSheetState(() => _newPwObscured = !_newPwObscured),
              ),
              const SizedBox(height: 12),
              _sheetTextField(
                controller: _confirmPasswordController,
                hint: "Confirm new password",
                icon: Icons.check_circle_outline_rounded,
                obscure: _confirmPwObscured,
                onToggle: () => setSheetState(
                  () => _confirmPwObscured = !_confirmPwObscured,
                ),
              ),
              const SizedBox(height: 16),
              _sheetButton(
                label: "Update Password",
                color: const Color(0xFF448AFF),
                onTap: _changePassword,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Log Out",
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: const Text(
          "Are you sure you want to log out of your account?",
          style: TextStyle(color: Color(0xFF555F6E), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(
                color: Color(0xFF9E9E9E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Log Out",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // ── APP BAR ─────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              floating: false,
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00C853).withOpacity(0.12),
                      ),
                      child: const CircleAvatar(
                        radius: 20,
                        backgroundImage: AssetImage('images/logo.png'),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Settings",
                      style: TextStyle(
                        color: Color(0xFF1A1A2E),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ── PROFILE BANNER ─────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0D1B2A), Color(0xFF1B2A3B)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D1B2A).withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C853).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                (user?.email ?? "U")
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF00C853),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.email ?? "Not logged in",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF00C853,
                                    ).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF00C853),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      const Text(
                                        "Active Account",
                                        style: TextStyle(
                                          color: Color(0xFF00C853),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── TOKEN STATUS BANNER ────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _statusColor.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(_statusIcon, color: _statusColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _status,
                              style: TextStyle(
                                color: _statusColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (!_isError && !_isSuccess)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _statusColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── SECTION: ACCOUNT ───────────────────────────────
                  _sectionHeader("Account"),
                  const SizedBox(height: 12),

                  _settingsCard(
                    child: Column(
                      children: [
                        _accountTile(
                          icon: Icons.person_outline_rounded,
                          iconColor: const Color(0xFF00C853),
                          label: "Change Username",
                          subtitle: "Update your display name",
                          onTap: _showChangeUsernameSheet,
                        ),
                        const Divider(
                          height: 1,
                          indent: 52,
                          color: Color(0xFFF5F5F5),
                        ),
                        _accountTile(
                          icon: Icons.lock_outline_rounded,
                          iconColor: const Color(0xFF448AFF),
                          label: "Change Password",
                          subtitle: "Update your login password",
                          onTap: _showChangePasswordSheet,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── SECTION: BROKER CONNECTION ─────────────────────
                  _sectionHeader("Broker Connection"),
                  const SizedBox(height: 12),

                  _settingsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6236FF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.account_balance_rounded,
                                color: Color(0xFF6236FF),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 13),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Upstox",
                                    style: TextStyle(
                                      color: Color(0xFF1A1A2E),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    "Connect your trading account",
                                    style: TextStyle(
                                      color: Color(0xFF9E9E9E),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _isSuccess
                                    ? const Color(0xFF00C853).withOpacity(0.1)
                                    : const Color(0xFFEEEEEE),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isSuccess
                                          ? const Color(0xFF00C853)
                                          : const Color(0xFFBBBBBB),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _isSuccess ? "Active" : "Inactive",
                                    style: TextStyle(
                                      color: _isSuccess
                                          ? const Color(0xFF00C853)
                                          : const Color(0xFF9E9E9E),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Divider(height: 1, color: Color(0xFFF0F0F0)),
                        const SizedBox(height: 18),
                        _stepRow(
                          "1",
                          "Open Upstox Login",
                          "Opens browser to authenticate",
                        ),
                        const SizedBox(height: 10),
                        _stepRow(
                          "2",
                          "Copy the code from URL",
                          "After login, paste the code below",
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _handleUpstoxLogin,
                            icon: const Icon(
                              Icons.vpn_key_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Generate Access Token",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6236FF),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── SECTION: MANUAL TOKEN ──────────────────────────
                  _sectionHeader("Manual Token Entry"),
                  const SizedBox(height: 12),

                  _settingsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C853).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.key_rounded,
                                color: Color(0xFF00C853),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 13),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Access Token",
                                  style: TextStyle(
                                    color: Color(0xFF1A1A2E),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  "Paste your token manually",
                                  style: TextStyle(
                                    color: Color(0xFF9E9E9E),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _manualTokenController,
                          obscureText: _tokenObscured,
                          style: const TextStyle(
                            color: Color(0xFF1A1A2E),
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                          decoration: InputDecoration(
                            hintText: "Paste access token here",
                            hintStyle: const TextStyle(
                              color: Color(0xFFBBBBBB),
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF5F6FA),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _tokenObscured
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 18,
                                color: const Color(0xFF9E9E9E),
                              ),
                              onPressed: () => setState(
                                () => _tokenObscured = !_tokenObscured,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFEEEEEE),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFEEEEEE),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF00C853),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _sendCodeToPython(_manualTokenController.text),
                            icon: const Icon(
                              Icons.send_rounded,
                              size: 17,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Submit Token",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C853),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── SECTION: SERVER CONFIG ─────────────────────────
                  _sectionHeader("Server Configuration"),
                  const SizedBox(height: 12),

                  _settingsCard(
                    child: Column(
                      children: [
                        _infoRow(
                          icon: Icons.dns_rounded,
                          iconColor: const Color(0xFF448AFF),
                          label: "Data Server",
                          value: backendUrl,
                        ),
                        const Divider(height: 20, color: Color(0xFFF0F0F0)),
                        _infoRow(
                          icon: Icons.flash_on_rounded,
                          iconColor: const Color(0xFFFFAB00),
                          label: "Trading Engine",
                          value: "http://172.20.10.2:5000",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── LOGOUT BUTTON ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _showLogoutDialog,
                        icon: const Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: Color(0xFFFF5252),
                        ),
                        label: const Text(
                          "Log Out",
                          style: TextStyle(
                            color: Color(0xFFFF5252),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFFFF5252),
                            width: 1.5,
                          ),
                          backgroundColor: const Color(
                            0xFFFF5252,
                          ).withOpacity(0.04),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Center(
                    child: Text(
                      "TradeLogic v1.0.0",
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── REUSABLE WIDGETS ──────────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF555F6E),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _settingsCard({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _accountTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFFBBBBBB),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepRow(String number, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF6236FF).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF6236FF),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.copy_rounded,
            size: 14,
            color: Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }

  // ── SHEET HELPERS ─────────────────────────────────────────────────────────

  Widget _sheetHandle() => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _sheetTitle(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1A1A2E),
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
      ),
    ],
  );

  Widget _sheetTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    VoidCallback? onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF9E9E9E)),
        suffixIcon: onToggle != null
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: const Color(0xFF9E9E9E),
                ),
                onPressed: onToggle,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00C853), width: 1.5),
        ),
      ),
    );
  }

  Widget _sheetButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) => SizedBox(
    width: double.infinity,
    height: 48,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        elevation: 0,
        shadowColor: color.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
