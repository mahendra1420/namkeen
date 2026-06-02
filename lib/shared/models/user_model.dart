enum UserRole { admin, retailer }

class UserModel {
  final String id;
  final String name;
  final String? surname;
  final String phone;
  final String? secondPhone;
  final String? password;
  final UserRole role;
  final String? shopName;
  final String? gstNumber;
  final String? address;
  final bool isApproved;
  final bool isBlocked;
  final double creditBalance;

  UserModel({
    required this.id,
    required this.name,
    this.surname,
    required this.phone,
    this.secondPhone,
    this.password,
    required this.role,
    this.shopName,
    this.gstNumber,
    this.address,
    this.isApproved = false,
    this.isBlocked = false,
    this.creditBalance = 0.0,
  });

  // JSON Serialization
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      surname: json['surname'] as String?,
      phone: json['phone'] as String,
      secondPhone: json['secondPhone'] as String?,
      password: json['password'] as String?,
      role: UserRole.values.firstWhere((e) => e.name == json['role'], orElse: () => UserRole.retailer),
      shopName: json['shopName'] as String?,
      gstNumber: json['gstNumber'] as String?,
      address: json['address'] as String?,
      isApproved: json['isApproved'] as bool? ?? false,
      isBlocked: json['isBlocked'] as bool? ?? false,
      creditBalance: (json['creditBalance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'phone': phone,
      'secondPhone': secondPhone,
      'password': password,
      'role': role.name,
      'shopName': shopName,
      'gstNumber': gstNumber,
      'address': address,
      'isApproved': isApproved,
      'isBlocked': isBlocked,
      'creditBalance': creditBalance,
    };
  }
}
