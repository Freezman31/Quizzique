extension StringPluralization on String {
  String pluralize(int count) {
    return count == 1 ? this : '${this}s';
  }
}
