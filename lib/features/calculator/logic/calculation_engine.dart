import '../../../models/processing_result.dart';

class CalculationEngine {
  String? validate(ProcessingResult result) {
    if (!result.liveWeightKg.isFinite || result.liveWeightKg <= 0) {
      return 'Tirik vazn 0 dan katta son bo‘lishi kerak.';
    }
    if (result.measuredOutputs.any(
      (entry) => !entry.$2.isFinite || entry.$2 < 0,
    )) {
      return 'Mahsulot vaznlari manfiy yoki noto‘g‘ri formatda bo‘lishi mumkin emas.';
    }
    if (result.totalMeasuredKg > result.liveWeightKg) {
      return 'Jami o‘lchangan mahsulot vazni tirik vazndan katta bo‘lishi mumkin emas.';
    }
    return null;
  }
}
