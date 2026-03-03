class PaymentSavedCard {
  const PaymentSavedCard({
    this.paymentCardId,
    required this.cardholderName,
    required this.cardNumber,
    required this.expiration,
    required this.cvc,
    required this.bankName,
    required this.cardAlias,
  });

  final String? paymentCardId;
  final String cardholderName;
  final String cardNumber;
  final String expiration;
  final String cvc;
  final String bankName;
  final String cardAlias;

  factory PaymentSavedCard.fromJson(Map<String, dynamic> json) {
    return PaymentSavedCard(
      paymentCardId: json['paymentCardId']?.toString(),
      cardholderName: json['cardholderName']?.toString() ?? '',
      cardNumber: json['cardNumber']?.toString() ?? '',
      expiration: json['expiration']?.toString() ?? '',
      cvc: (json['cvc'] ?? json['CVC'] ?? json['cvv'])?.toString() ?? '',
      bankName: json['bankName']?.toString() ?? 'BANK NAME',
      cardAlias: json['cardAlias']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'cardholderName': cardholderName,
      'cardNumber': cardNumber,
      'expiration': expiration,
      'cvc': cvc,
      'bankName': bankName,
      'cardAlias': cardAlias,
      'createdAtUtc': DateTime.now().toUtc().toIso8601String(),
    };
  }

  PaymentSavedCard copyWith({
    String? paymentCardId,
    String? cardholderName,
    String? cardNumber,
    String? expiration,
    String? cvc,
    String? bankName,
    String? cardAlias,
  }) {
    return PaymentSavedCard(
      paymentCardId: paymentCardId ?? this.paymentCardId,
      cardholderName: cardholderName ?? this.cardholderName,
      cardNumber: cardNumber ?? this.cardNumber,
      expiration: expiration ?? this.expiration,
      cvc: cvc ?? this.cvc,
      bankName: bankName ?? this.bankName,
      cardAlias: cardAlias ?? this.cardAlias,
    );
  }
}
