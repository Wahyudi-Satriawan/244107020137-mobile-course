import '../../../../core/failures.dart';

class ValidateNote {
  const ValidateNote();

  ValidationFailure? call(String? title) {
    if (title == null || title.trim().isEmpty) {
      return const ValidationFailure('Judul tidak boleh kosong');
    }
    if (title.trim().length < 3) {
      return const ValidationFailure('Judul minimal 3 karakter');
    }
    return null;
  }
}
