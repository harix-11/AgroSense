import 'dart:convert';
import 'package:agrosense/data/local/database/app_database.dart';
import 'package:drift/drift.dart';

/// Crop Catalog Repository
///
/// Manages predefined crop database with South Indian crop varieties
/// Includes growth stages, durations, and regional adaptations
class CropCatalogRepository {
  final AppDatabase _database;

  CropCatalogRepository(this._database);

  /// Initialize crop catalog with predefined data
  Future<void> seedCropCatalog() async {
    final existing = await _database.getAllCrops();
    if (existing.isNotEmpty) {
      return; // Already seeded
    }

    // South Indian crop varieties
    final crops = [
      _createRice(),
      _createSugarcane(),
      _createCotton(),
      _createGroundnut(),
      _createFingerMillet(),
      _createPearlMillet(),
      _createPigeonPea(),
      _createChickpea(),
      _createTurmeric(),
      _createCoconut(),
      _createBanana(),
      _createTomato(),
      _createBrinjal(),
      _createOkra(),
      _createChilli(),
    ];

    for (final crop in crops) {
      await _database.insertCrop(crop);
    }
  }

  /// Get all crops
  Future<List<Crop>> getAllCrops() async {
    return _database.getAllCrops();
  }

  /// Get crops by category
  Future<List<Crop>> getCropsByCategory(String category) async {
    return _database.getCropsByCategory(category);
  }

  /// Get crop by ID
  Future<Crop?> getCropById(String cropId) async {
    return _database.getCropById(cropId);
  }

  // ==================== CROP DEFINITIONS ====================

  CropsCompanion _createRice() {
    return CropsCompanion.insert(
      id: 'crop_rice',
      name: 'Rice (Paddy)',
      scientificName: const Value('Oryza sativa'),
      category: 'Cereal',
      minDurationDays: 90,
      maxDurationDays: 150,
      region: 'South India',
      season: 'Kharif/Rabi',
      waterRequirement: const Value('High'),
      soilTypes: Value(json.encode(['Clayey', 'Loamy'])),
      stagesJson: json.encode([
        {
          'name': 'land_preparation',
          'minDays': 0,
          'maxDays': 7,
          'description': 'Plowing, leveling, and bund preparation',
        },
        {
          'name': 'nursery',
          'minDays': 0,
          'maxDays': 25,
          'description': 'Seedling preparation (if transplanting)',
        },
        {
          'name': 'transplanting',
          'minDays': 25,
          'maxDays': 30,
          'description': 'Moving seedlings to main field',
        },
        {
          'name': 'tillering',
          'minDays': 30,
          'maxDays': 50,
          'description': 'Formation of tillers and leaves',
        },
        {
          'name': 'panicle_initiation',
          'minDays': 50,
          'maxDays': 70,
          'description': 'Panicle development begins',
        },
        {
          'name': 'flowering',
          'minDays': 70,
          'maxDays': 90,
          'description': 'Flowering and pollination',
        },
        {
          'name': 'grain_filling',
          'minDays': 90,
          'maxDays': 120,
          'description': 'Grain development and maturation',
        },
        {
          'name': 'maturity',
          'minDays': 120,
          'maxDays': 140,
          'description': 'Grains harden, ready for harvest',
        },
        {
          'name': 'harvest',
          'minDays': 140,
          'maxDays': 150,
          'description': 'Harvesting and threshing',
        },
      ]),
      createdAt: DateTime.now(),
    );
  }

  CropsCompanion _createSugarcane() {
    return CropsCompanion.insert(
      id: 'crop_sugarcane',
      name: 'Sugarcane',
      scientificName: const Value('Saccharum officinarum'),
      category: 'Cash Crop',
      minDurationDays: 300,
      maxDurationDays: 365,
      region: 'South India',
      season: 'Year-round',
      waterRequirement: const Value('High'),
      soilTypes: Value(json.encode(['Loamy', 'Clayey', 'Black Soil'])),
      stagesJson: json.encode([
        {
          'name': 'land_preparation',
          'minDays': 0,
          'maxDays': 15,
          'description': 'Deep plowing and furrow formation'
        },
        {
          'name': 'planting',
          'minDays': 15,
          'maxDays': 30,
          'description': 'Planting setts in furrows'
        },
        {
          'name': 'germination',
          'minDays': 30,
          'maxDays': 60,
          'description': 'Shoot emergence from setts'
        },
        {
          'name': 'tillering',
          'minDays': 60,
          'maxDays': 120,
          'description': 'Tiller formation'
        },
        {
          'name': 'grand_growth',
          'minDays': 120,
          'maxDays': 270,
          'description': 'Rapid height and cane development'
        },
        {
          'name': 'maturity',
          'minDays': 270,
          'maxDays': 350,
          'description': 'Sugar accumulation in cane'
        },
        {
          'name': 'harvest',
          'minDays': 350,
          'maxDays': 365,
          'description': 'Harvesting mature canes'
        },
      ]),
      createdAt: DateTime.now(),
    );
  }

