enum NumberScale { thousand, million, billion }

String formatNumberAbbreviation(
    double number, {
      int decimalPlaces = 1,
      NumberScale scale = NumberScale.thousand,
      bool showSuffix = true, // ✅ new flag
    }) {
  String suffix = "";
  if (showSuffix) {
    suffix = number < 0 ? " (DR)" : " (CR)";
  }

  double absNumber = number.abs();
  String formatted;

  switch (scale) {
    case NumberScale.thousand:
      formatted = (absNumber / 1000)
          .toStringAsFixed(decimalPlaces)
          .replaceAll(RegExp(r"\.0+$"), "") +
          "K";
      break;
    case NumberScale.million:
      formatted = (absNumber / 1000000)
          .toStringAsFixed(decimalPlaces)
          .replaceAll(RegExp(r"\.0+$"), "") +
          "M";
      break;
    case NumberScale.billion:
      formatted = (absNumber / 1000000000)
          .toStringAsFixed(decimalPlaces)
          .replaceAll(RegExp(r"\.0+$"), "") +
          "B";
      break;
  }

  return formatted + suffix;
}

