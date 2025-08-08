class Sales {
  final String label;
  final int earning;

  Sales(this.label, this.earning);

  /// Parses a JSON map into a Sales instance,
  /// defaulting to 0 if `earning` is null or missing.
  factory Sales.fromJson(Map<String, dynamic> json) {
    // Extract label safely (empty string if missing)
    final label = json['label'] as String? ?? '';

    // Extract earning:
    //  - if it's already an int, use it
    //  - if it's a num (double), convert to int
    //  - if null or missing, default to 0
    final dynamic raw = json['earning'];
    final int earning = raw is int
        ? raw
        : raw is num
        ? raw.toInt()
        : 0;

    return Sales(label, earning);
  }
}
