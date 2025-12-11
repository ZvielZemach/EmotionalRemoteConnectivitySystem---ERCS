
enum UserType{
  myPrinces,
  herPrince
}

class User {
  const User({
    required this.name,
    required this.password,
    required this.userType
  });

    final String name;
    final String password;
    final UserType userType;
}