  CropsCompanion _createCotton() {
    return CropsCompanion.insert(
      id: 'crop_cotton',
      name: 'Cotton',
      scientificName: const Value('Gossypium spp.'),
      category: 'Cash Crop',
      minDurationDays: 150,
      maxDurationDays: 180,
      region: 'South India',
      season: 'Kharif',
      waterRequirement: const Value('Medium'),
      soilTypes: Value(json.encode(['Black Soil', 'Loamy'])),
      stagesJson: json.encode([
        {
          'name': 'land_preparation',
          'minDays': 0,
          'maxDays': 10,
          'description': 'Plowing and bed preparation'
        },
        {
          'name': 'sowing',
          'minDays': 10,
          'maxDays': 15,
          'description': 'Seed sowing'
        },
        {
          'name': 'germination',
          'minDays': 15,
          'maxDays': 25,
          'description': 'Seedling emergence'
        },
        {
          'name': 'vegetative',
          'minDays': 25,
          'maxDays': 60,
          'description': 'Plant growth and branching'
        },
        {
          'name': 'squaring',
          'minDays': 60,
          'maxDays': 75,
          'description': 'Square (flower bud) formation'
        },
        {
          'name': 'flowering',
          'minDays': 75,
          'maxDays': 110,
          'description': 'Flowering and boll formation'
        },
        {
          'name': 'boll_development',
          'minDays': 110,
          'maxDays': 150,
          'description': 'Boll growth and fiber development'
        },
        {
          'name': 'maturity',
          'minDays': 150,
          'maxDays': 170,
          'description': 'Bolls open'
        },
        {
          'name': 'harvest',
          'minDays': 170,
          'maxDays': 180,
          'description': 'Cotton picking'
        },
      ]),
      createdAt: DateTime.now(),
    );
  }

  CropsCompanion _createGroundnut() {
    return CropsCompanion.insert(
      id: 'crop_groundnut',
      name: 'Groundnut (Peanut)',
      scientificName: const Value('Arachis hypogaea'),
      category: 'Oilseed',
      minDurationDays: 90,
      maxDurationDays: 120,
      region: 'South India',
      season: 'Kharif/Rabi',
      waterRequirement: const Value('Medium'),
      soilTypes: Value(json.encode(['Sandy Loam', 'Red Soil'])),
      stagesJson: json.encode([
        {
          'name': 'land_preparation',
          'minDays': 0,
          'maxDays': 7,
          'description': 'Plowing and seed bed preparation'
        },
        {
          'name': 'sowing',
          'minDays': 7,
          'maxDays': 12,
          'description': 'Seed sowing'
        },
        {
          'name': 'germination',
          'minDays': 12,
          'maxDays': 20,
          'description': 'Seedling emergence'
        },
        {
          'name': 'vegetative',
          'minDays': 20,
          'maxDays': 40,
          'description': 'Branch and leaf development'
        },
        {
          'name': 'flowering',
          'minDays': 40,
          'maxDays': 60,
          'description': 'Flower appearance'
        },
        {
          'name': 'pegging',
          'minDays': 60,
          'maxDays': 75,
          'description': 'Peg penetration into soil'
        },
        {
          'name': 'pod_development',
          'minDays': 75,
          'maxDays': 100,
          'description': 'Pod and kernel formation'
        },
        {
          'name': 'maturity',
          'minDays': 100,
          'maxDays': 115,
          'description': 'Pod maturation'
        },
        {
          'name': 'harvest',
          'minDays': 115,
          'maxDays': 120,
          'description': 'Harvesting pods'
        },
      ]),
      createdAt: DateTime.now(),
    );
  }

