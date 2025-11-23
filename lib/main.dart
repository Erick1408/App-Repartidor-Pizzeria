// lib/main.dart
<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme.dart';
import 'providers/pedidos_provider.dart';
import 'view/login_page.dart';
import 'view/list_pedidos.dart';

void main() {
=======
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
// import wiew
import 'view/list_pedidos.dart';
import 'view/login_page.dart';

void main() async {
>>>>>>> 6876e94f5c454d6a1ac15e072a89cc194d903b44
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
<<<<<<< HEAD

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PedidosProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Repartidor Pizzería',

        // Tema Material 3 minimalista
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.system, // respeta modo oscuro del dispositivo

        // Página inicial (login)
        home: const LoginPage(),

        // Rutas opcionales si deseas navegación por nombre
        routes: {
          '/login': (_) => const LoginPage(),
          '/pedidos': (_) => const ListPedidos(),
        },
=======
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "PIZZERIA DON MARIO",
      debugShowCheckedModeBanner: false,
      home: const MainPage(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
>>>>>>> 6876e94f5c454d6a1ac15e072a89cc194d903b44
      ),
    );
  }
}
<<<<<<< HEAD
=======

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final String _baseUrl = 'https://backend-pizzeria-production.up.railway.app/api';
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final token = _prefs.getString('token');

    if (token == null) {
      _goToLogin();
      return;
    }

    await _fetchProfile();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ListPedidos()),
    );
  }

  Future<void> _fetchProfile() async {
    final token = _prefs.getString('token');
    if (token == null) return;

    try {
      final url = Uri.parse('$_baseUrl/auth/profile');
      final resp = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Cookie': 'token=$token',
        },
      );
      debugPrint("PROFILE → ${resp.statusCode}: ${resp.body}");
    } catch (_) {}
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
>>>>>>> 6876e94f5c454d6a1ac15e072a89cc194d903b44
