/// Card validation result
class CardValidationResult {
  final bool isValid;
  final String? error;
  final String? cardType;

  CardValidationResult({
    required this.isValid,
    this.error,
    this.cardType,
  });
}

/// Card validation utility class
/// Uses custom validation logic since credit_card_validator package
/// doesn't export all needed types
class CardValidator {

  /// Validate card number using Luhn algorithm
  static bool _luhnCheck(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\s+'), '');
    int sum = 0;
    bool isEven = false;

    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanNumber[i]);

      if (isEven) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      isEven = !isEven;
    }

    return sum % 10 == 0;
  }

  /// Detect card type from number
  static String? _detectCardType(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\s+'), '');
    
    if (cleanNumber.isEmpty) return null;
    
    // Visa: starts with 4
    if (RegExp(r'^4').hasMatch(cleanNumber)) {
      return 'visa';
    }
    // Mastercard: starts with 5 or 2
    if (RegExp(r'^5[1-5]|^2[2-7]').hasMatch(cleanNumber)) {
      return 'mastercard';
    }
    // American Express: starts with 34 or 37
    if (RegExp(r'^3[47]').hasMatch(cleanNumber)) {
      return 'amex';
    }
    // Discover: starts with 6
    if (RegExp(r'^6(?:011|5)').hasMatch(cleanNumber)) {
      return 'discover';
    }
    // Diners Club: starts with 30, 36, or 38
    if (RegExp(r'^3[068]').hasMatch(cleanNumber)) {
      return 'diners';
    }
    // JCB: starts with 35
    if (RegExp(r'^35').hasMatch(cleanNumber)) {
      return 'jcb';
    }
    
    return null;
  }

  /// Validate card number
  static CardValidationResult validateCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\s+'), '');
    
    if (cleanNumber.isEmpty) {
      return CardValidationResult(
        isValid: false,
        error: 'Card number is required',
      );
    }

    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return CardValidationResult(
        isValid: false,
        error: 'Card number must be between 13 and 19 digits',
      );
    }

    if (!RegExp(r'^\d+$').hasMatch(cleanNumber)) {
      return CardValidationResult(
        isValid: false,
        error: 'Card number must contain only digits',
      );
    }

    final cardType = _detectCardType(cleanNumber);
    
    // Validate length based on card type
    if (cardType == 'amex' && cleanNumber.length != 15) {
      return CardValidationResult(
        isValid: false,
        error: 'American Express cards must have 15 digits',
        cardType: cardType,
      );
    }
    
    if (cardType != null && cardType != 'amex' && cleanNumber.length != 16) {
      return CardValidationResult(
        isValid: false,
        error: 'Card number must have 16 digits',
        cardType: cardType,
      );
    }

    if (!_luhnCheck(cleanNumber)) {
      return CardValidationResult(
        isValid: false,
        error: 'Invalid card number',
        cardType: cardType,
      );
    }

    return CardValidationResult(
      isValid: true,
      cardType: cardType,
    );
  }

  /// Validate CVV
  static CardValidationResult validateCVV(String cvv, String? cardNumber) {
    if (cvv.isEmpty) {
      return CardValidationResult(
        isValid: false,
        error: 'CVV is required',
      );
    }

    if (!RegExp(r'^\d+$').hasMatch(cvv)) {
      return CardValidationResult(
        isValid: false,
        error: 'CVV must contain only digits',
      );
    }

    int expectedLength = 3;
    if (cardNumber != null && cardNumber.isNotEmpty) {
      final cardType = _detectCardType(cardNumber);
      if (cardType == 'amex') {
        expectedLength = 4;
      }
    }

    if (cvv.length != expectedLength) {
      return CardValidationResult(
        isValid: false,
        error: 'CVV must be $expectedLength digits',
      );
    }

    return CardValidationResult(isValid: true);
  }

  /// Validate expiry date
  static CardValidationResult validateExpiryDate(String expiryDate) {
    final cleanDate = expiryDate.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanDate.isEmpty) {
      return CardValidationResult(
        isValid: false,
        error: 'Expiry date is required',
      );
    }

    if (cleanDate.length < 4) {
      return CardValidationResult(
        isValid: false,
        error: 'Please enter MM/YY',
      );
    }

    final month = int.tryParse(cleanDate.substring(0, 2));
    final year = int.tryParse(cleanDate.substring(2, 4));

    if (month == null || year == null) {
      return CardValidationResult(
        isValid: false,
        error: 'Invalid date format',
      );
    }

    if (month < 1 || month > 12) {
      return CardValidationResult(
        isValid: false,
        error: 'Invalid month',
      );
    }

    final now = DateTime.now();
    final currentYear = now.year % 100;
    final currentMonth = now.month;

    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return CardValidationResult(
        isValid: false,
        error: 'Card has expired',
      );
    }

    return CardValidationResult(isValid: true);
  }

  /// Get card type from number
  static String? getCardType(String cardNumber) {
    return _detectCardType(cardNumber);
  }

  /// Format card number with spaces
  static String formatCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\s+'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < cleanNumber.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(cleanNumber[i]);
    }
    return buffer.toString();
  }

  /// Format expiry date (MM/YY)
  static String formatExpiryDate(String expiryDate) {
    final cleanDate = expiryDate.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanDate.length >= 2) {
      return '${cleanDate.substring(0, 2)}/${cleanDate.length > 2 ? cleanDate.substring(2, 4) : ''}';
    }
    return cleanDate;
  }

  /// Get card type name
  static String getCardTypeName(dynamic cardType) {
    if (cardType == null) return 'Unknown';
    
    final typeStr = cardType.toString().toLowerCase();
    if (typeStr.contains('visa')) return 'Visa';
    if (typeStr.contains('mastercard')) return 'Mastercard';
    if (typeStr.contains('amex') || typeStr.contains('american')) return 'American Express';
    if (typeStr.contains('discover')) return 'Discover';
    if (typeStr.contains('diners')) return 'Diners Club';
    if (typeStr.contains('jcb')) return 'JCB';
    
    return 'Unknown';
  }

  /// Get card icon asset path
  static String? getCardIconPath(dynamic cardType) {
    if (cardType == null) return null;
    
    final typeStr = cardType.toString().toLowerCase();
    if (typeStr.contains('visa')) return 'assets/images/visa.png';
    if (typeStr.contains('mastercard')) return 'assets/images/mastercard.png';
    if (typeStr.contains('amex') || typeStr.contains('american')) return 'assets/images/amex.png';
    if (typeStr.contains('discover')) return 'assets/images/discover.png';
    
    return null;
  }
}
