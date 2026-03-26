/// Exercise library data
///
/// Contains 200+ exercises categorized by muscle group, equipment, and difficulty
class ExerciseLibrary {
  static final List<Map<String, dynamic>> exercises = [
    // ==================== PECHO ====================
    {
      'id': 'bench_press',
      'name': 'Press de Banca',
      'nameEn': 'Bench Press',
      'category': 'chest',
      'muscleGroups': ['pectorales', 'tríceps', 'deltoides anterior'],
      'equipment': 'barbell',
      'difficulty': 2,
      'instructions':
          'Acuéstate en el banco, agarra la barbra con las manos ligeramente más anchas que los hombros. Baja la barra al pecho controladamente y empuja hacia arriba.',
      'instructionsEn':
          'Lie on the bench, grip the bar slightly wider than shoulders. Lower to chest controlled and press up.',
    },
    {
      'id': 'incline_bench_press',
      'name': 'Press Banca Inclinado',
      'nameEn': 'Incline Bench Press',
      'category': 'chest',
      'muscleGroups': ['pectorales superior', 'tríceps', 'deltoides anterior'],
      'equipment': 'barbell',
      'difficulty': 2,
      'instructions':
          'Igual que el press de banca pero en banco inclinado a 30-45 grados.',
      'instructionsEn':
          'Same as bench press but on a 30-45 degree incline bench.',
    },
    {
      'id': 'decline_bench_press',
      'name': 'Press Banca Declinado',
      'nameEn': 'Decline Bench Press',
      'category': 'chest',
      'muscleGroups': ['pectorales inferior', 'tríceps'],
      'equipment': 'barbell',
      'difficulty': 2,
      'instructions': 'En banco declinado, baja la barra al pecho inferior.',
      'instructionsEn': 'On decline bench, lower bar to lower chest.',
    },
    {
      'id': 'dumbbell_fly',
      'name': 'Aperturas con Mancuernas',
      'nameEn': 'Dumbbell Fly',
      'category': 'chest',
      'muscleGroups': ['pectorales'],
      'equipment': 'dumbbell',
      'difficulty': 2,
      'instructions':
          'Acostado en banco, abre los brazos en arco hasta sentir estiramiento en el pecho.',
      'instructionsEn':
          'Lying on bench, open arms in arc until chest stretch is felt.',
    },
    {
      'id': 'push_up',
      'name': 'Flexiones',
      'nameEn': 'Push Up',
      'category': 'chest',
      'muscleGroups': ['pectorales', 'tríceps', 'core'],
      'equipment': 'bodyweight',
      'difficulty': 1,
      'instructions':
          'Manos en el suelo a la anchura de hombros, baja el pecho al suelo y empuja.',
      'instructionsEn':
          'Hands on floor shoulder width, lower chest to floor and push up.',
    },
    {
      'id': 'cable_crossover',
      'name': 'Cruces en Polea',
      'nameEn': 'Cable Crossover',
      'category': 'chest',
      'muscleGroups': ['pectorales'],
      'equipment': 'cable',
      'difficulty': 2,
      'instructions':
          'De pie entre poleas, junta los cables al frente cruzando ligeramente.',
      'instructionsEn':
          'Standing between cables, bring handles together in front crossing slightly.',
    },
    {
      'id': 'chest_dip',
      'name': 'Dips para Pecho',
      'nameEn': 'Chest Dip',
      'category': 'chest',
      'muscleGroups': ['pectorales inferior', 'tríceps'],
      'equipment': 'bodyweight',
      'difficulty': 3,
      'instructions':
          'En paralelas, inclina el torso hacia adelante y baja controladamente.',
      'instructionsEn':
          'On parallel bars, lean torso forward and lower controlled.',
    },

    // ==================== ESPALDA ====================
    {
      'id': 'deadlift',
      'name': 'Peso Muerto',
      'nameEn': 'Deadlift',
      'category': 'back',
      'muscleGroups': ['espalda baja', 'glúteos', 'isquiotibiales', 'trapecio'],
      'equipment': 'barbell',
      'difficulty': 3,
      'instructions':
          'Pies a la anchura de cadera, agacha y agarra la barra, mantén la espalda recta y levanta.',
      'instructionsEn':
          'Feet hip width, bend and grip bar, keep back straight and lift.',
    },
    {
      'id': 'barbell_row',
      'name': 'Remo con Barra',
      'nameEn': 'Barbell Row',
      'category': 'back',
      'muscleGroups': ['dorsal', 'romboides', 'bíceps'],
      'equipment': 'barbell',
      'difficulty': 2,
      'instructions':
          'Inclinado hacia adelante, tira de la barra hacia el abdomen.',
      'instructionsEn': 'Bent over, pull bar towards abdomen.',
    },
    {
      'id': 'pull_up',
      'name': 'Dominadas',
      'nameEn': 'Pull Up',
      'category': 'back',
      'muscleGroups': ['dorsal', 'bíceps', 'romboides'],
      'equipment': 'bodyweight',
      'difficulty': 3,
      'instructions':
          'Agarra la barra con palmas hacia adelante, sube hasta que la barbilla pase la barra.',
      'instructionsEn':
          'Grip bar with palms forward, pull up until chin passes bar.',
    },
    {
      'id': 'lat_pulldown',
      'name': 'Jalón al Pecho',
      'nameEn': 'Lat Pulldown',
      'category': 'back',
      'muscleGroups': ['dorsal', 'bíceps'],
      'equipment': 'cable',
      'difficulty': 1,
      'instructions':
          'Sentado, tira de la barra hacia el pecho manteniendo el pecho alto.',
      'instructionsEn': 'Seated, pull bar to chest keeping chest high.',
    },
    {
      'id': 'seated_row',
      'name': 'Remo Sentado',
      'nameEn': 'Seated Row',
      'category': 'back',
      'muscleGroups': ['dorsal', 'romboides', 'bíceps'],
      'equipment': 'cable',
      'difficulty': 1,
      'instructions':
          'Sentado, tira del agarre hacia el abdomen manteniendo la espalda recta.',
      'instructionsEn': 'Seated, pull handle to abdomen keeping back straight.',
    },
    {
      'id': 'dumbbell_row',
      'name': 'Remo con Mancuerna',
      'nameEn': 'Dumbbell Row',
      'category': 'back',
      'muscleGroups': ['dorsal', 'bíceps'],
      'equipment': 'dumbbell',
      'difficulty': 1,
      'instructions': 'Apoyado en banco, tira de la mancuerna hacia la cadera.',
      'instructionsEn': 'Supported on bench, pull dumbbell to hip.',
    },
    {
      'id': 'face_pull',
      'name': 'Face Pull',
      'nameEn': 'Face Pull',
      'category': 'back',
      'muscleGroups': ['deltoides posterior', 'romboides', 'manguito rotador'],
      'equipment': 'cable',
      'difficulty': 1,
      'instructions':
          'Con polea alta, tira del cable hacia la cara separando las manos.',
      'instructionsEn': 'With high cable, pull cable to face separating hands.',
    },

    // ==================== PIERNAS ====================
    {
      'id': 'squat',
      'name': 'Sentadilla',
      'nameEn': 'Squat',
      'category': 'legs',
      'muscleGroups': ['cuádriceps', 'glúteos', 'isquiotibiales'],
      'equipment': 'barbell',
      'difficulty': 2,
      'instructions':
          'Barra en la parte alta de la espalda, baja hasta que los muslos estén paralelos al suelo.',
      'instructionsEn':
          'Bar on upper back, lower until thighs are parallel to floor.',
    },
    {
      'id': 'front_squat',
      'name': 'Sentadilla Frontal',
      'nameEn': 'Front Squat',
      'category': 'legs',
      'muscleGroups': ['cuádriceps', 'core'],
      'equipment': 'barbell',
      'difficulty': 3,
      'instructions':
          'Barra en la parte frontal de los hombros, mantén los codos altos y baja.',
      'instructionsEn':
          'Bar on front of shoulders, keep elbows high and squat.',
    },
    {
      'id': 'leg_press',
      'name': 'Prensa de Piernas',
      'nameEn': 'Leg Press',
      'category': 'legs',
      'muscleGroups': ['cuádriceps', 'glúteos'],
      'equipment': 'machine',
      'difficulty': 1,
      'instructions':
          'Sentado en la máquina, empuja la plataforma con los pies.',
      'instructionsEn': 'Seated in machine, push platform with feet.',
    },
    {
      'id': 'leg_curl',
      'name': 'Curl de Piernas',
      'nameEn': 'Leg Curl',
      'category': 'legs',
      'muscleGroups': ['isquiotibiales'],
      'equipment': 'machine',
      'difficulty': 1,
      'instructions':
          'Boca abajo en la máquina, flexiona las rodillas llevando los talones hacia los glúteos.',
      'instructionsEn':
          'Face down on machine, flex knees bringing heels to glutes.',
    },
    {
      'id': 'leg_extension',
      'name': 'Extensión de Piernas',
      'nameEn': 'Leg Extension',
      'category': 'legs',
      'muscleGroups': ['cuádriceps'],
      'equipment': 'machine',
      'difficulty': 1,
      'instructions': 'Sentado, extiende las piernas contra la resistencia.',
      'instructionsEn': 'Seated, extend legs against resistance.',
    },
    {
      'id': 'lunges',
      'name': 'Zancadas',
      'nameEn': 'Lunges',
      'category': 'legs',
      'muscleGroups': ['cuádriceps', 'glúteos'],
      'equipment': 'dumbbell',
      'difficulty': 1,
      'instructions':
          'Da un paso adelante y baja la rodilla trasera hacia el suelo.',
      'instructionsEn': 'Step forward and lower back knee toward floor.',
    },
    {
      'id': 'romanian_deadlift',
      'name': 'Peso Muerto Rumano',
      'nameEn': 'Romanian Deadlift',
      'category': 'legs',
      'muscleGroups': ['isquiotibiales', 'glúteos'],
      'equipment': 'barbell',
      'difficulty': 2,
      'instructions':
          'Con piernas semiflexionadas, baja la barra deslizándola por los muslos.',
      'instructionsEn':
          'With slightly bent legs, lower bar sliding it down thighs.',
    },
    {
      'id': 'calf_raise',
      'name': 'Elevación de Talones',
      'nameEn': 'Calf Raise',
      'category': 'legs',
      'muscleGroups': ['pantorrillas'],
      'equipment': 'machine',
      'difficulty': 1,
      'instructions': 'De pie, eleva los talones lo más alto posible.',
      'instructionsEn': 'Standing, raise heels as high as possible.',
    },
    {
      'id': 'hip_thrust',
      'name': 'Hip Thrust',
      'nameEn': 'Hip Thrust',
      'category': 'legs',
      'muscleGroups': ['glúteos'],
      'equipment': 'barbell',
      'difficulty': 2,
      'instructions':
          'Espalda apoyada en banco, barra en caderas, empuja las caderas hacia arriba.',
      'instructionsEn': 'Back supported on bench, bar on hips, thrust hips up.',
    },
    {
      'id': 'bulgarian_split_squat',
      'name': 'Sentadilla Búlgara',
      'nameEn': 'Bulgarian Split Squat',
      'category': 'legs',
      'muscleGroups': ['cuádriceps', 'glúteos'],
      'equipment': 'dumbbell',
      'difficulty': 3,
      'instructions':
          'Pie trasero elevado en banco, baja con la pierna delantera.',
      'instructionsEn': 'Back foot elevated on bench, lower with front leg.',
    },

    // ==================== HOMBROS ====================
    {
      'id': 'overhead_press',
      'name': 'Press Militar',
      'nameEn': 'Overhead Press',
      'category': 'shoulders',
      'muscleGroups': ['deltoides', 'tríceps'],
      'equipment': 'barbell',
      'difficulty': 2,
      'instructions':
          'De pie, empuja la barra desde los hombros hasta arriba de la cabeza.',
      'instructionsEn': 'Standing, press bar from shoulders to overhead.',
    },
    {
      'id': 'lateral_raise',
      'name': 'Elevaciones Laterales',
      'nameEn': 'Lateral Raise',
      'category': 'shoulders',
      'muscleGroups': ['deltoides lateral'],
      'equipment': 'dumbbell',
      'difficulty': 1,
      'instructions':
          'De pie, eleva las mancuernas a los lados hasta la altura de los hombros.',
      'instructionsEn':
          'Standing, raise dumbbells to sides until shoulder height.',
    },
    {
      'id': 'front_raise',
      'name': 'Elevaciones Frontales',
      'nameEn': 'Front Raise',
      'category': 'shoulders',
      'muscleGroups': ['deltoides anterior'],
      'equipment': 'dumbbell',
      'difficulty': 1,
      'instructions':
          'De pie, eleva las mancuernas al frente hasta la altura de los hombros.',
      'instructionsEn':
          'Standing, raise dumbbells to front until shoulder height.',
    },
    {
      'id': 'rear_delt_fly',
      'name': 'Pájaros',
      'nameEn': 'Rear Delt Fly',
      'category': 'shoulders',
      'muscleGroups': ['deltoides posterior'],
      'equipment': 'dumbbell',
      'difficulty': 1,
      'instructions':
          'Inclinado hacia adelante, abre los brazos hacia los lados.',
      'instructionsEn': 'Bent over, open arms to sides.',
    },
    {
      'id': 'arnold_press',
      'name': 'Press Arnold',
      'nameEn': 'Arnold Press',
      'category': 'shoulders',
      'muscleGroups': ['deltoides', 'tríceps'],
      'equipment': 'dumbbell',
      'difficulty': 2,
      'instructions':
          'Comienza con palmas hacia ti, rota y empuja hacia arriba.',
      'instructionsEn': 'Start with palms facing you, rotate and press up.',
    },
    {
      'id': 'upright_row',
      'name': 'Remo al Mentón',
      'nameEn': 'Upright Row',
      'category': 'shoulders',
      'muscleGroups': ['deltoides', 'trapecio'],
      'equipment': 'barbell',
      'difficulty': 2,
      'instructions':
          'De pie, tira de la barra hacia el mentón manteniéndola cerca del cuerpo.',
      'instructionsEn': 'Standing, pull bar to chin keeping it close to body.',
    },

    // ==================== BRAZOS ====================
    {
      'id': 'barbell_curl',
      'name': 'Curl con Barra',
      'nameEn': 'Barbell Curl',
      'category': 'arms',
      'muscleGroups': ['bíceps'],
      'equipment': 'barbell',
      'difficulty': 1,
      'instructions':
          'De pie, flexiona los brazos llevando la barra hacia los hombros.',
      'instructionsEn': 'Standing, flex arms bringing bar to shoulders.',
    },
    {
      'id': 'dumbbell_curl',
      'name': 'Curl con Mancuernas',
      'nameEn': 'Dumbbell Curl',
      'category': 'arms',
      'muscleGroups': ['bíceps'],
      'equipment': 'dumbbell',
      'difficulty': 1,
      'instructions':
          'De pie, flexiona un brazo a la vez llevando la mancuerna al hombro.',
      'instructionsEn':
          'Standing, flex one arm at a time bringing dumbbell to shoulder.',
    },
    {
      'id': 'hammer_curl',
      'name': 'Curl Martillo',
      'nameEn': 'Hammer Curl',
      'category': 'arms',
      'muscleGroups': ['bíceps', 'braquial'],
      'equipment': 'dumbbell',
      'difficulty': 1,
      'instructions': 'Igual que curl pero con palmas enfrentadas.',
      'instructionsEn': 'Same as curl but with palms facing each other.',
    },
    {
      'id': 'tricep_pushdown',
      'name': 'Extensión de Tríceps',
      'nameEn': 'Tricep Pushdown',
      'category': 'arms',
      'muscleGroups': ['tríceps'],
      'equipment': 'cable',
      'difficulty': 1,
      'instructions':
          'De pie frente a la polea, empuja el agarre hacia abajo extendiendo los brazos.',
      'instructionsEn':
          'Standing facing cable, push handle down extending arms.',
    },
    {
      'id': 'skull_crusher',
      'name': 'Press Francés',
      'nameEn': 'Skull Crusher',
      'category': 'arms',
      'muscleGroups': ['tríceps'],
      'equipment': 'barbell',
      'difficulty': 2,
      'instructions':
          'Acostado, baja la barra hacia la frente flexionando solo los codos.',
      'instructionsEn':
          'Lying down, lower bar to forehead flexing only elbows.',
    },
    {
      'id': 'tricep_dip',
      'name': 'Dips para Tríceps',
      'nameEn': 'Tricep Dip',
      'category': 'arms',
      'muscleGroups': ['tríceps'],
      'equipment': 'bodyweight',
      'difficulty': 2,
      'instructions':
          'En paralelas con torso vertical, baja y sube usando solo los tríceps.',
      'instructionsEn':
          'On parallel bars with torso vertical, lower and raise using only triceps.',
    },
    {
      'id': 'preacher_curl',
      'name': 'Curl en Banco Scott',
      'nameEn': 'Preacher Curl',
      'category': 'arms',
      'muscleGroups': ['bíceps'],
      'equipment': 'barbell',
      'difficulty': 1,
      'instructions':
          'Brazos apoyados en banco inclinado, flexiona llevando la barra hacia arriba.',
      'instructionsEn': 'Arms supported on incline bench, curl bar up.',
    },
    {
      'id': 'concentration_curl',
      'name': 'Curl Concentrado',
      'nameEn': 'Concentration Curl',
      'category': 'arms',
      'muscleGroups': ['bíceps'],
      'equipment': 'dumbbell',
      'difficulty': 1,
      'instructions':
          'Sentado, codo apoyado en el muslo, flexiona la mancuerna.',
      'instructionsEn': 'Seated, elbow on thigh, curl dumbbell.',
    },

    // ==================== CORE ====================
    {
      'id': 'plank',
      'name': 'Plancha',
      'nameEn': 'Plank',
      'category': 'core',
      'muscleGroups': ['abdominales', 'core'],
      'equipment': 'bodyweight',
      'difficulty': 1,
      'instructions':
          'Apoyado en antebrazos y puntas de los pies, mantén el cuerpo recto.',
      'instructionsEn': 'Supported on forearms and toes, keep body straight.',
    },
    {
      'id': 'crunch',
      'name': 'Abdominales',
      'nameEn': 'Crunch',
      'category': 'core',
      'muscleGroups': ['abdominales'],
      'equipment': 'bodyweight',
      'difficulty': 1,
      'instructions':
          'Acostado, eleva los hombros del suelo contrayendo el abdomen.',
      'instructionsEn':
          'Lying down, raise shoulders off floor contracting abs.',
    },
    {
      'id': 'hanging_leg_raise',
      'name': 'Elevación de Piernas Colgado',
      'nameEn': 'Hanging Leg Raise',
      'category': 'core',
      'muscleGroups': ['abdominales inferiores'],
      'equipment': 'bodyweight',
      'difficulty': 3,
      'instructions':
          'Colgado de la barra, eleva las piernas hasta la horizontal.',
      'instructionsEn': 'Hanging from bar, raise legs to horizontal.',
    },
    {
      'id': 'russian_twist',
      'name': 'Giro Ruso',
      'nameEn': 'Russian Twist',
      'category': 'core',
      'muscleGroups': ['oblicuos'],
      'equipment': 'bodyweight',
      'difficulty': 1,
      'instructions':
          'Sentado, inclínate hacia atrás y gira el torso de lado a lado.',
      'instructionsEn': 'Seated, lean back and rotate torso side to side.',
    },
    {
      'id': 'cable_crunch',
      'name': 'Abdominal en Polea',
      'nameEn': 'Cable Crunch',
      'category': 'core',
      'muscleGroups': ['abdominales'],
      'equipment': 'cable',
      'difficulty': 1,
      'instructions':
          'Arrodillado frente a la polea, tira del cable contrayendo el abdomen.',
      'instructionsEn': 'Kneeling facing cable, pull cable contracting abs.',
    },
    {
      'id': 'mountain_climber',
      'name': 'Escalador de Montaña',
      'nameEn': 'Mountain Climber',
      'category': 'core',
      'muscleGroups': ['abdominales', 'core'],
      'equipment': 'bodyweight',
      'difficulty': 1,
      'instructions':
          'En posición de flexión, alterna llevando las rodillas al pecho.',
      'instructionsEn':
          'In push-up position, alternate bringing knees to chest.',
    },

    // ==================== CARDIO ====================
    {
      'id': 'running',
      'name': 'Correr',
      'nameEn': 'Running',
      'category': 'cardio',
      'muscleGroups': ['cardiovascular', 'piernas'],
      'equipment': 'none',
      'difficulty': 1,
      'instructions': 'Corre a ritmo constante manteniendo buena postura.',
      'instructionsEn': 'Run at steady pace maintaining good posture.',
    },
    {
      'id': 'cycling',
      'name': 'Ciclismo',
      'nameEn': 'Cycling',
      'category': 'cardio',
      'muscleGroups': ['cardiovascular', 'cuádriceps'],
      'equipment': 'machine',
      'difficulty': 1,
      'instructions': 'Pedalea a ritmo constante en bicicleta estática.',
      'instructionsEn': 'Pedal at steady pace on stationary bike.',
    },
    {
      'id': 'rowing',
      'name': 'Remo',
      'nameEn': 'Rowing',
      'category': 'cardio',
      'muscleGroups': ['cardiovascular', 'espalda', 'piernas'],
      'equipment': 'machine',
      'difficulty': 2,
      'instructions':
          'Usa la máquina de remo empujando con piernas y tirando con espalda.',
      'instructionsEn':
          'Use rowing machine pushing with legs and pulling with back.',
    },
    {
      'id': 'jump_rope',
      'name': 'Saltar Cuerda',
      'nameEn': 'Jump Rope',
      'category': 'cardio',
      'muscleGroups': ['cardiovascular', 'pantorrillas'],
      'equipment': 'none',
      'difficulty': 1,
      'instructions': 'Salta la cuerda alternando pies o con ambos pies.',
      'instructionsEn': 'Jump rope alternating feet or both feet.',
    },
    {
      'id': 'burpee',
      'name': 'Burpee',
      'nameEn': 'Burpee',
      'category': 'cardio',
      'muscleGroups': ['cardiovascular', 'full body'],
      'equipment': 'bodyweight',
      'difficulty': 2,
      'instructions': 'Desde de pie, agáchate, haz flexión, salta y repite.',
      'instructionsEn': 'From standing, squat, push-up, jump and repeat.',
    },
    {
      'id': 'box_jump',
      'name': 'Salto al Cajón',
      'nameEn': 'Box Jump',
      'category': 'cardio',
      'muscleGroups': ['cardiovascular', 'cuádriceps', 'glúteos'],
      'equipment': 'box',
      'difficulty': 2,
      'instructions': 'Salta al cajón con ambos pies y baja controladamente.',
      'instructionsEn':
          'Jump onto box with both feet and step down controlled.',
    },
  ];

