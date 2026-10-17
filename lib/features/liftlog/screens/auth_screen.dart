import 'package:flutter/material.dart';

import '../services/local_database.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.onAuthenticated});
  final ValueChanged<Map<String, Object?>> onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registering = false;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      Map<String, Object?>? user;
      if (_registering) {
        final id = await LocalDatabase.instance.register(_name.text, _email.text, _password.text);
        user = {'id': id, 'name': _name.text.trim(), 'email': _email.text.trim().toLowerCase(), 'goal': 4};
      } else {
        user = await LocalDatabase.instance.signIn(_email.text, _password.text);
      }
      if (!mounted) return;
      if (user == null) {
        _message('Correo o contraseña incorrectos.');
      } else {
        widget.onAuthenticated(user);
      }
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().contains('EMAIL_ALREADY_EXISTS') ||
              error.toString().toLowerCase().contains('unique constraint')
          ? 'Ese correo ya tiene una cuenta. Inicia sesión.'
          : 'No se pudo crear la cuenta. Intenta de nuevo.';
      _message(message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 58, height: 58, decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(19)), child: const Icon(Icons.fitness_center, color: Colors.white, size: 29)),
                const SizedBox(height: 34),
                Text(_registering ? 'Empieza tu\nprogreso.' : 'Entrena con\nintencion.', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.08, letterSpacing: -1.3)),
                const SizedBox(height: 12),
                Text(_registering ? 'Crea tu cuenta y lleva tu evolución en un solo lugar.' : 'Tu entrenamiento, tus marcas y tu progreso. Todo en orden.', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 15, height: 1.5)),
                const SizedBox(height: 32),
                SegmentedButton<bool>(
                  segments: const [ButtonSegment(value: false, label: Text('Iniciar sesión')), ButtonSegment(value: true, label: Text('Crear cuenta'))],
                  selected: {_registering},
                  onSelectionChanged: (value) => setState(() => _registering = value.first),
                ),
                const SizedBox(height: 24),
                Form(key: _formKey, child: Column(children: [
                  if (_registering) ...[
                    TextFormField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline)), validator: (v) => v == null || v.trim().length < 2 ? 'Escribe tu nombre.' : null),
                    const SizedBox(height: 14),
                  ],
                  TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo electronico', prefixIcon: Icon(Icons.alternate_email)), validator: (v) => v == null || !v.contains('@') ? 'Escribe un correo valido.' : null),
                  const SizedBox(height: 14),
                  TextFormField(controller: _password, obscureText: _obscure, decoration: InputDecoration(labelText: 'Contraseña', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined))), validator: (v) => v == null || v.length < 6 ? 'Usa al menos 6 caracteres.' : null),
                  const SizedBox(height: 22),
                  SizedBox(width: double.infinity, height: 54, child: FilledButton(onPressed: _busy ? null : _submit, child: _busy ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_registering ? 'Crear mi cuenta' : 'Entrar', style: const TextStyle(fontWeight: FontWeight.w700)))),
                ])),
                const SizedBox(height: 20),
                Center(child: Text('LiftLog Pro · Tu constancia, en datos', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
