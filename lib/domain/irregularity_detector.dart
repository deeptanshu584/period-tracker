enum CycleRegularity {
  regular,
  slightlyIrregular,
  irregular,
  insufficientData,
}

class IrregularityDetector {
  static CycleRegularity detect(List<int> gaps, double rollingAverage) {
    if (gaps.length < 2) {
      return CycleRegularity.insufficientData;
    }

    final lookback = gaps.length > 6 ? gaps.sublist(gaps.length - 6) : gaps;
    int irregularCount = 0;

    for (final gap in lookback) {
      if ((gap - rollingAverage).abs() > 7) {
        irregularCount++;
      }
    }

    if (irregularCount >= 2) return CycleRegularity.irregular;
    if (irregularCount == 1) return CycleRegularity.slightlyIrregular;
    return CycleRegularity.regular;
  }

  static String buildExplanation(List<int> gaps, double rollingAverage) {
    if (gaps.isEmpty) return "Not enough data to determine regularity.";

    final lastGap = gaps.last;
    final diff = lastGap - rollingAverage;

    if (diff > 0) {
      return "Your last cycle was ${diff.round()} days longer than your average.";
    } else if (diff < 0) {
      return "Your last cycle was ${diff.abs().round()} days shorter than your average.";
    } else {
      return "Your last cycle matched your average exactly.";
    }
  }
}