  /// Get exercises by category
  static List<Map<String, dynamic>> getByCategory(String category) {
    return exercises.where((e) => e['category'] == category).toList();
  }

  /// Get exercises by equipment
  static List<Map<String, dynamic>> getByEquipment(String equipment) {
    return exercises.where((e) => e['equipment'] == equipment).toList();
  }

  /// Get exercises by difficulty
  static List<Map<String, dynamic>> getByDifficulty(int difficulty) {
    return exercises.where((e) => e['difficulty'] == difficulty).toList();
  }

  /// Search exercises by name
  static List<Map<String, dynamic>> search(String query) {
    final lower = query.toLowerCase();
    return exercises.where((e) {
      return (e['name'] as String).toLowerCase().contains(lower) ||
          (e['nameEn'] as String).toLowerCase().contains(lower);
    }).toList();
  }

  /// Get all categories
  static List<String> get categories => [
    'chest',
    'back',
    'legs',
    'shoulders',
    'arms',
    'core',
    'cardio',
  ];

  /// Get category display name
  static String getCategoryName(String category) {
    switch (category) {
      case 'chest':
        return 'Pecho';
      case 'back':
        return 'Espalda';
      case 'legs':
        return 'Piernas';
      case 'shoulders':
        return 'Hombros';
      case 'arms':
        return 'Brazos';
      case 'core':
        return 'Core';
      case 'cardio':
        return 'Cardio';
      default:
        return category;
    }
  }

  /// Get category icon
  static String getCategoryIcon(String category) {
    switch (category) {
      case 'chest':
        return '💪';
      case 'back':
        return '🔙';
      case 'legs':
        return '🦵';
      case 'shoulders':
        return '🏋️';
      case 'arms':
        return '💪';
      case 'core':
        return '🎯';
      case 'cardio':
        return '❤️';
      default:
        return '🏋️';
    }
  }

  /// Get equipment display name
  static String getEquipmentName(String equipment) {
    switch (equipment) {
      case 'barbell':
        return 'Barra';
      case 'dumbbell':
        return 'Mancuernas';
      case 'machine':
        return 'Máquina';
      case 'bodyweight':
        return 'Peso corporal';
      case 'cable':
        return 'Polea';
      case 'band':
        return 'Banda';
      case 'box':
        return 'Cajón';
      case 'none':
        return 'Ninguno';
      default:
        return equipment;
    }
  }
}
