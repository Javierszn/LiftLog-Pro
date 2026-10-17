import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/lift_entry.dart';
import '../services/local_database.dart';

const _ink = Color(0xFF17241E);
const _green = Color(0xFF146B4B);
const _paper = Color(0xFFF5F7F3);

class LiftLogShell extends StatefulWidget {
  const LiftLogShell({super.key, required this.user, required this.onSignOut});
  final Map<String, Object?> user;
  final VoidCallback onSignOut;

  @override
  State<LiftLogShell> createState() => _LiftLogShellState();
}

class _LiftLogShellState extends State<LiftLogShell> {
  int _page = 0;
  late Map<String, Object?> _user;
  List<LiftEntry> _entries = [];
  List<Map<String, Object?>> _photos = [];
  bool _loading = true;

  int get _userId => _user['id'] as int;
  int get _goal => _user['goal'] as int? ?? 4;

  @override
  void initState() {
    super.initState();
    _user = Map<String, Object?>.from(widget.user);
    _refresh();
  }

  Future<void> _refresh() async {
    final results = await Future.wait([
      LocalDatabase.instance.exercises(_userId),
      LocalDatabase.instance.photos(_userId),
    ]);
    if (!mounted) return;
    setState(() {
      _entries = results[0] as List<LiftEntry>;
      _photos = results[1] as List<Map<String, Object?>>;
      _loading = false;
    });
  }

  Future<void> _saveEntry(LiftEntry entry) async {
    await LocalDatabase.instance.saveExercise(_userId, entry);
    await _refresh();
    if (mounted) _notice(entry.id == null ? 'Ejercicio agregado a tu rutina.' : 'Cambios guardados.');
  }

  Future<void> _deleteEntry(LiftEntry entry) async {
    await LocalDatabase.instance.deleteExercise(_userId, entry.id!);
    await _refresh();
    if (mounted) _notice('${entry.name} se elimino de la rutina.');
  }

