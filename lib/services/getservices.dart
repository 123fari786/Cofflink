import 'package:googleapis_auth/auth_io.dart';

class GetServiceKey {
  Future<String> getServiceToken() async {
    try {
      final scopes = [
        'https://www.googleapis.com/auth/cloud-platform',
        'https://www.googleapis.com/auth/firebase.messaging',
      ];

      final credentials = ServiceAccountCredentials.fromJson({
        "type": "service_account",
        "project_id": "cofflink-11119",
        "private_key_id": "0218c31f3c9eb4f1b0f3fefa25ef2e50a4875634",
        "private_key":
            "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDODmb2pL67AHWz\n7TRL+xUE0glhR4q3IsvV+KNI1eGGpmDRDUzln442dtziiDs3fkge1CsxWJ87Lrn7\nvCmUy4C2CgpzwgzqSPYFiyuHY1/Fd3zMTuWFG4+Ly+w6rAEuau2AsPwICGpyugYg\nzJP0N+7FWiyRL6d28cZJLvd1zPirfoz6vQpOCikq/rjMvjlhnuP30r4Xvqn/w5H0\n1O5HxJ6VMaYE5vA2QtCgfIf6w7rCud3e6tDLARyWjSDBXhXOVoCrEJg8vbcyqqI2\nePEuPl595LARJQp3eOmCef8kIsHgfK6Cf29uEehFZ8XBxt0XEfxxOPyX3B76WMip\njubULw4vAgMBAAECggEAFlwCuT3cQn+Exi71r08CE2FVSjyQpVm9w6y0zzkCPXG9\nbMHkN8COFoPkaSJ+RoHKAqpkO3kR4kKqRNJAstg4UciaJMCIVT3wkF5vLURPxqY2\nIRdomX6Jn5JTwnQatrY8qmvKFXcQUf20n4eDgIs3OiwUTPbeVa5bpWJW0O4ah8VE\nSI0VKARrO4khW6glKDFbLhb+aetivPr6TuciWf0Yq7ktStojAYs5BYyOBw1ljZqu\n5IUXfz3X4UD+2lHE8TCWbOkhUIGEkSXcY76DgHAIqo4N3YlwiTUWcHfKaXFZ4hvW\nvx9JPBNp5k2FCDhZTrxaVooUeUtW2A1z8a6kO0BHCQKBgQDz6lL76FZcf67q8k2j\n16mK5PBzZ/ULJ8SibP3apgHbpDO1d9EdD3F/35R501OmF1Ld1FHGESqviZOTT1BT\n55LN8k6I1YBSEdaemS9+/E6GPTGIjoBJdm0uE/X58goVdjFx2HHQlpr8ZwIWOJNK\njWUYrpUdHbD2r3hebg2cqJk/aQKBgQDYQ+VzNMc/V7F4eT63L1U3HI+oe4/Isj5/\nb+Kx5I6YN9wMBD3FDUlrpvwxhKzp4sbc754rxzLYt6DCcPgqzRjGfBTUXJKLtlAG\npwcg/Dn/N6gIqB/h797NJAcKGdw4l84vXUlGPMss9qB1WsASXR88GnXUvIBuh05/\nQBwVmVfF1wKBgC5AMYoYzT9u6rEcTwKRY1G2Ba4seTerS8rs1dn+/n0yjqeLV7il\n9ASmVZYgL01gQNNVbkgbezeb48LcGERAtgKdPq0Npu5o+YRLUclHeHBV7C2Tr9m+\nPgetu0ew0J6vMcL/ot1FoY/YzHmAMtXBJ/ldKWNC/QpZzX5CagxZn+15AoGAeBYj\nh7hL1zFzm2j/2SpQUDzszGpoKdJH/+153LwELiP+bTHBtvSsyzk7GqgIeArzz+TC\nWJ7Q7iPxAWdHdkTSuAxYaJ9KxIekoj0HKVrFPaGDDeOFaKkQd6rEuegoL8ijtgs/\nz9+cFkiQSvnsY4YP/QjYWxuc2UMK5IAN2DSA15sCgYAwy+IAj3vITlI/Nkku3Obb\nrbvHvA+ofH4xffdxVv0Mn1w19r4qd3erOZmVlSoJ5mNxuXjvBrGFHAyLDwVedHC3\nRsbyYepQ/4+dLp2qjyi5DfyTwTi7D9uIkqnRyjP0YynJQWWSYbhevPd+/SS/h8uV\nNKUWR5oSUv8nyg3mpbnmDg==\n-----END PRIVATE KEY-----\n",
        "client_email":
            "firebase-adminsdk-fbsvc@cofflink-11119.iam.gserviceaccount.com",
        "client_id": "114916593199610807074",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url":
            "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url":
            "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40cofflink-11119.iam.gserviceaccount.com",
        "universe_domain": "googleapis.com",
      });

      final client = await clientViaServiceAccount(credentials, scopes);
      final accessToken = client.credentials.accessToken.data;
      print("Access Token: $accessToken");
      return accessToken;
    } catch (e) {
      print("Error getting service token: $e");
      rethrow;
    }
  }
}
