class LiftEntry {
  const LiftEntry({
    this.id,
    required this.name,
    required this.muscleGroup,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.day,
    this.completed = false,
    this.createdAt,
  });

  final int? id;
  final String name;
  final String muscleGroup;
  final int sets;
  final int reps;
  final double weight;
  final String day;
  final bool completed;
  final DateTime? createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'muscle_group': muscleGroup,
        'sets': sets,
        'reps': reps,
        'weight': weight,
        'day': day,
        'completed': completed ? 1 : 0,
        'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      };

  factory LiftEntry.fromMap(Map<String, Object?> map) => LiftEntry(
        id: map['id'] as int,
        name: map['name'] as String,
        muscleGroup: map['muscle_group'] as String,
        sets: map['sets'] as int,
        reps: map['reps'] as int,
        weight: (map['weight'] as num).toDouble(),
        day: map['day'] as String,
        completed: map['completed'] == 1,
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
      );
}