  void _notice(String text, {SnackBarAction? action}) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), action: action, behavior: SnackBarBehavior.floating));

  Future<void> _editEntry([LiftEntry? entry]) async {
    final result = await showModalBottomSheet<LiftEntry>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => _ExerciseForm(entry: entry));
    if (result != null) await _saveEntry(result);
  }

  Future<void> _toggleEntry(LiftEntry entry) async {
    await LocalDatabase.instance.saveExercise(_userId, LiftEntry(id: entry.id, name: entry.name, muscleGroup: entry.muscleGroup, sets: entry.sets, reps: entry.reps, weight: entry.weight, day: entry.day, completed: !entry.completed, createdAt: entry.createdAt));
    await _refresh();
  }

  Future<void> _capturePhoto() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1800);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final dataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      await LocalDatabase.instance.savePhoto(_userId, dataUri);
      await _refresh();
      if (mounted) _notice('Foto guardada en tu progreso.');
    } catch (_) {
      if (mounted) _notice('No se pudo abrir la cámara. Revisa los permisos del dispositivo.');
    }
  }

  Future<void> _deletePhoto(Map<String, Object?> photo) async {
    final id = photo['id'] as int;
    await LocalDatabase.instance.deletePhoto(_userId, id);
    await _refresh();
  }

  Future<void> _updateProfile() async {
    final result = await showDialog<Map<String, Object?>>(context: context, builder: (_) => _ProfileDialog(user: _user));
    if (result == null) return;
    await LocalDatabase.instance.updateUser(_userId, name: result['name'] as String, goal: result['goal'] as int);
    setState(() => _user = {..._user, ...result});
    _notice('Perfil actualizado.');
  }

  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('liftlog_user_id');
    widget.onSignOut();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _dashboard(),
      _routines(),
      _progress(),
      _profile(),
    ];
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final content = Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1060), child: _loading ? const Center(child: CircularProgressIndicator()) : pages[_page]));
          if (!wide) return content;
          return Row(children: [
            NavigationRail(
              selectedIndex: _page,
              onDestinationSelected: (value) => setState(() => _page = value),
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.white,
              leading: Padding(padding: const EdgeInsets.symmetric(vertical: 22), child: _BrandMark(compact: true)),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.grid_view_rounded), label: Text('Resumen')),
                NavigationRailDestination(icon: Icon(Icons.fitness_center_rounded), label: Text('Rutinas')),
                NavigationRailDestination(icon: Icon(Icons.photo_library_outlined), label: Text('Progreso')),
                NavigationRailDestination(icon: Icon(Icons.person_outline_rounded), label: Text('Perfil')),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: content),
          ]);
        }),
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width >= 760 ? null : NavigationBar(
        selectedIndex: _page,
        onDestinationSelected: (value) => setState(() => _page = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Resumen'),
          NavigationDestination(icon: Icon(Icons.fitness_center_rounded), label: 'Rutinas'),
          NavigationDestination(icon: Icon(Icons.photo_library_outlined), label: 'Progreso'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _pageHeader(String eyebrow, String title, {Widget? trailing}) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _BrandMark(),
            const SizedBox(height: 24),
            Text(eyebrow.toUpperCase(), style: const TextStyle(color: _green, fontSize: 11, letterSpacing: 1.7, fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            Text(title, style: const TextStyle(color: _ink, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
          ])),
          ?trailing,
        ]),
      );

  Widget _dashboard() {
    final completed = _entries.where((e) => e.completed).length;
    final today = _todayName();
    final todayEntries = _entries.where((e) => e.day == today).toList();
    final volume = _entries.fold<double>(0, (sum, e) => sum + e.weight * e.sets * e.reps);
    return ListView(padding: EdgeInsets.zero, children: [
      _pageHeader('Tu espacio de entrenamiento', 'Hola, ${(_user['name'] as String).split(' ').first}.', trailing: IconButton.filledTonal(onPressed: _updateProfile, icon: const Icon(Icons.tune_rounded))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: _heroCard(completed, volume)),
      Padding(padding: const EdgeInsets.fromLTRB(22, 25, 22, 10), child: _sectionHeading('Tu semana', 'Meta: $_goal sesiones', action: 'Editar meta', onAction: _updateProfile)),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: _weekCard()),
      Padding(padding: const EdgeInsets.fromLTRB(22, 26, 22, 10), child: _sectionHeading('Rutina de hoy', '$today · ${todayEntries.length} ejercicios', action: 'Ver rutina', onAction: () => setState(() => _page = 1))),
      if (todayEntries.isEmpty)
        Padding(padding: const EdgeInsets.fromLTRB(22, 4, 22, 22), child: _emptyCard('Aún no hay ejercicios para $today.', action: 'Agregar ejercicio', onTap: () => _editEntry()))
      else
        ...todayEntries.take(3).map((entry) => Padding(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 5), child: _exerciseTile(entry))),
      const SizedBox(height: 22),
    ]);
  }

  Widget _heroCard(int completed, double volume) => Container(
        padding: const EdgeInsets.all(23),
        decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(25), gradient: const LinearGradient(colors: [Color(0xFF18372B), Color(0xFF101A16)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Expanded(child: Text('CONSISTENCIA EN ACCIÓN', style: TextStyle(color: Color(0xFFB6D6C7), fontSize: 10, letterSpacing: 1.7, fontWeight: FontWeight.w800))), Icon(Icons.bolt_rounded, color: Colors.lime.shade300)]),
          const SizedBox(height: 19),
          Text('$completed', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800, height: 1)),
          const SizedBox(height: 5),
          const Text('ejercicios completados', style: TextStyle(color: Color(0xFFD1DDD6), fontSize: 14)),
          const SizedBox(height: 21),
          Row(children: [
            _heroMetric(Icons.fitness_center_rounded, '${_entries.length}', 'en tu plan'),
            const SizedBox(width: 25),
            _heroMetric(Icons.monitor_weight_outlined, '${_formatNumber(volume)} kg', 'volumen registrado'),
            const Spacer(),
            IconButton.filled(onPressed: () => setState(() => _page = 1), style: IconButton.styleFrom(backgroundColor: const Color(0xFFD7F36B), foregroundColor: _ink), icon: const Icon(Icons.arrow_forward_rounded)),
          ]),
        ]),
      );

  Widget _heroMetric(IconData icon, String value, String label) => Row(children: [
        Icon(icon, size: 18, color: const Color(0xFFD7F36B)),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)), Text(label, style: const TextStyle(color: Color(0xFFB6C4BC), fontSize: 10))]),
      ]);

  Widget _weekCard() => Container(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: List.generate(7, (i) {
            final date = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1 - i));
            final day = _dayForWeekday(i + 1);
            final hasWorkout = _entries.any((entry) => entry.day == day);
            final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month;
            return Column(children: [Text(const ['L', 'M', 'M', 'J', 'V', 'S', 'D'][i], style: TextStyle(fontSize: 11, color: isToday ? _green : Colors.black45, fontWeight: FontWeight.w700)), const SizedBox(height: 10), Container(width: 32, height: 32, alignment: Alignment.center, decoration: BoxDecoration(color: hasWorkout ? _green : (isToday ? const Color(0xFFE7EEE7) : _paper), shape: BoxShape.circle, border: isToday && !hasWorkout ? Border.all(color: _green) : null), child: hasWorkout ? const Icon(Icons.check_rounded, size: 17, color: Colors.white) : Text('${date.day}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),]);
          })),
          const SizedBox(height: 15),
          ClipRRect(borderRadius: BorderRadius.circular(9), child: LinearProgressIndicator(value: (_entries.map((e) => e.day).toSet().length / _goal).clamp(0, 1), minHeight: 5, backgroundColor: const Color(0xFFE8ECE8), color: _green)),
        ]),
      );

  Widget _routines() {
    final byDay = <String, List<LiftEntry>>{};
    for (final entry in _entries) {
      byDay.putIfAbsent(entry.day, () => []).add(entry);
    }
    final order = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return Scaffold(backgroundColor: _paper, floatingActionButton: FloatingActionButton.extended(onPressed: () => _editEntry(), icon: const Icon(Icons.add_rounded), label: const Text('Ejercicio')), body: _loading ? const Center(child: CircularProgressIndicator()) : CustomScrollView(slivers: [
      SliverToBoxAdapter(child: _pageHeader('Planifica y registra', 'Mis rutinas.')),
      if (_entries.isEmpty)
        SliverFillRemaining(hasScrollBody: false, child: Padding(padding: const EdgeInsets.fromLTRB(22, 0, 22, 100), child: _emptyCard('Tu plan comienza con un ejercicio.', action: 'Crear ejercicio', onTap: () => _editEntry())))
      else
        for (final day in order.where(byDay.containsKey)) ...[
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(22, 13, 22, 8), child: _sectionHeading(day, '${byDay[day]!.length} ejercicios'))),
          SliverList.builder(itemCount: byDay[day]!.length, itemBuilder: (context, index) {
            final entry = byDay[day]![index];
            return Padding(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 5), child: Dismissible(key: ValueKey(entry.id), direction: DismissDirection.endToStart, background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 23), decoration: BoxDecoration(color: const Color(0xFFF5DAD5), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.delete_outline_rounded, color: Color(0xFF9F3B2A))), onDismissed: (_) => _deleteEntry(entry), child: _exerciseTile(entry, onEdit: () => _editEntry(entry))));
          }),
        ],
      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ]));
  }

  Widget _exerciseTile(LiftEntry entry, {VoidCallback? onEdit}) => Card(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          leading: InkWell(onTap: () => _toggleEntry(entry), borderRadius: BorderRadius.circular(14), child: Container(width: 44, height: 44, decoration: BoxDecoration(color: entry.completed ? const Color(0xFFE3F0E9) : _paper, borderRadius: BorderRadius.circular(14)), child: Icon(entry.completed ? Icons.check_rounded : Icons.fitness_center_rounded, color: _green, size: 21))),
          title: Text(entry.name, style: TextStyle(fontWeight: FontWeight.w700, decoration: entry.completed ? TextDecoration.lineThrough : null)),
          subtitle: Text('${entry.muscleGroup}  ·  ${entry.sets} × ${entry.reps}  ·  ${_formatNumber(entry.weight)} kg', style: const TextStyle(height: 1.8, fontSize: 12)),
          trailing: IconButton(onPressed: onEdit ?? () => _editEntry(entry), icon: const Icon(Icons.more_horiz_rounded)),
          onTap: () => _editEntry(entry),
        ),
      );

  Widget _progress() => ListView(padding: EdgeInsets.zero, children: [
        _pageHeader('Tu progreso visual', 'Cada etapa cuenta.', trailing: IconButton.filled(onPressed: _capturePhoto, icon: const Icon(Icons.photo_camera_outlined))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFE6EFE7), borderRadius: BorderRadius.circular(22)), child: const Row(children: [Icon(Icons.tips_and_updates_outlined, color: _green), SizedBox(width: 13), Expanded(child: Text('Toma tus fotos con luz y ángulo similares para comparar tu evolución con más claridad.', style: TextStyle(color: _ink, height: 1.45, fontSize: 13)))]))),
        Padding(padding: const EdgeInsets.fromLTRB(22, 25, 22, 12), child: _sectionHeading('Registro visual', '${_photos.length} ${_photos.length == 1 ? 'foto' : 'fotos'}')),
        if (_photos.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: _emptyCard('Aún no has guardado fotos.', action: 'Abrir cámara', onTap: _capturePhoto))
        else
          Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth > 650 ? 3 : 2;
            return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _photos.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 9, mainAxisSpacing: 9, childAspectRatio: .83), itemBuilder: (context, index) {
              final photo = _photos[index];
              final encodedImage = (photo['file_path'] as String).split(',').last;
              final date = DateTime.tryParse(photo['created_at'] as String? ?? '');
              return GestureDetector(onLongPress: () => _confirmDeletePhoto(photo), child: ClipRRect(borderRadius: BorderRadius.circular(17), child: Stack(fit: StackFit.expand, children: [Image.memory(base64Decode(encodedImage), fit: BoxFit.cover), Align(alignment: Alignment.bottomCenter, child: Container(height: 70, decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xAA101A16)])))), Positioned(left: 11, bottom: 11, child: Text(date == null ? 'Progreso' : '${date.day} ${_monthName(date.month)} ${date.year}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))), Positioned(right: 4, top: 4, child: IconButton.filledTonal(onPressed: () => _confirmDeletePhoto(photo), iconSize: 18, visualDensity: VisualDensity.compact, icon: const Icon(Icons.delete_outline_rounded)))])));
            });
          })),
        Padding(padding: const EdgeInsets.all(22), child: OutlinedButton.icon(onPressed: _capturePhoto, icon: const Icon(Icons.add_a_photo_outlined), label: const Text('Tomar foto de progreso'))),
      ]);

  Future<void> _confirmDeletePhoto(Map<String, Object?> photo) async {
    final remove = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Eliminar foto'), content: const Text('Esta foto se quitará de tu historial visual.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar'))]));
    if (remove == true) await _deletePhoto(photo);
  }

  Widget _profile() => ListView(padding: EdgeInsets.zero, children: [
        _pageHeader('Tu cuenta', 'Perfil y ajustes.'),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(24)), child: Row(children: [CircleAvatar(radius: 30, backgroundColor: const Color(0xFFD7F36B), child: Text((_user['name'] as String).isEmpty ? 'L' : (_user['name'] as String)[0].toUpperCase(), style: const TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 22))), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_user['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(_user['email'] as String, style: const TextStyle(color: Color(0xFFC5D2CB), fontSize: 12))])), IconButton(onPressed: _updateProfile, color: Colors.white, icon: const Icon(Icons.edit_outlined))]))),
        Padding(padding: const EdgeInsets.fromLTRB(22, 25, 22, 10), child: _sectionHeading('Preferencias', 'Personaliza tu plan')),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: Card(color: Colors.white, elevation: 0, child: Column(children: [ListTile(leading: const Icon(Icons.flag_outlined, color: _green), title: const Text('Meta semanal', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('$_goal sesiones de entrenamiento'), trailing: const Icon(Icons.chevron_right_rounded), onTap: _updateProfile), const Divider(height: 1, indent: 55), const ListTile(leading: Icon(Icons.storage_outlined, color: _green), title: Text('Tus datos', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('Guardados de forma local en este dispositivo'))]))),
        Padding(padding: const EdgeInsets.fromLTRB(22, 26, 22, 40), child: OutlinedButton.icon(onPressed: _signOut, icon: const Icon(Icons.logout_rounded), label: const Text('Cerrar sesión'), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF9F3B2A), padding: const EdgeInsets.all(15)))),
      ]);

  Widget _sectionHeading(String title, String detail, {String? action, VoidCallback? onAction}) => Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 16)), const SizedBox(height: 3), Text(detail, style: const TextStyle(color: Colors.black54, fontSize: 11))])), if (action != null) TextButton(onPressed: onAction, child: Text(action))]);

  Widget _emptyCard(String text, {required String action, required VoidCallback onTap}) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(text, style: const TextStyle(color: _ink)), const SizedBox(height: 10), TextButton.icon(onPressed: onTap, icon: const Icon(Icons.add_rounded), label: Text(action))]));

  String _todayName() => _dayForWeekday(DateTime.now().weekday);
  String _dayForWeekday(int weekday) => const ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'][weekday - 1];
  String _monthName(int month) => const ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'][month - 1];
  String _formatNumber(double number) => number == number.roundToDouble() ? number.toInt().toString() : number.toStringAsFixed(1);
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 30, height: 30, decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 16)), if (!compact) ...[const SizedBox(width: 9), const Text('LIFTLOG', style: TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)), const SizedBox(width: 4), const Text('PRO', style: TextStyle(color: _green, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2))]]);
}

