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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'interests': interests,
      'favorite_character': favoriteCharacter,
      'learning_level': learningLevel,
    };
  }

  factory ChildProfileModel.fromJson(Map<String, dynamic> json) {
    return ChildProfileModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      age: json['age'] != null ? (json['age'] as num).toInt() : 0,
      gender: json['gender']?.toString() ?? 'boy',
      interests: json['interests'] != null
          ? List<String>.from(json['interests'] as List)
          : <String>[],
      favoriteCharacter: json['favorite_character']?.toString() ??
          json['favoriteCharacter']?.toString() ??
          '',
      learningLevel: json['learning_level']?.toString() ??
          json['learningLevel']?.toString() ??
          'Explorer',
    );
  }

  ChildProfileModel copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    List<String>? interests,
    String? favoriteCharacter,
    String? learningLevel,
  }) {
    return ChildProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      interests: interests ?? this.interests,
      favoriteCharacter: favoriteCharacter ?? this.favoriteCharacter,
      learningLevel: learningLevel ?? this.learningLevel,
    );
  }
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

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    int? rewardCoins,
    List<ChildProfileModel>? children,
    bool? isAdmin,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rewardCoins: rewardCoins ?? this.rewardCoins,
      children: children ?? this.children,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
