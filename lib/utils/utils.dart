extension StringPluralization on String {
  String pluralize(int count) {
    return count == 1 ? this : '${this}s';
  }
}

extension StringOrdinal on int {
  String ordinate() {
    if (this == 1) return '${this}st';
    if (this == 2) return '${this}nd';
    if (this == 3) return '${this}rd';
    return '${this}th';
  }
}

extension StringNumberExtension on String {
  String spaceSeparateNumbers() {
    return padLeft(6, '0').replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }
}

extension StringMaxLength on String {
  String max(int newLength) {
    if (length <= newLength) return this;
    return '${substring(0, newLength - 3)}...';
  }
}

bool isEmailValid(String email) {
  final RegExp emailRegex = RegExp(
    r'''(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])''',
  );
  return emailRegex.hasMatch(email);
}
