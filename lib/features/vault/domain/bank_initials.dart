/// Avatar letters for a bank: first letters of the first two words
/// ("Harbour Bank" -> "HB"), or the first two letters of a single word
/// ("Nordea" -> "NO").
String bankInitials(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  String first(String s, int n) => String.fromCharCodes(s.runes.take(n));
  final letters = words.length == 1
      ? first(words.first, 2)
      : words.take(2).map((w) => first(w, 1)).join();
  return letters.toUpperCase();
}
