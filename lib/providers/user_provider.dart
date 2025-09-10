import 'package:flutter/widgets.dart';
import 'package:memesworld/models/user.dart';
import 'package:memesworld/resources/auth_methods.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  final AuthMethods _authMethods = AuthMethods();

  User get getUser => _user!;
  User? get userOrNull => _user;
  bool get isLoaded => _user != null;

  Future<void> refreshUser() async {
    User user = await _authMethods.getUserDetails();
    _user = user;
    notifyListeners();
  }
}
