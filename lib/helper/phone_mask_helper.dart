/// Masks a phone number for display, e.g. `+96650*****123`.
///
/// Safe for short/odd input (never throws) and wrapped in Unicode "left to
/// right isolate" marks so the `+`, digits and `*` keep their order inside
/// right-to-left (Arabic) text instead of being reshuffled.
String maskPhoneNumber(String number) {
  final String lri = String.fromCharCode(0x2066); // LEFT-TO-RIGHT ISOLATE
  final String pdi = String.fromCharCode(0x2069); // POP DIRECTIONAL ISOLATE
  final String n = number.trim();
  String masked;
  if (n.length >= 9) {
    masked = '${n.substring(0, 5)}*****${n.substring(n.length - 3)}';
  } else if (n.length > 3) {
    masked = '${n.substring(0, 1)}${'*' * (n.length - 3)}${n.substring(n.length - 2)}';
  } else {
    masked = n;
  }
  return '$lri$masked$pdi';
}
