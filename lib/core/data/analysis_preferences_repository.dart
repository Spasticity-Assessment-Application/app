import 'package:shared_preferences/shared_preferences.dart';

/// Repository pour gérer les préférences de configuration d'analyse
/// Ces préférences sont persistées pour que l'utilisateur retrouve
/// ses derniers réglages lors de la prochaine analyse
class AnalysisPreferencesRepository {
  AnalysisPreferencesRepository._();
  static final AnalysisPreferencesRepository instance =
      AnalysisPreferencesRepository._();

  static const _keyModel = 'analysis_model';
  static const _keyFrameCount = 'analysis_frame_count';
  static const _keyThreshold = 'analysis_threshold';
  static const _keyAdvancedMode = 'analysis_advanced_mode';

  // Valeurs par défaut
  static const String defaultModel = 'mnv3l';
  static const int defaultFrameCount = 60;
  static const double defaultThreshold = 0.0;
  static const bool defaultAdvancedMode = false;

  Future<String> loadModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyModel) ?? defaultModel;
  }

  Future<void> saveModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyModel, model);
  }

  Future<int> loadFrameCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyFrameCount) ?? defaultFrameCount;
  }

  Future<void> saveFrameCount(int frameCount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyFrameCount, frameCount);
  }

  Future<double> loadThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyThreshold) ?? defaultThreshold;
  }

  Future<void> saveThreshold(double threshold) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyThreshold, threshold);
  }

  Future<bool> loadAdvancedMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAdvancedMode) ?? defaultAdvancedMode;
  }

  Future<void> saveAdvancedMode(bool isAdvanced) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAdvancedMode, isAdvanced);
  }

  Future<AnalysisPreferences> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    return AnalysisPreferences(
      model: prefs.getString(_keyModel) ?? defaultModel,
      frameCount: prefs.getInt(_keyFrameCount) ?? defaultFrameCount,
      threshold: prefs.getDouble(_keyThreshold) ?? defaultThreshold,
      isAdvancedMode: prefs.getBool(_keyAdvancedMode) ?? defaultAdvancedMode,
    );
  }

  Future<void> saveAll(AnalysisPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_keyModel, preferences.model),
      prefs.setInt(_keyFrameCount, preferences.frameCount),
      prefs.setDouble(_keyThreshold, preferences.threshold),
      prefs.setBool(_keyAdvancedMode, preferences.isAdvancedMode),
    ]);
  }

  Future<void> resetToDefaults() async {
    await saveAll(AnalysisPreferences.defaults());
  }
}

class AnalysisPreferences {
  final String model;
  final int frameCount;
  final double threshold;
  final bool isAdvancedMode;

  const AnalysisPreferences({
    required this.model,
    required this.frameCount,
    required this.threshold,
    required this.isAdvancedMode,
  });

  factory AnalysisPreferences.defaults() {
    return const AnalysisPreferences(
      model: AnalysisPreferencesRepository.defaultModel,
      frameCount: AnalysisPreferencesRepository.defaultFrameCount,
      threshold: AnalysisPreferencesRepository.defaultThreshold,
      isAdvancedMode: AnalysisPreferencesRepository.defaultAdvancedMode,
    );
  }
}