  CropsCompanion _createFingerMillet() {
    return CropsCompanion.insert(
      id: 'crop_ragi',
      name: 'Finger Millet (Ragi)',
      scientificName: const Value('Eleusine coracana'),
      category: 'Millet',
      minDurationDays: 90,
      maxDurationDays: 120,
      region: 'South India',
      season: 'Kharif/Rabi',
      waterRequirement: const Value('Low'),
      soilTypes: Value(json.encode(['Red Soil', 'Loamy', 'Sandy'])),
      stagesJson: json.encode([
        {
          'name': 'land_preparation',
          'minDays': 0,
          'maxDays': 7,
          'description': 'Field preparation'
        },
        {
          'name': 'sowing',
          'minDays': 7,
          'maxDays': 12,
          'description': 'Broadcasting or line sowing'
        },
        {
          'name': 'germination',
          'minDays': 12,
          'maxDays': 20,
          'description': 'Seedling emergence'
        },
        {
          'name': 'vegetative',
          'minDays': 20,
          'maxDays': 45,
          'description': 'Tillering and leaf growth'
        },
        {
          'name': 'flowering',
          'minDays': 45,
          'maxDays': 70,
          'description': 'Ear emergence and flowering'
        },
        {
          'name': 'grain_filling',
          'minDays': 70,
          'maxDays': 100,
          'description': 'Grain development'
        },
        {
          'name': 'maturity',
          'minDays': 100,
          'maxDays': 115,
          'description': 'Grain hardening'
        },
        {
          'name': 'harvest',
          'minDays': 115,
          'maxDays': 120,
          'description': 'Harvesting'
        },
      ]),
      createdAt: DateTime.now(),
    );
  }

  CropsCompanion _createPearlMillet() {
    return CropsCompanion.insert(
      id: 'crop_bajra',
      name: 'Pearl Millet (Bajra)',
      scientificName: const Value('Pennisetum glaucum'),
      category: 'Millet',
      minDurationDays: 70,
      maxDurationDays: 90,
      region: 'South India',
      season: 'Kharif',
      waterRequirement: const Value('Low'),
      soilTypes: Value(json.encode(['Sandy', 'Loamy'])),
      stagesJson: json.encode([
        {
          'name': 'land_preparation',
          'minDays': 0,
          'maxDays': 5,
          'description': 'Minimal tillage'
        },
        {
          'name': 'sowing',
          'minDays': 5,
          'maxDays': 10,
          'description': 'Seed sowing'
        },
        {
          'name': 'germination',
          'minDays': 10,
          'maxDays': 15,
          'description': 'Seedling emergence'
        },
        {
          'name': 'vegetative',
          'minDays': 15,
          'maxDays': 35,
          'description': 'Tillering and growth'
        },
        {
          'name': 'flowering',
          'minDays': 35,
          'maxDays': 55,
          'description': 'Ear head emergence'
        },
        {
          'name': 'grain_filling',
          'minDays': 55,
          'maxDays': 75,
          'description': 'Grain development'
        },
        {
          'name': 'maturity',
          'minDays': 75,
          'maxDays': 85,
          'description': 'Grain hardening'
        },
        {
          'name': 'harvest',
          'minDays': 85,
          'maxDays': 90,
          'description': 'Harvesting'
        },
      ]),
      createdAt: DateTime.now(),
    );
  }

