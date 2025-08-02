class Constants {
  static String appwriteUrl = '';
  static String appwriteProjectId = '';
  static String databaseId = '';
  static String usersCollectionId = '';
  static String quizzesCollectionId = '';
  static String answersCollectionId = '';
  static String gamesCollectionId = '';
  static String answerCheckFunctionId = '';
  static String url = '';
  static String port = '';
  static bool isDemo = false;

  static void init({
    required String appwriteUrl,
    required String appwriteProjectId,
    required String databaseId,
    required String usersCollectionId,
    required String quizzesCollectionId,
    required String answersCollectionId,
    required String gamesCollectionId,
    required String answerCheckFunctionId,
    required String url,
    String port = '',
    bool isDemo = false,
  }) {
    Constants.appwriteUrl = appwriteUrl;
    Constants.appwriteProjectId = appwriteProjectId;
    Constants.databaseId = databaseId;
    Constants.usersCollectionId = usersCollectionId;
    Constants.quizzesCollectionId = quizzesCollectionId;
    Constants.answersCollectionId = answersCollectionId;
    Constants.gamesCollectionId = gamesCollectionId;
    Constants.answerCheckFunctionId = answerCheckFunctionId;
    Constants.url = url;
    Constants.port = port;
    Constants.isDemo = isDemo;
  }
}
