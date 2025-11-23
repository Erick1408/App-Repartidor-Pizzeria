// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme.dart';
import 'providers/pedidos_provider.dart';
import 'view/login_page.dart';
import 'view/list_pedidos.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      ),
    );
  }
}
