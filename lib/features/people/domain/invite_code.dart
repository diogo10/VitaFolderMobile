final _formattingChars = RegExp(r'[\s\-_]');
final _validCode = RegExp(r'^[A-Z0-9]{6}$');

/// Normalizes raw user input into the canonical invite-code form.
///
/// Trims surrounding whitespace, drops inner separators (spaces, dashes,
/// underscores — e.g. from the `XX-0000` hint era or pasted links) and
/// uppercases, so `ab-1234` becomes `AB1234`.
String normalizeInviteCode(String raw) {
  return raw.trim().toUpperCase().replaceAll(_formattingChars, '');
}

/// Whether [code] is a canonical invite code (`[A-Z0-9]{6}`).
bool isValidInviteCode(String code) {
  return _validCode.hasMatch(code);
}
