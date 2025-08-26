class Constants {
  static String appwriteUrl = '';
  static String appwriteProjectId = '';
  static String databaseId = '';
  static String usersTableId = '';
  static String quizzesTableId = '';
  static String answersTableId = '';
  static String gamesTableId = '';
  static String answerCheckFunctionId = '';
  static String scoresTableId = '';
  static String url = '';
  static String port = '';
  static bool isDemo = false;

  static void init({
    required String appwriteUrl,
    required String appwriteProjectId,
    required String databaseId,
    required String usersTableId,
    required String quizzesTableId,
    required String answersTableId,
    required String gamesTableId,
    required String answerCheckFunctionId,
    required String scoresTableId,
    required String url,
    String port = '',
    bool isDemo = false,
  }) {
    Constants.appwriteUrl = appwriteUrl;
    Constants.appwriteProjectId = appwriteProjectId;
    Constants.databaseId = databaseId;
    Constants.usersTableId = usersTableId;
    Constants.quizzesTableId = quizzesTableId;
    Constants.answersTableId = answersTableId;
    Constants.gamesTableId = gamesTableId;
    Constants.answerCheckFunctionId = answerCheckFunctionId;
    Constants.scoresTableId = scoresTableId;
    Constants.url = url;
    Constants.port = port;
    Constants.isDemo = isDemo;
  }
}