  CropsCompanion _createPigeonPea() {
    return CropsCompanion.insert(
      id: 'crop_pigeonpea',
      name: 'Pigeon Pea (Tur/Arhar)',
      scientificName: const Value('Cajanus cajan'),
      category: 'Pulse',
      minDurationDays: 150,
      maxDurationDays: 180,
      region: 'South India',
      season: 'Kharif',
      waterRequirement: const Value('Low'),
      soilTypes: Value(json.encode(['Black Soil', 'Red Soil', 'Loamy'])),
      stagesJson: json.encode([
        {
          'name': 'land_preparation',
          'minDays': 0,
          'maxDays': 7,
          'description': 'Plowing and leveling'
        },
        {
          'name': 'sowing',
          'minDays': 7,
          'maxDays': 12,
          'description': 'Seed sowing'
        },
        {
          'name': 'germination',
          'minDays': 12,
          'maxDays': 20,
          'description': 'Seedling emergence'
        },
        {
          'name': 'vegetative',
          'minDays': 20,
          'maxDays': 70,
          'description': 'Branch and leaf growth'
        },
        {
          'name': 'flowering',
          'minDays': 70,
          'maxDays': 110,
          'description': 'Flowering'
        },
        {
          'name': 'pod_development',
          'minDays': 110,
          'maxDays': 150,
          'description': 'Pod formation and filling'
        },
        {
          'name': 'maturity',
          'minDays': 150,
          'maxDays': 170,
          'description': 'Pod maturation'
        },
        {
          'name': 'harvest',
          'minDays': 170,
          'maxDays': 180,
          'description': 'Harvesting'
        },
      ]),
      createdAt: DateTime.now(),
    );
  }

  CropsCompanion _createChickpea() {
    return CropsCompanion.insert(
      id: 'crop_chickpea',
      name: 'Chickpea (Chana)',
      scientificName: const Value('Cicer arietinum'),
      category: 'Pulse',
      minDurationDays: 90,
      maxDurationDays: 120,
      region: 'South India',
      season: 'Rabi',
      waterRequirement: const Value('Low'),
      soilTypes: Value(json.encode(['Black Soil', 'Loamy'])),
      stagesJson: json.encode([
        {
          'name': 'land_preparation',
          'minDays': 0,
          'maxDays': 7,
          'description': 'Seed bed preparation'
        },
        {
          'name': 'sowing',
          'minDays': 7,
          'maxDays': 12,
          'description': 'Seed sowing'
        },
        {
          'name': 'germination',
          'minDays': 12,
          'maxDays': 20,
          'description': 'Seedling emergence'
        },
        {
          'name': 'vegetative',
          'minDays': 20,
          'maxDays': 50,
          'description': 'Branch formation'
        },
        {
          'name': 'flowering',
          'minDays': 50,
          'maxDays': 75,
          'description': 'Flowering'
        },
        {
          'name': 'pod_development',
          'minDays': 75,
          'maxDays': 100,
          'description': 'Pod formation'
        },
        {
          'name': 'maturity',
          'minDays': 100,
          'maxDays': 115,
          'description': 'Pod maturation'
        },
        {
          'name': 'harvest',
          'minDays': 115,
          'maxDays': 120,
          'description': 'Harvesting'
        },
      ]),
      createdAt: DateTime.now(),
    );
  }

  CropsCompanion _createTurmeric() {
    return CropsCompanion.insert(
      id: 'crop_turmeric',
      name: 'Turmeric',
      scientificName: const Value('Curcuma longa'),
      category: 'Spice',
      minDurationDays: 210,
      maxDurationDays: 270,
      region: 'South India',
      season: 'Kharif',
      waterRequirement: const Value('Medium'),
      soilTypes: Value(json.encode(['Loamy', 'Clayey', 'Red Soil'])),
      stagesJson: json.encode([
        {
          'name': 'land_preparation',
          'minDays': 0,
          'maxDays': 15,
          'description': 'Deep plowing and bed preparation'
        },
        {
          'name': 'planting',
          'minDays': 15,
          'maxDays': 25,
          'description': 'Rhizome planting'
        },
        {
          'name': 'germination',
          'minDays': 25,
          'maxDays': 45,
          'description': 'Shoot emergence'
        },
        {
          'name': 'vegetative',
          'minDays': 45,
          'maxDays': 120,
          'description': 'Leaf and tiller growth'
        },
        {
          'name': 'rhizome_development',
          'minDays': 120,
          'maxDays': 210,
          'description': 'Rhizome formation'
        },
        {
          'name': 'maturity',
          'minDays': 210,
          'maxDays': 260,
          'description': 'Rhizome maturation'
        },
        {
          'name': 'harvest',
          'minDays': 260,
          'maxDays': 270,
          'description': 'Harvesting rhizomes'
        },
      ]),
      createdAt: DateTime.now(),
    );
  }

