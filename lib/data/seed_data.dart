import '../models/models.dart';

/// Sample content that ships with a fresh account so every screen in the
/// approved mock-ups has data to show on first launch.
class SeedData {
  static const cellularRespirationQuiz = <QuizQuestion>[
    QuizQuestion(
        prompt: 'In aerobic respiration, ______ is the final electron acceptor in the electron transport chain.',
        options: ['Carbon dioxide', 'Oxygen', 'Glucose', 'Pyruvate'],
        answer: 1,
        fillBlank: true,
        insight:
            'Oxygen accepts electrons and combines with protons to form water at the end of the electron transport chain. This allows continuous electron flow and robust ATP production.'),
    QuizQuestion(
        prompt: 'Which metabolic pathway produces the highest net yield of ATP per glucose molecule?',
        options: ['Glycolysis', 'Citric Acid Cycle', 'Oxidative Phosphorylation', 'Lactic acid fermentation'],
        answer: 2,
        insight: 'Oxidative phosphorylation produces approximately 26 to 28 ATP per glucose molecule.'),
    QuizQuestion(
        prompt: 'Where in the cell does glycolysis take place?',
        options: [
          'Cytoplasm (Cytosol)',
          'Mitochondrial matrix',
          'Inner mitochondrial membrane',
          'Endoplasmic reticulum'
        ],
        answer: 0,
        insight: 'Glycolysis occurs in the cytosol of the cytoplasm and does not require oxygen.'),
    QuizQuestion(
        prompt: 'What is the net gain of ATP molecules produced directly by glycolysis from one molecule of glucose?',
        options: ['1 ATP', '2 ATP', '4 ATP', '36 ATP'],
        answer: 1,
        insight: 'Glycolysis consumes 2 ATP and produces 4 ATP, resulting in a net yield of 2 ATP.'),
    QuizQuestion(
        prompt: 'Which stage of cellular respiration occurs in the mitochondrial matrix?',
        options: ['Glycolysis', 'Electron transport chain', 'Krebs cycle', 'Light-dependent reactions'],
        answer: 2,
        fillBlank: false,
        insight:
            'The Krebs cycle occurs in the mitochondrial matrix, where it breaks down acetyl-CoA and produces NADH, FADH₂, and CO₂.'),
    QuizQuestion(
        prompt: 'What molecule enters the citric acid cycle after the transition (link) reaction?',
        options: ['Acetyl-CoA', 'Pyruvate', 'Oxaloacetate', 'Lactate'],
        answer: 0,
        insight: 'Pyruvate is converted into acetyl-CoA in the link reaction before entering the Krebs cycle.'),
    QuizQuestion(
        prompt: 'Which organelle is primarily responsible for producing ATP during cellular respiration?',
        options: ['Chloroplast', 'Mitochondrion', 'Nucleus', 'Ribosome'],
        answer: 1,
        insight:
            'Mitochondria produce most of the ATP during cellular respiration. The electron transport chain and oxidative phosphorylation take place in the inner mitochondrial membrane.'),
    QuizQuestion(
        prompt: 'Which stage of cellular respiration occurs in the mitochondrial matrix?',
        options: ['Glycolysis', 'Electron transport chain', 'Krebs cycle', 'Light-dependent reactions'],
        answer: 2,
        insight: 'The Krebs (citric acid) cycle occurs within the mitochondrial matrix.'),
    QuizQuestion(
        prompt: 'What enzyme catalyzes the phosphorylation of ADP to synthesize ATP via proton gradient?',
        options: ['ATP Synthase', 'Hexokinase', 'DNA Polymerase', 'Amylase'],
        answer: 0,
        insight:
            'ATP synthase uses the proton electrochemical gradient across the inner mitochondrial membrane to produce ATP.'),
    QuizQuestion(
        prompt:
            'Which phase of cellular respiration yields the largest net quantity of ATP molecules under aerobic conditions?',
        options: [
          'Glycolysis in cytoplasm',
          'Citric Acid (Krebs) Cycle',
          'Electron Transport Chain & Oxidative Phosphorylation',
          'Lactic Acid Fermentation'
        ],
        answer: 2,
        insight:
            'Yields ~30-32 ATP via ATP Synthase driven by the electrochemical proton gradient across the inner mitochondrial membrane.'),
  ];

