String formatMonero(num? amt) {
  if (amt == null) {
    return "";
  }
  if (amt == 0) {
    return "0";
  }
  return (((amt / 1e12 * 1e8)).floor() / 1e8).toStringAsFixed(8);
  // var formatter = NumberFormat("###.####");
  // formatter.maximumFractionDigits = minimumFractions;
  // formatter.minimumFractionDigits = minimumFractions;
  // try {
  //   return formatter.format(value / 1e12);
  // } catch (e) {
  //   if (kDebugMode) {
  //     print(e);
  //   }
  //   return "";
  // }
}
