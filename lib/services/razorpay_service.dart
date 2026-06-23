// lib/services/razorpay_service.dart
import 'package:flutter/foundation.dart';
import 'razorpay_stub.dart' if (dart.library.html) 'razorpay_web.dart';

class RazorpayServiceWrapper {
  static Future<void> openCheckout({
    required double amount,
    required String currency,
    required String orderId,
    required String keyId,
    required String name,
    required String description,
    required String prefillName,
    required String prefillEmail,
    required String prefillContact,
    required String paymentMethod,
    required Function(String paymentId, String orderId, String signature) onSuccess,
    required Function(String error) onError,
  }) async {
    if (kIsWeb) {
      await openRazorpayWeb(
        amount: amount,
        currency: currency,
        orderId: orderId,
        keyId: keyId,
        name: name,
        description: description,
        prefillName: prefillName,
        prefillEmail: prefillEmail,
        prefillContact: prefillContact,
        paymentMethod: paymentMethod,
        onSuccess: onSuccess,
        onError: onError,
      );
    } else {
      onError('Razorpay not implemented for mobile yet.');
    }
  }
}
