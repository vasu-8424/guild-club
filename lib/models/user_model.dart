class ChildProfileModel {
  final String id;
  final String name;
  final int age;
  final String gender;
  final List<String> interests;
  final String favoriteCharacter;
  final String learningLevel;

  const ChildProfileModel({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.interests,
    required this.favoriteCharacter,
    required this.learningLevel,
  });
}

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String avatarUrl;
  final int rewardCoins;
  final List<ChildProfileModel> children;
  final bool isAdmin;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    this.rewardCoins = 350,
    this.children = const [],
    this.isAdmin = true,
  });
}