  static const plantCellQuiz = <QuizQuestion>[
    QuizQuestion(
        prompt: 'Which structure gives plant cells their rigid shape?',
        options: ['Cell membrane', 'Cell wall', 'Nucleus', 'Ribosome'],
        answer: 1,
        insight: 'The cellulose cell wall provides structure and protection to plant cells.'),
    QuizQuestion(
        prompt: 'Photosynthesis takes place inside the ______.',
        options: ['Mitochondria', 'Vacuole', 'Chloroplasts', 'Golgi body'],
        answer: 2,
        fillBlank: true,
        insight: 'Chloroplasts capture light energy and convert it into chemical energy.'),
    QuizQuestion(
        prompt: 'The large central vacuole mainly maintains…',
        options: ['Turgor pressure', 'DNA replication', 'Protein synthesis', 'Cell division'],
        answer: 0,
        insight: 'The central vacuole stores water and keeps the cell firm through turgor pressure.'),
    QuizQuestion(
        prompt: 'Plasmodesmata connect…',
        options: ['Neighbouring plant cells', 'Chloroplast membranes', 'Nucleus and ribosome', 'Roots and leaves'],
        answer: 0,
        insight: 'Plasmodesmata are channels that link the cytoplasm of adjacent plant cells.'),
    QuizQuestion(
        prompt: 'Which organelle controls the activities of the cell?',
        options: ['Nucleus', 'Vacuole', 'Cell wall', 'Chloroplast'],
        answer: 0,
        insight: 'The nucleus stores DNA and directs cell activities.'),
    QuizQuestion(
        prompt: 'The cell wall is mainly made of ______.',
        options: ['Chitin', 'Cellulose', 'Starch', 'Keratin'],
        answer: 1,
        fillBlank: true,
        insight: 'Plant cell walls are composed mostly of cellulose microfibrils.'),
    QuizQuestion(
        prompt: 'Amyloplasts are plastids that store…',
        options: ['Starch', 'Pigments', 'Water', 'Proteins'],
        answer: 0,
        insight: 'Amyloplasts are colourless plastids that store starch.'),
    QuizQuestion(
        prompt: 'Which pigment captures light energy in chloroplasts?',
        options: ['Melanin', 'Chlorophyll', 'Hemoglobin', 'Carotene only'],
        answer: 1,
        insight: 'Chlorophyll absorbs mostly blue and red light for photosynthesis.'),
    QuizQuestion(
        prompt: 'The membrane surrounding the central vacuole is the…',
        options: ['Tonoplast', 'Thylakoid', 'Stroma', 'Cristae'],
        answer: 0,
        insight: 'The tonoplast regulates what enters and leaves the vacuole.'),
    QuizQuestion(
        prompt: 'Light energy is converted into ______ energy during photosynthesis.',
        options: ['Thermal', 'Chemical', 'Kinetic', 'Nuclear'],
        answer: 1,
        fillBlank: true,
        insight: 'Photosynthesis converts light energy into chemical energy stored in glucose.'),
  ];

