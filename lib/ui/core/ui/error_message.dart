import '../../../data/services/api_client.dart';

/// 화면에 띄울 오류 문구.
///
/// `'$e'`를 그대로 쓰면 `ApiException(null /ranking): 서버에 연결하지 못했어요`
/// 처럼 내부 정보가 사용자에게 노출된다. [ApiClient]가 이미 사람이 읽을
/// 문구를 담아 두므로 그것만 꺼낸다.
String mhErrorMessage(Object error) {
  if (error is ApiException) return error.message;
  return '문제가 생겼어요. 잠시 뒤에 다시 시도해 주세요';
}
