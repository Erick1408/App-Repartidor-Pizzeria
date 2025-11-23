// lib/view/login_page.dart
<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pedidos_provider.dart';
import 'list_pedidos.dart';
=======
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

const String _loginUrl = 'https://backend-pizzeria-production.up.railway.app/api/auth/login';
>>>>>>> 6876e94f5c454d6a1ac15e072a89cc194d903b44

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
<<<<<<< HEAD
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;
  bool _buttonEnabled = false;
  bool _obscure = true;
=======
  bool _isLoading = false;
  bool _buttonEnabled = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
>>>>>>> 6876e94f5c454d6a1ac15e072a89cc194d903b44

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

<<<<<<< HEAD
  Future<void> _signIn() async {
    if (!_buttonEnabled || _isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final provider = Provider.of<PedidosProvider>(context, listen: false);

    final ok = await provider.login(emailController.text.trim(), passwordController.text);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ListPedidos()));
    } else {
      final msg = provider.lastError ?? 'Error al iniciar sesión';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
=======
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
>>>>>>> 6876e94f5c454d6a1ac15e072a89cc194d903b44
    }
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = theme.textTheme;

    // Material icon to use in header — change if you want another icon
    const headerIcon = Icons.local_pizza_outlined;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: theme.cardColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header: Material icon (replaces big "P")
                      Container(
                        height: 88,
                        width: 88,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(color: cs.shadow.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Center(
                          child: Icon(headerIcon, size: 40, color: cs.onPrimaryContainer),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Text('Pizzería Don Mario', style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text('App Repartidor', style: text.bodyMedium?.copyWith(color: text.bodySmall?.color?.withOpacity(0.7))),
                      const SizedBox(height: 20),

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.username],
                              decoration: InputDecoration(
                                labelText: 'Correo',
                                filled: true,
                                isDense: true,
                                fillColor: theme.inputDecorationTheme.fillColor ?? cs.surfaceVariant,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                prefixIcon: Icon(Icons.email_outlined, color: cs.onSurfaceVariant),
                              ),
                              validator: (v) {
                                final s = v?.trim() ?? '';
                                if (s.isEmpty) return 'Ingrese su correo';
                                if (!RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w]{2,4}$').hasMatch(s)) return 'Correo inválido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: passwordController,
                              obscureText: _obscure,
                              autofillHints: const [AutofillHints.password],
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                isDense: true,
                                filled: true,
                                fillColor: theme.inputDecorationTheme.fillColor ?? cs.surfaceVariant,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                prefixIcon: Icon(Icons.lock_outline, color: cs.onSurfaceVariant),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: cs.onSurfaceVariant),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) {
                                final s = v ?? '';
                                if (s.isEmpty) return 'Ingrese su contraseña';
                                if (s.length < 4) return 'Mínimo 4 caracteres';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Buttons
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: FilledButton(
                                onPressed: _buttonEnabled && !_isLoading ? _signIn : null,
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isLoading
                                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: cs.onPrimary, strokeWidth: 2))
                                    : Text('Iniciar sesión', style: text.titleMedium?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.w700)),
                              ),
                            ),

                            const SizedBox(height: 10),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),
                      // Footer small text
                      Text('Versión 1.0.0', style: text.bodySmall?.copyWith(color: text.bodySmall?.color?.withOpacity(0.6))),
                    ],
                  ),
                ),
=======
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
>>>>>>> 6876e94f5c454d6a1ac15e072a89cc194d903b44
              ),
            ),
          ),
        ),
      ),
    );
  }
}
<<<<<<< HEAD
=======

>>>>>>> 6876e94f5c454d6a1ac15e072a89cc194d903b44
