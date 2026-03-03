class PaymentSavedCard {
  const PaymentSavedCard({
    required this.cardholderName,
    required this.cardNumber,
    required this.expiration,
    required this.cvv,
    required this.bankName,
    required this.cardAlias,
  });

  final String cardholderName;
  final String cardNumber;
  final String expiration;
  final String cvv;
  final String bankName;
  final String cardAlias;
}
