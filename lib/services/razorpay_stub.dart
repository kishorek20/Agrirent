// lib/services/razorpay_stub.dart
Future<void> openRazorpayWeb({
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
  onError('Razorpay is only implemented for Web in this configuration.');
}
