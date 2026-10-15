String formatDate(DateTime dateTime) {
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final year = dateTime.year.toString();
  return '$day/$month/$year';
}

String truncateToken(String token, {int maxLength = 12}) {
  if (token.isEmpty) return '';
  return token.length > maxLength
      ? '${token.substring(0, maxLength)}...'
      : token;
}
