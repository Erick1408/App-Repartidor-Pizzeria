// lib/view/login_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

const String _loginUrl = 'https://backend-pizzeria-production.up.railway.app/api/auth/login';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  bool _buttonEnabled = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    emailController.addListener(_updateButton);
    passwordController.addListener(_updateButton);
  }

  void _updateButton() {
    final enabled = emailController.text.trim().isNotEmpty && passwordController.text.trim().isNotEmpty;
    if (enabled != _buttonEnabled) setState(() => _buttonEnabled = enabled);
  }

  @override
  void dispose() {
    emailController.removeListener(_updateButton);
    passwordController.removeListener(_updateButton);
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    setState(() => _isLoading = true);
    try {
      final resp = await http.post(
        Uri.parse(_loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"email": emailController.text.trim(), "password": passwordController.text}),
      );
      debugPrint('LOGIN STATUS: ${resp.statusCode}');
      debugPrint('LOGIN BODY: ${resp.body}');

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);
        String? token;
        if (body is Map && body['token'] != null) token = body['token'].toString();

        // Si el backend manda token via cookie, intenta extraer también
        final rawCookie = resp.headers['set-cookie'];
        if ((token == null || token.isEmpty) && rawCookie != null) {
          final m = RegExp(r'token=([^;]+)').firstMatch(rawCookie);
          token = m?.group(1);
        }

        if (token != null && token.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainPage()),
            (r) => false,
          );
          return;
        } else {
          final msg = (body['mensaje'] ?? body['message'] ?? 'Login success pero token faltante').toString();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      } else {
        String msg = 'Credenciales inválidas';
        try {
          final body = json.decode(resp.body);
          msg = (body['mensaje'] ?? body['message'] ?? msg).toString();
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      debugPrint('LOGIN EXCEPTION: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent));
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  const Text('Pizzeria Don Mario', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text('App Repartidor', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 32),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _buttonEnabled ? signIn : null,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, elevation: 0),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Iniciar sesión'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {}, // futuro: recuperar contraseña
                    child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: Colors.black54)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