  CropsCompanion _createCoconut() {
    return CropsCompanion.insert(
      id: 'crop_coconut',
      name: 'Coconut',
      scientificName: const Value('Cocos nucifera'),
      category: 'Plantation',
      minDurationDays: 1825, // ~5 years to first harvest
      maxDurationDays: 2190,
      region: 'South India',
      season: 'Year-round',
      waterRequirement: const Value('High'),
      soilTypes: Value(json.encode(['Coastal Sandy', 'Loamy', 'Alluvial'])),
      stagesJson: json.encode([
        {
          'name': 'planting',
          'minDays': 0,
          'maxDays': 30,
          'description': 'Sapling planting'
        },
        {
          'name': 'establishment',
          'minDays': 30,
          'maxDays': 365,
          'description': 'Root and shoot establishment'
        },
        {
          'name': 'juvenile',
          'minDays': 365,
          'maxDays': 1460,
          'description': 'Vegetative growth (4 years)'
        },
        {
          'name': 'flowering',
          'minDays': 1460,
          'maxDays': 1825,
          'description': 'First flowering'
        },
        {
          'name': 'maturity',
          'minDays': 1825,
          'maxDays': 2190,
          'description': 'Regular bearing'
        },
      ]),
      createdAt: DateTime.now(),
    );
  }

  CropsCompanion _createBanana() {
    return CropsCompanion.insert(
      id: 'crop_banana',
      name: 'Banana',
      scientificName: const Value('Musa spp.'),
      category: 'Fruit',
      minDurationDays: 270,
      maxDurationDays: 365,
      region: 'South India',
      season: 'Year-round',
      waterRequirement: const Value('High'),
      soilTypes: Value(json.encode(['Loamy', 'Clayey', 'Alluvial'])),
      stagesJson: json.encode([
        {
          'name': 'planting',
          'minDays': 0,
          'maxDays': 15,
          'description': 'Sucker planting'
        },
        {
          'name': 'establishment',
          'minDays': 15,
          'maxDays': 60,
          'description': 'Root and shoot development'
        },
        {
          'name': 'vegetative',
          'minDays': 60,
          'maxDays': 180,
          'description': 'Leaf production'
        },
        {
          'name': 'flowering',
          'minDays': 180,
          'maxDays': 240,
          'description': 'Bunch emergence'
        },
        {
          'name': 'fruit_development',
          'minDays': 240,
          'maxDays': 330,
          'description': 'Fruit filling'
        },
        {
          'name': 'maturity',
          'minDays': 330,
          'maxDays': 360,
          'description': 'Fruit maturation'
        },
        {
          'name': 'harvest',
          'minDays': 360,
          'maxDays': 365,
          'description': 'Bunch harvesting'
        },
      ]),
      createdAt: DateTime.now(),
    );
  }

  CropsCompanion _createTomato() {
    return CropsCompanion.insert(
      id: 'crop_tomato',
      name: 'Tomato',
      scientificName: const Value('Solanum lycopersicum'),
      category: 'Vegetable',
      minDurationDays: 60,
      maxDurationDays: 90,
      region: 'South India',
      season: 'Rabi',
      waterRequirement: const Value('Medium'),
      soilTypes: Value(json.encode(['Loamy', 'Sandy Loam'])),
      stagesJson: json.encode([
        {
          'name': 'nursery',
          'minDays': 0,
          'maxDays': 25,
          'description': 'Seedling raising'
        },
        {
          'name': 'transplanting',
          'minDays': 25,
          'maxDays': 30,
          'description': 'Transplanting to field'
        },
        {
          'name': 'vegetative',
          'minDays': 30,
          'maxDays': 45,
          'description': 'Plant growth'
        },
        {
          'name': 'flowering',
          'minDays': 45,
          'maxDays': 55,
          'description': 'Flower appearance'
        },
        {
          'name': 'fruit_setting',
          'minDays': 55,
          'maxDays': 65,
          'description': 'Fruit formation'
        },
        {
          'name': 'fruit_development',
          'minDays': 65,
          'maxDays': 80,
          'description': 'Fruit growth'
        },
        {
          'name': 'maturity',
          'minDays': 80,
          'maxDays': 85,
          'description': 'Fruit ripening'
        },
        {
          'name': 'harvest',
          'minDays': 85,
          'maxDays': 90,
          'description': 'Harvesting'
        },
      ]),
      createdAt: DateTime.now(),
    );
  }

