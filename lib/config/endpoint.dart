class Endpoint {
  //auth
  static const String authLoginUrl = '/api/auth/login';
  static const String logoutUrl = '/api/auth/logout';

  // dashboard
  static const String dashboardUrl = '/api/dashboard';


  // activities role admin
  static const String activityRoleAdmin = '/api/activities';


  // users role by admin
  static const String usersByAdmin = '/api/users';

  static const String productUrl = '/api/products';
  static const String categoriesUrl = '/api/categories';

  // profile
  static const String profileUrl = '/api/auth/profile';

  //stock in
  static const String stockInHistoryUrl = '/api/stock-ins/history';
  static const String stockInUrl = '/api/stock-ins';

  static const String stockOutUrl = '/api/stock-outs';

  static const String stockInReports = '/api/reports/stock-ins';
  static const String stockInPDF = '/api/reports/stock-ins/pdf';
  static const String stockOutPDF = '/api/reports/stock-outs/pdf';
  static const String stockOutsReports = '/api/reports/stock-outs';

}