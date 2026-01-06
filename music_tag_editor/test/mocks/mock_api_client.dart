import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart';

class MockHttpClient extends Mock implements Client {}

void setupMockSuccess(MockHttpClient client, String body, {int statusCode = 200}) {
  when(() => client.get(any())).thenAnswer((_) async => 
    Response(body, statusCode)
  );
}

void setupMockPostSuccess(MockHttpClient client, String body, {int statusCode = 200}) {
  when(() => client.post(any(), body: any(named: 'body'), headers: any(named: 'headers')))
      .thenAnswer((_) async => Response(body, statusCode));
}
