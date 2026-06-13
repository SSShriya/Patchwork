import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_client.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isResending = false;
  bool _resentSuccess = false;

  Future<void> _resendEmail() async {
    setState(() {
      _isResending = true;
      _resentSuccess = false;
    });

    try {
      await supabase.auth.resend(type: OtpType.signup, email: widget.email);
      if (mounted) setState(() => _resentSuccess = true);
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (mounted) setState(() => _resentSuccess = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: Color(0xFF84DCC6),
              ),
              const SizedBox(height: 24),

              const Text(
                'Verify your university email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'We sent a verification link to:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 6),

              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'Click the link in the email to confirm your '
                'university student status and access the app.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 40),

              // ── Resend success message ─────────────────────────────────
              if (_resentSuccess)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Verification email resent!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF84DCC6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              // ── Resend button ──────────────────────────────────────────
              ElevatedButton(
                onPressed: _isResending ? null : _resendEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF84DCC6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isResending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'RESEND EMAIL',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
              ),
              const SizedBox(height: 12),

              // ── Wrong email — go back ──────────────────────────────────
              TextButton(
                onPressed: _logout,
                child: Text(
                  'Wrong email? Go back to sign up',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