  static List<StudyModule> modules(DateTime now) {
    StudyModule m(String id, String title, String file, String ext, int kb, int daysAgo, String cat, String icon,
            int best, List<KeyPoint> kp, List<String> ov, List<QuizQuestion> q) =>
        StudyModule(
            id: id,
            title: title,
            fileName: file,
            ext: ext,
            sizeBytes: kb * 1024,
            uploadedAt: now.subtract(Duration(days: daysAgo)),
            category: cat,
            iconKey: icon,
            bestScore: best,
            keyPoints: kp,
            overview: ov,
            questions: q);

    const plantCellKp = [
      KeyPoint('Cellular Structure',
          'Distinct characteristics of plant cells including rigid cellulose cell walls, large central vacuoles, and chloroplasts.'),
      KeyPoint('Photosynthetic Apparatus',
          'Light-dependent and Calvin cycle compartmentalization within thylakoid membranes and stroma.'),
      KeyPoint(
          'Intercellular Transport', 'Plasmodesmata facilitating cytoplasmic transport between adjacent plant cells.'),
    ];
    const plantCellOv = [
      'Plant cell structure',
      'Organelles and their functions',
      'Cell division',
      'Photosynthesis process'
    ];
    const respKp = [
      KeyPoint('Glycolysis', 'Anaerobic breakdown of glucose into 2 pyruvate molecules yielding net 2 ATP.'),
      KeyPoint('Krebs Cycle', 'Mitochondrial matrix reaction producing CO2, NADH, and FADH2.'),
    ];

    return [
      m('plant_cell', 'Plant Cell Biology', 'Plant Cell Biology.pdf', 'pdf', 2458, 2, 'Plant Biology', 'microscope', 85,
          plantCellKp, plantCellOv, plantCellQuiz),
      m(
          'photosynthesis',
          'Organic Photosynthesis',
          'Organic Photosynthesis.pdf',
          'pdf',
          5222,
          4,
          'Plant Biology',
          'sun',
          62,
          const [
            KeyPoint('Light Reactions', 'Photosystems II and I excite electrons and split water in the thylakoids.'),
            KeyPoint('Calvin Cycle', 'RuBisCO fixes CO2 in the stroma to build G3P for glucose assembly.'),
          ],
          const ['Light-dependent reactions', 'Thylakoids', 'Calvin cycle'],
          plantCellQuiz),
      m(
          'soil',
          'Soil Ecology & Nutrients',
          'Soil_Ecology_Nutrients_Ch4.txt',
          'txt',
          850,
          6,
          'Ecology & Soils',
          'gauge',
          48,
          const [
            KeyPoint('Soil Horizons', 'Layered profile from organic O horizon down to bedrock.'),
            KeyPoint('Nutrient Cycling', 'Decomposers return nitrogen and phosphorus to the soil.'),
          ],
          const ['Soil layers', 'Macronutrients', 'Decomposition'],
          plantCellQuiz),
      m(
          'vascular',
          'Plant Vascular Systems',
          'Plant_Vascular_Systems.pdf',
          'pdf',
          3100,
          7,
          'Plant Biology',
          'phone',
          92,
          const [
            KeyPoint('Xylem', 'Transports water and minerals upward from the roots.'),
            KeyPoint('Phloem', 'Distributes sugars from leaves to the rest of the plant.'),
          ],
          const ['Xylem', 'Phloem', 'Transpiration'],
          plantCellQuiz),
      m(
          'genetics',
          'Floral Genetics & Breeding',
          'Genetics_Mendelian_Inheritance.pdf',
          'pdf',
          6400,
          8,
          'Genetics',
          'genetics',
          32,
          const [
            KeyPoint('Mendelian Inheritance', 'Dominant and recessive alleles segregate independently.'),
            KeyPoint('Hybrid Breeding', 'Cross-pollination combines desirable floral traits.'),
          ],
          const ['Alleles', 'Punnett squares', 'Hybridization'],
          plantCellQuiz),
      m(
          'germination',
          'Seed Germination & Growth',
          'Seed_Germination_Growth.pdf',
          'pdf',
          1900,
          14,
          'Plant Biology',
          'cloud',
          17,
          const [
            KeyPoint('Imbibition', 'Seeds absorb water to activate enzymes.'),
            KeyPoint('Radicle Emergence', 'The embryonic root breaks through the seed coat first.'),
          ],
          const ['Dormancy', 'Imbibition', 'Seedling growth'],
          plantCellQuiz),
      m('cell_resp', 'Cellular Respiration', 'Bio_101_Cellular_Respiration.pdf', 'pdf', 4300, 1, 'Biology', 'flask', -1,
          respKp, const ['Glycolysis', 'Krebs cycle', 'Electron transport chain'], cellularRespirationQuiz),
    ];
  }

  static List<QuizAttempt> history(DateTime now) {
    final pc = plantCellQuiz;
    return [
      QuizAttempt(
          moduleId: 'plant_cell',
          title: 'Plant Cell Biology',
          fileName: 'Plant Cell Biology.pdf',
          date: DateTime(now.year, 10, 4),
          attemptNo: 1,
          answers: [1, 2, 0, 0, 0, 1, 0, 1, 1, 0],
          flagged: List.filled(10, false),
          questions: pc,
          coins: 50),
      QuizAttempt(
          moduleId: 'photosynthesis',
          title: 'Organic Photosynthesis',
          fileName: 'Organic Photosynthesis',
          date: DateTime(now.year, 9, 30),
          attemptNo: 1,
          answers: [1, 2, 0, 0, 0, 1, 1, 0, 1, 0],
          flagged: List.filled(10, false),
          questions: pc,
          coins: 20),
    ];
  }
}
