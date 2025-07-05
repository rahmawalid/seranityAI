// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:ui_screens_grad/services/doctor_service.dart';
import 'login.dart';

class ConfirmationScreen extends StatefulWidget {
  final String email;
  final String? doctorId;

  const ConfirmationScreen({
    Key? key,
    required this.email,
    this.doctorId,
  }) : super(key: key);

  @override
  _ConfirmationScreenState createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  bool _isResending = false;
  String? _resendMessage;
  bool _canResend = true;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    _startResendCooldown(60);
  }

  void _startResendCooldown(int seconds) {
    setState(() {
      _canResend = false;
      _resendCooldown = seconds;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCooldown--;
        });
        return _resendCooldown > 0;
      }
      return false;
    }).then((_) {
      if (mounted) {
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend || _isResending) return;

    setState(() {
      _isResending = true;
      _resendMessage = null;
    });

    try {
      final doctorService = DoctorService();
      final success = await doctorService.resendVerificationEmail(widget.email);

      if (success) {
        setState(() {
          _resendMessage = 'Verification email sent successfully!';
        });
        _startResendCooldown(60);
      } else {
        setState(() {
          _resendMessage = 'Failed to send verification email. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _resendMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isResending = false;
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _resendMessage = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorIdDisplay =
        widget.doctorId != null ? 'Your ID: ${widget.doctorId}' : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Your Email'),
        backgroundColor: const Color(0xFF2F3C58),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_read,
                  size: 100, color: Color(0xFF2F3C58)),
              const SizedBox(height: 20),
              Text(
                'A verification email has been sent to:',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.subtitle1,
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (doctorIdDisplay.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  doctorIdDisplay,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _canResend ? _resendVerificationEmail : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _canResend ? const Color(0xFF2F3C58) : Colors.grey,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                child: _isResending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _canResend
                            ? 'Resend Email'
                            : 'Wait $_resendCooldown seconds',
                        style: const TextStyle(color: Colors.white),
                      ),
              ),
              if (_resendMessage != null) ...[
                const SizedBox(height: 20),
                Text(
                  _resendMessage!,
                  style: TextStyle(
                    color: _resendMessage!.toLowerCase().contains('error') ||
                            _resendMessage!.toLowerCase().contains('fail')
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
              ],
              const SizedBox(height: 40),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