  CropsCompanion _createBrinjal() {
    return CropsCompanion.insert(
      id: 'crop_brinjal',
      name: 'Brinjal (Eggplant)',
      scientificName: const Value('Solanum melongena'),
      category: 'Vegetable',
      minDurationDays: 90,
      maxDurationDays: 120,
      region: 'South India',
      season: 'Year-round',
      waterRequirement: const Value('Medium'),
      soilTypes: Value(json.encode(['Loamy', 'Sandy Loam'])),
      stagesJson: json.encode([
        {
          'name': 'nursery',
          'minDays': 0,
          'maxDays': 30,
          'description': 'Seedling preparation'
        },
        {
          'name': 'transplanting',
          'minDays': 30,
          'maxDays': 35,
          'description': 'Transplanting'
        },
        {
          'name': 'vegetative',
          'minDays': 35,
          'maxDays': 55,
          'description': 'Plant growth'
        },
        {
          'name': 'flowering',
          'minDays': 55,
          'maxDays': 70,
          'description': 'Flowering'
        },
        {
          'name': 'fruit_setting',
          'minDays': 70,
          'maxDays': 85,
          'description': 'Fruit formation'
        },
        {
          'name': 'harvest',
          'minDays': 85,
          'maxDays': 120,
          'description': 'Continuous harvesting'
        },
      ]),
      createdAt: DateTime.now(),
    );
  }

  CropsCompanion _createOkra() {
    return CropsCompanion.insert(
      id: 'crop_okra',
      name: 'Okra (Ladyfinger)',
      scientificName: const Value('Abelmoschus esculentus'),
      category: 'Vegetable',
      minDurationDays: 50,
      maxDurationDays: 70,
      region: 'South India',
      season: 'Kharif/Rabi',
      waterRequirement: const Value('Medium'),
      soilTypes: Value(json.encode(['Loamy', 'Sandy Loam'])),
      stagesJson: json.encode([
        {
          'name': 'sowing',
          'minDays': 0,
          'maxDays': 5,
          'description': 'Direct seeding'
        },
        {
          'name': 'germination',
          'minDays': 5,
          'maxDays': 12,
          'description': 'Seedling emergence'
        },
        {
          'name': 'vegetative',
          'minDays': 12,
          'maxDays': 30,
          'description': 'Plant growth'
        },
        {
          'name': 'flowering',
          'minDays': 30,
          'maxDays': 40,
          'description': 'Flower appearance'
        },
        {
          'name': 'pod_development',
          'minDays': 40,
          'maxDays': 50,
          'description': 'Pod formation'
        },
        {
          'name': 'harvest',
          'minDays': 50,
          'maxDays': 70,
          'description': 'Continuous harvesting'
        },
      ]),
      createdAt: DateTime.now(),
    );
  }

  CropsCompanion _createChilli() {
    return CropsCompanion.insert(
      id: 'crop_chilli',
      name: 'Chilli',
      scientificName: const Value('Capsicum annuum'),
      category: 'Spice',
      minDurationDays: 120,
      maxDurationDays: 150,
      region: 'South India',
      season: 'Kharif/Rabi',
      waterRequirement: const Value('Medium'),
      soilTypes: Value(json.encode(['Loamy', 'Red Soil'])),
      stagesJson: json.encode([
        {
          'name': 'nursery',
          'minDays': 0,
          'maxDays': 30,
          'description': 'Seedling raising'
        },
        {
          'name': 'transplanting',
          'minDays': 30,
          'maxDays': 35,
          'description': 'Transplanting to field'
        },
        {
          'name': 'vegetative',
          'minDays': 35,
          'maxDays': 60,
          'description': 'Plant growth'
        },
        {
          'name': 'flowering',
          'minDays': 60,
          'maxDays': 80,
          'description': 'Flowering'
        },
        {
          'name': 'fruit_setting',
          'minDays': 80,
          'maxDays': 100,
          'description': 'Fruit formation'
        },
        {
          'name': 'maturity',
          'minDays': 100,
          'maxDays': 140,
          'description': 'Fruit ripening'
        },
        {
          'name': 'harvest',
          'minDays': 140,
          'maxDays': 150,
          'description': 'Harvesting'
        },
      ]),
      createdAt: DateTime.now(),
    );
  }
}
