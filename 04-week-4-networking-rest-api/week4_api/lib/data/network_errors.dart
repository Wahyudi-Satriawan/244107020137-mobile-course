import 'package:dio/dio.dart';

String friendlyErrorMessage(Object? error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'Koneksi bermasalah. Periksa internet Anda.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 404) return 'Data tidak ditemukan (404).';
        if (code != null && code >= 500) return 'Server sedang bermasalah ($code).';
        return 'Terjadi kesalahan dari server ($code).';
      default:
        return 'Terjadi kesalahan jaringan yang tidak dikenal.';
    }
  }
  return 'Terjadi kesalahan sistem: $error';
}