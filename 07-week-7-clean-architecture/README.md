

|File|Layer saat ini|Masalah|
|-|-|-|
|pages/home\_page.dart|presentation|memanggil Dio langsung? memformat tanggal + parsing JSON di widget?|
|data/api\_client.dart|data|OK bila hanya dipakai repository, bukan widget|
|providers/auth\_provider.dart|presentation (state)|OK bila hanya memanggil repository/use case|
|data/auth\_repository.dart|data (+kontrak tercampur)|interface dan implementasi masih satu kelas|



