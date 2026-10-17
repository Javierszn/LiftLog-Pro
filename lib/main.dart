import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/liftlog/screens/auth_screen.dart';
import 'features/liftlog/screens/liftlog_shell.dart';
import 'features/liftlog/services/local_database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LiftLogProApp());
}

class LiftLogProApp extends StatelessWidget {
  const LiftLogProApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'LiftLog Pro',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF146B4B), brightness: Brightness.light),
          scaffoldBackgroundColor: const Color(0xFFF5F7F3),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFE7EBE6))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF146B4B), width: 1.5)),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFFE2EFE5),
            labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(fontSize: 11, fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500)),
          ),
          filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: const Color(0xFF146B4B), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)))),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Color(0xFFD7F36B), foregroundColor: Color(0xFF17241E)),
        ),
        home: const _SessionGate(),
      );
}

class _SessionGate extends StatefulWidget {
  const _SessionGate();
  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  Map<String, Object?>? _user;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('liftlog_user_id');
    final user = id == null ? null : await LocalDatabase.instance.userById(id);
    if (mounted) setState(() { _user = user; _ready = true; });
  }

  Future<void> _authenticate(Map<String, Object?> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('liftlog_user_id', user['id'] as int);
    if (mounted) setState(() => _user = user);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_user == null) return AuthScreen(onAuthenticated: _authenticate);
    return LiftLogShell(user: _user!, onSignOut: () => setState(() => _user = null));
  }
}
