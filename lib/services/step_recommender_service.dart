import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'dart:typed_data';

class StepRecommenderService {
  static final StepRecommenderService _instance = StepRecommenderService._internal();
  factory StepRecommenderService() => _instance;
  StepRecommenderService._internal();

  OrtSession? _session;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      OrtEnv.instance.init();

      final sessionOptions = OrtSessionOptions();
      const assetFileName = 'assets/models/step_recommendor.onnx';
      
      final rawAssetFile = await rootBundle.load(assetFileName);
      final bytes = rawAssetFile.buffer.asUint8List();
      
      final documentsDir = await getApplicationDocumentsDirectory();
      final modelFile = File('${documentsDir.path}/step_recommendor.onnx');
      await modelFile.writeAsBytes(bytes);

      _session = OrtSession.fromFile(modelFile, sessionOptions);
      _isInitialized = true;
      print("Adım Öneri Modeli Başarıyla Yüklendi");

    } catch (e) {
      print("Model Yükleme Hatası: $e");
    }
  }

  Future<int> predictDailySteps({
    required int age,
    required String gender,
    required double weightKg,
    required double heightCm,
    required double sedentaryHours,
    required bool doSport,
    required int healthRating,
  }) async {
    if (!_isInitialized || _session == null) {
      await init();
    }

    try {
      double genderVal = (gender.toLowerCase() == "female") ? 1.0 : 0.0;
      double heightM = heightCm / 100.0;
      double bmi = weightKg / (heightM * heightM);

      double bmiClass;
      if (bmi < 18.5) bmiClass = 0.0;
      else if (bmi < 25) bmiClass = 1.0;
      else if (bmi < 30) bmiClass = 2.0;
      else bmiClass = 3.0;

      double ageBmi = age * bmi;
      double sedentaryMin = sedentaryHours * 60.0;

      double vigorousSport = 0.0;
      double moderateSport = doSport ? 1.0 : 0.0;

      List<double> inputData = [
        age.toDouble(),
        genderVal,
        weightKg,
        heightM,
        bmi,
        bmiClass,
        ageBmi,
        sedentaryMin,
        vigorousSport,
        moderateSport,
        healthRating.toDouble(),
      ];

      final float32Data = Float32List.fromList(inputData);

      final inputOrt = OrtValueTensor.createTensorWithDataList(
        float32Data, 
        [1, 11]
      );

      final inputName = _session!.inputNames[0];
      final inputs = {inputName: inputOrt};
      
      final runOptions = OrtRunOptions();
      final outputs = _session!.run(runOptions, inputs);
      
      final rawResult = (outputs[0]?.value as List)[0][0] as double;

      inputOrt.release();
      runOptions.release();
      outputs.forEach((element) => element?.release());

      double adjustedSteps = rawResult;
      if (age > 60 || healthRating >= 4) {
        adjustedSteps = rawResult * 0.90;
      }

      int roundedSteps = (adjustedSteps / 250).round() * 250;

      return roundedSteps;

    } catch (e) {
      print("Tahmin Hatası: $e");
      return 7500;
    }
  }

  void dispose() {
    _session?.release();
    OrtEnv.instance.release();
  }
}