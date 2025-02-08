class UserPayload {
  static UserPayload fromJson(Map<String, dynamic> json) {
    return UserPayload(
      User.fromJson(json["user"]),
    );
  }

  const UserPayload(this.user);

  final User user;
}

class User {
  static User fromJson(Map<String, dynamic> json) {
    return User(
      token: json["token"],
      id: json["id"],
      email: json["email"],
      status: json["status"],
      firstName: json["first_name"],
      lastName: json["last_name"],
      profilePicture: json["profile_picture"],
      created: json["created"],
      admin: json["admin"],
      defaultShow: json["default_show"],
      defaultShowOrder: json["default_show_order"],
    );
  }

  const User({
    required this.token,
    required this.id,
    required this.email,
    required this.status,
    required this.firstName,
    required this.lastName,
    this.profilePicture,
    required this.created,
    required this.admin,
    required this.defaultShow,
    required this.defaultShowOrder,
  });

  final String token;

  final String id;
  final String email;
  final String status;
  final String firstName;
  final String lastName;
  final String? profilePicture;

  final String created;
  final int admin;
  final String? defaultShow;
  final String defaultShowOrder;
}
