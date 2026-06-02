class PaymentModel {
  final String id;
  final String retailerId;
  final double amount;
  final DateTime date;
  final String? reference;

  PaymentModel({
    required this.id,
    required this.retailerId,
    required this.amount,
    required this.date,
    this.reference,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      retailerId: json['retailerId'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      reference: json['reference'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'retailerId': retailerId,
      'amount': amount,
      'date': date.toIso8601String(),
      'reference': reference,
    };
  }
}