class _ExerciseForm extends StatefulWidget {
  const _ExerciseForm({this.entry});
  final LiftEntry? entry;
  @override
  State<_ExerciseForm> createState() => _ExerciseFormState();
}

class _ExerciseFormState extends State<_ExerciseForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.entry?.name);
  late final _sets = TextEditingController(text: '${widget.entry?.sets ?? 3}');
  late final _reps = TextEditingController(text: '${widget.entry?.reps ?? 10}');
  late final _weight = TextEditingController(text: '${widget.entry?.weight ?? 0}');
  late String _day = widget.entry?.day ?? _weekdayToday();
  late String _muscle = widget.entry?.muscleGroup ?? 'Pecho';
  static const _days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  static const _groups = ['Pecho', 'Espalda', 'Hombro', 'Bíceps', 'Tríceps', 'Pierna', 'Abdomen', 'Cuerpo completo'];

  String _weekdayToday() => _days[DateTime.now().weekday - 1];

  @override
  void dispose() { _name.dispose(); _sets.dispose(); _reps.dispose(); _weight.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(padding: EdgeInsets.fromLTRB(22, 12, 22, MediaQuery.viewInsetsOf(context).bottom + 20), child: Form(key: _form, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
    Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4))),),
    const SizedBox(height: 21), Text(widget.entry == null ? 'Nuevo ejercicio' : 'Editar ejercicio', style: const TextStyle(fontSize: 23, color: _ink, fontWeight: FontWeight.w800)), const SizedBox(height: 18),
    TextFormField(controller: _name, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Nombre del ejercicio', prefixIcon: Icon(Icons.fitness_center_rounded)), validator: (v) => v == null || v.trim().isEmpty ? 'Escribe el ejercicio.' : null),
    const SizedBox(height: 13),
    DropdownButtonFormField<String>(initialValue: _muscle, decoration: const InputDecoration(labelText: 'Grupo muscular', prefixIcon: Icon(Icons.accessibility_new_rounded)), items: _groups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(), onChanged: (v) => setState(() => _muscle = v!)),
    const SizedBox(height: 13),
    DropdownButtonFormField<String>(initialValue: _day, decoration: const InputDecoration(labelText: 'Día de rutina', prefixIcon: Icon(Icons.calendar_today_outlined)), items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(), onChanged: (v) => setState(() => _day = v!)),
    const SizedBox(height: 13),
    Row(children: [Expanded(child: _numberField(_sets, 'Series', allowDecimal: false)), const SizedBox(width: 10), Expanded(child: _numberField(_reps, 'Repeticiones', allowDecimal: false)), const SizedBox(width: 10), Expanded(child: _numberField(_weight, 'Peso (kg)', allowDecimal: true))]),
    const SizedBox(height: 20), SizedBox(width: double.infinity, height: 52, child: FilledButton(onPressed: () { if (!_form.currentState!.validate()) return; Navigator.pop(context, LiftEntry(id: widget.entry?.id, name: _name.text.trim(), muscleGroup: _muscle, sets: int.parse(_sets.text), reps: int.parse(_reps.text), weight: double.parse(_weight.text), day: _day, completed: widget.entry?.completed ?? false, createdAt: widget.entry?.createdAt)); }, child: Text(widget.entry == null ? 'Agregar a mi rutina' : 'Guardar cambios'))),
  ]))));

  Widget _numberField(TextEditingController controller, String label, {required bool allowDecimal}) => TextFormField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: label), validator: (v) { final number = allowDecimal ? double.tryParse(v ?? '') : int.tryParse(v ?? ''); return number == null || number < 0 ? 'Inválido' : null; });
}

class _ProfileDialog extends StatefulWidget {
  const _ProfileDialog({required this.user});
  final Map<String, Object?> user;
  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  late final _name = TextEditingController(text: widget.user['name'] as String);
  late int _goal = widget.user['goal'] as int? ?? 4;
  @override
  void dispose() { _name.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(title: const Text('Ajustes de perfil'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nombre')), const SizedBox(height: 14), DropdownButtonFormField<int>(initialValue: _goal, decoration: const InputDecoration(labelText: 'Sesiones por semana'), items: List.generate(7, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1} sesiones'))), onChanged: (v) => setState(() => _goal = v!))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () { if (_name.text.trim().isEmpty) return; Navigator.pop(context, {'name': _name.text.trim(), 'goal': _goal}); }, child: const Text('Guardar'))]);
}
