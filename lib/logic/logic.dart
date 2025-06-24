import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';

Future<bool> isCodeValid(String code, {required Client client}) async {
  if (code.length != 6) {
    return false;
  }
  for (int i = 0; i < code.length; i++) {
    if (!RegExp(r'^\d$').hasMatch(code[i])) {
      return false;
    }
  }
  Databases databases = Databases(client);
  try {
    DocumentList result = await databases.listDocuments(
      databaseId: '6859582600031c46e49c',
      collectionId: '685990a30018382797dc',
      queries: [Query.equal('code', int.parse(code))],
    );
    return result.total > 0;
  } catch (e) {
    print('Error fetching documents: $e');
    return false;
  }
}
