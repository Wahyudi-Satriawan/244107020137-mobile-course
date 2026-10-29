import '../../../../core/failures.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';
import 'validate_note.dart';

class AddNote {
  const AddNote(this._repository, {this.validator = const ValidateNote()});

  final NoteRepository _repository;
  final ValidateNote validator;

  Future<(Note? note, Failure? failure)> call({
    required String title,
    String body = '',
  }) async {
    final validationError = validator(title);
    if (validationError != null) {
      return (null, validationError);
    }

    return _repository.addNote(title: title.trim(), body: body.trim());
  }
}
